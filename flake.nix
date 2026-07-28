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
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                (craneLib.fileset.commonCargoSources ./rust/core)
                (craneLib.fileset.commonCargoSources ./rust/contacts)
                ./web/packages/wasm
              ];
            };
            wasm-bindgen-cli = (pkgs.buildWasmBindgenCli rec {
              src = pkgs.fetchCrate {
                pname = "wasm-bindgen-cli";
                version = "0.2.108";
                hash = "sha256-UsuxILm1G6PkmVw0I/JF12CRltAfCJQFOaT4hFwvR8E=";
              };

              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit src;
                inherit (src) pname version;
                hash = "sha256-iqQiWbsKlLBiJFeqIYiXo3cqxGLSjNM8SOWXGM9u43E=";
              };
            });
          in craneLib.buildPackage {
            inherit src;
            # https://github.com/ipetkov/crane/blob/master/docs/faq/workspace-not-at-source-root.md
            cargoToml = ./web/packages/wasm/Cargo.toml;
            cargoLock = ./web/packages/wasm/Cargo.lock;
            postUnpack = ''
              cd $sourceRoot/web/packages/wasm
              sourceRoot="."
            '';
            postBuild = ''
              mkdir pkg
              ls pkg
              ${wasm-bindgen-cli}/bin/wasm-bindgen --out-dir ./pkg target/wasm32-unknown-unknown/release/ente_wasm.wasm
              ls pkg
            '';
            installPhaseCommand = ''
              mkdir $out
              cp -R pkg/* $out/
            '';
            cargoExtraArgs = "-p ente-wasm --target wasm32-unknown-unknown";
            doCheck = false;
          };

          ente-cli = buildGoModule {
            pname = "ente-cli";
            version = "main";
            src = ./cli;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-Gg1mifMVt6Ma8yQ/t0R5nf6NXbzLZBpuZrYsW48p0mw=";
            doCheck = false;
            postInstall = "cp -R ./* $out/";
          };

          ente-server = buildGoModule {
            pname = "ente-server";
            version = "main";
            src = ./server;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-qrcfNacMR2hwdtezwYrYTPpr1ALCwZktSW8UiyzGXjQ=";
            doCheck = false;
            postInstall = "cp -R ./* $out/";
          };

          ente-web = stdenv.mkDerivation (finalAttrs: {
            pname = "ente-web";
            version = "main";
            src = ./web;

            nativeBuildInputs = [
              yarn
              nodejs
              yarnConfigHook
              writableTmpDirAsHomeHook
              self'.packages.ente-wasm
              wasm-bindgen-cli
              wasm-pack
            ];
            doCheck = false;

            # yarn.lock drifts from upstream: the key for base-x must be
            # "base-x@5.0.1, base-x@^5.0.0:" (not just "base-x@^5.0.0:") so
            # that fetchYarnDeps includes it for the resolutions pin in
            # package.json. Reverse when upstream restores the multi-alias key.
            yarnOfflineCache = fetchYarnDeps {
              yarnLock = ./web/yarn.lock;
              hash = "sha256-gc0TsT0pYHQfiwjOQHUqtuO65ib+mS8Ifc0TcBig2/s=";
            };

            buildPhase = ''
              runHook preBuild

              mkdir packages/wasm/pkg
              cp -R ${self'.packages.ente-wasm}/* packages/wasm/pkg

              yarn workspace photos next build

              yarn workspace albums next build

              yarn workspace accounts next build

              yarn workspace auth next build

              yarn workspace cast next build

              yarn workspace share next build && yarn workspace share build:post

              yarn workspace embed next build

              yarn workspace memories next build && yarn workspace memories build:post

              runHook postBuild
            '';

            installPhase = ''
              mkdir -p $out

              # Photos
              cp -r apps/photos/out $out/photos
              # Albums
              cp -r apps/albums/out $out/albums
              # Accounts
              cp -r apps/accounts/out $out/accounts
              # Auth
              cp -r apps/auth/out $out/auth
              # Cast
              cp -r apps/cast/out $out/cast
              # Public Locker
              cp -r apps/share/out $out/share
              # Embed
              cp -r apps/embed/out $out/embed
              # Memories
              cp -r apps/memories/out $out/memories
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
                window.process.env = {
                  NEXT_PUBLIC_ENTE_ENDPOINT: 'https://${cfg.domain}',
                  NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT: 'https://albums.${cfg.domain}',
                  NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT: 'https://photos.${cfg.domain}',
                  NEXT_PUBLIC_ENTE_SHARE_ENDPOINT: 'https://share.${cfg.domain}',
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
