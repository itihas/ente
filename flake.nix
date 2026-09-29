{
  description =
    "End-to-end encrypted cloud for photos, videos and 2FA secrets.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, moduleWithSystem, ... }: {
      systems = [ "x86_64-linux" ];

      perSystem = { self', inputs', pkgs, system, lib, ... }: {
        packages = with pkgs; {

          # The wasm bindings used by the web apps we build, from the rust/
          # workspace. Upstream builds these with `wasm-pack build --target
          # bundler --no-pack`; wasm-pack downloads its tools at build time, so
          # we run the cargo + wasm-bindgen steps it would run ourselves.
          #
          # refer https://github.com/ipetkov/crane/blob/master/examples/custom-toolchain/flake.nix
          ente-wasm = let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ (import inputs.rust-overlay) ];
            };
            craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (p:
              p.rust-bin.stable.latest.default.override {
                targets = [ "wasm32-unknown-unknown" ];
              });
            # Crate (directory) names under rust/bindings/wasm, each of which
            # ends up in web/packages/wasm/<name>/pkg.
            crates = [ "prelogin" "photos" "auth" "cast" ];
            commonArgs = {
              src = lib.cleanSourceWith {
                src = ./rust;
                filter = path: type: baseNameOf path != "target";
              };
              pname = "ente-wasm";
              version = "main";
              CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
              cargoExtraArgs =
                lib.concatMapStringsSep " " (c: "-p ente-${c}-wasm") crates;
              doCheck = false;
            };
          in craneLib.buildPackage (commonArgs // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;
            nativeBuildInputs = [ pkgs.wasm-bindgen-cli_0_2_125 ];
            installPhaseCommand = lib.concatMapStringsSep "\n" (c: ''
              mkdir -p $out/${c}
              wasm-bindgen --target bundler --out-dir $out/${c} \
                target/wasm32-unknown-unknown/release/ente_${c}_wasm.wasm
            '') crates;
          });

          ente-cli = buildGoModule {
            pname = "ente-cli";
            version = "main";
            src = ./cli;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-9O8Dj2ZnBXTPo/rDaamgw9Hlhjq0UaM9ppjTK0+GzFY=";
            doCheck = false;
            postInstall = "cp -R ./* $out/";
          };

          ente-server = buildGoModule {
            pname = "ente-server";
            version = "main";
            src = ./server;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-NADYbTkO0ng3lYll9+W7ICGOkUuYim8FRLtkoraMgRY=";
            doCheck = false;
            postInstall = "cp -R ./* $out/";
          };

          ente-web = let
            # Needs the ente-wasm crates built above (every app needs
            # prelogin; photos, auth and cast also need their own).
            apps = [ "photos" "albums" "accounts" "auth" "cast" "share" "embed" "memories" ];
            # Apps whose package.json has a build:post step.
            postBuildApps = [ "share" "memories" ];
          in stdenv.mkDerivation (finalAttrs: {
            pname = "ente-web";
            version = "main";
            src = ./web;

            npmDeps = fetchNpmDeps {
              inherit (finalAttrs) src;
              hash = "sha256-X7WaR9TGWqQptvGTznKSfCzbmmh7uvcNZLxVogFcP9k=";
            };

            nativeBuildInputs = [ nodejs npmHooks.npmConfigHook ];
            # Skip install scripts: wasm-pack's downloads a binary (we build
            # the wasm ourselves) and exifreader's only customizes its bundle.
            npmRebuildFlags = [ "--ignore-scripts" ];

            env.NEXT_TELEMETRY_DISABLED = "1";
            doCheck = false;

            buildPhase = ''
              runHook preBuild

              for c in ${self'.packages.ente-wasm}/*; do
                mkdir -p packages/wasm/$(basename $c)/pkg
                cp -R $c/* packages/wasm/$(basename $c)/pkg/
              done

              ${lib.concatMapStringsSep "\n" (app: ''
                npm exec --workspace ${app} -- next build --webpack
              '') apps}
              ${lib.concatMapStringsSep "\n"
              (app: "npm run build:post --workspace ${app}") postBuildApps}

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              ${lib.concatMapStringsSep "\n"
              (app: "cp -r apps/${app}/out $out/${app}")
              apps}
              runHook postInstall
            '';
          });
        };
      };
      flake.nixosModules.ente = moduleWithSystem (perSystem@{ config, ... }:
        nixos@{ config, pkgs, lib, ... }:
        with lib;
        let cfg = config.services.ente;
        in {
          options.services.ente = {
            enable = mkEnableOption "enable ente photos service";
            nginx = { enable = mkEnableOption "configure"; };
            domain = mkOption { type = types.str; };
            apps = mkOption {
              type = types.attrs;
              default = {
                accounts = {
                  subdomain = "accounts";
                  serve = "accounts";
                };
                public-albums = {
                  subdomain = "albums";
                  serve = "albums";
                };
                auth = {
                  subdomain = "auth";
                  serve = "auth";
                };
                cast = {
                  subdomain = "cast";
                  serve = "cast";
                };
                embed-albums = {
                  subdomain = "embed";
                  serve = "embed";
                };
                photos = {
                  subdomain = "photos";
                  serve = "photos";
                };
                public-locker = {
                  subdomain = "share";
                  serve = "share";
                };
              };
            };
            port = mkOption {
              type = types.int;
              default = 8080;
              description =
                "port that the ente server binds to. ente apps are file-served and can therefore just be served by nginx directly, they don't need local ports.";
            };
            credentialsFile = mkOption {
              type = types.str;
              default = "";
              description =
                "path where your credentials file lives. It is currently useless to set the credentials-file value in museum.yaml because the viper merge order is wrong. Therefore this variable sets `ENTE_CREDENTIALS_FILE in the systemd service environment.`";
            };
            museumYaml = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            museumExtraConfig = mkOption {
              type = types.attrs;
              default = { };
            };
          };
          config = {

            users = {
              users.ente = {
                isSystemUser = true;
                group = "ente";
              };
              groups.ente = { };
            };
            systemd.services.ente-server = let
              museumConfig = {
                http.port = cfg.port;
                apps = mapAttrs (n: v: "https://${v.subdomain}.${cfg.domain}") cfg.apps;
              };
              configDir = pkgs.symlinkJoin {
                name = "ente-config";
                paths = [
                  perSystem.config.packages.ente-server
                  (if cfg.museumYaml != null then
                    cfg.museumYaml
                  else
                    (pkgs.writeTextDir "museum.yaml" (builtins.toJSON
                      (recursiveUpdate museumConfig cfg.museumExtraConfig))))
                ];
              };
            in {
              wantedBy = [ "multi-user.target" ];
              environment = {
                ENVIRONMENT = "local";
                ENTE_CREDENTIALS_FILE = cfg.credentialsFile;
              };
              serviceConfig = {
                User = "ente";
                Group = "ente";
                WorkingDirectory = configDir;
                ExecStart = "${configDir}/bin/museum";
              };
            };

            services.nginx.virtualHosts = let
              # TODO: upstream fix to web/packages/base/next.config.base.js —
              # add a webpack ProvidePlugin for process/browser so that
              # process.nextTick is injected at the module level rather than
              # relying on window.process. The nextTick shim below is a
              # workaround for fast-srp-hap → crypto-browserify → randombytes
              # calling process.nextTick, which fails because the pre-compiled
              # crypto-browserify bundle inside Next.js reads from window.process
              # rather than webpack's per-module process injection.
              envPolyfill = pkgs.writeText "env.js" ''
                window.process = window.process || {};
                window.process.nextTick = window.process.nextTick || function nextTick(fn) {
                  var args = Array.prototype.slice.call(arguments, 1);
                  Promise.resolve().then(function() { fn.apply(null, args); });
                };
                // Other app origins come from museum's `apps` config, which
                // the web apps fetch at runtime.
                window.process.env = {
                  NEXT_PUBLIC_ENTE_ENDPOINT: 'https://${cfg.domain}',
                };
              '';
            in {
              ${cfg.domain} = {
                forceSSL = true;
                enableACME = true;
                locations."/".proxyPass =
                  "http://localhost:${toString cfg.port}";
              };
            } // mapAttrs' (n: v:
              (nameValuePair "${v.subdomain}.${cfg.domain}" {
                forceSSL = true;
                enableACME = true;
                root = "${perSystem.config.packages.ente-web}/${v.serve}";
                locations."=/env.js" = {
                  alias = "${envPolyfill}";
                  extraConfig = ''
                    add_header Content-Type application/javascript;
                  '';
                };
                locations."/".extraConfig = ''
                  sub_filter '</head>' '<script src="/env.js"></script></head>';
                  sub_filter_once on;

                  try_files $uri $uri.html /index.html;'';
              })) cfg.apps;
          };
        });
    });
}
