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

          # refer https://github.com/ipetkov/crane/blob/master/examples/quick-start/flake.nix
          ente-core = let
            craneLib = inputs.crane.mkLib pkgs;
            src = craneLib.cleanCargoSource ./rust/core;
            commonArgs = {
              inherit src;
              strictDeps = true;
              nativeBuildInputs = [ pkg-config ];
              buildInputs = [ openssl ]
                ++ lib.optionals pkgs.stdenv.isDarwin [ ];
            };
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          in craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });

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
                ./web/packages/wasm
              ];
            };
          in craneLib.buildPackage {
            inherit src;
            # https://github.com/ipetkov/crane/blob/master/docs/faq/workspace-not-at-source-root.md
            cargoToml = ./web/packages/wasm/Cargo.toml;
            cargoLock = ./web/packages/wasm/Cargo.lock;
            postUnpack = ''
              cd $sourceRoot/web/packages/wasm
              sourceRoot="."
            '';
            cargoExtraArgs = "-p ente-wasm --target wasm32-unknown-unknown";
            doCheck = false;
          };

          ente-server = buildGoModule {
            pname = "ente-server";
            version = "main";
            src = ./server;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-napF55nA/9P8l5lddnEHQMjLXWSyTzgblIQCbSZ20MA=";
            doCheck = false;
            postInstall = "cp -R ./* $out/";
          };

          ente-web = stdenv.mkDerivation (finalAttrs: {
            pname = "ente-web";
            version = "main";
            src = ./.;

            postUnpack = ''
              cd $sourceRoot/web
              sourceRoot="."
            '';

            nativeBuildInputs = [
              yarn
              nodejs
              yarnConfigHook
              writableTmpDirAsHomeHook
              self'.packages.ente-wasm
            ];
            doCheck = false;

            yarnOfflineCache = fetchYarnDeps {
              yarnLock = ./web/yarn.lock;
              hash = "sha256-Kr/sOyju+WsdbdS0KN017vtrAsyQoTzn32rltSXykNk=";
            };

            buildPhase = ''
              runHook preBuild

              # These commands are executed inside web directory
              # Build photos. Build output to be served is present at apps/photos/
              yarn --offline build

              # Build accounts. Build output to be served is present at apps/accounts/out
              yarn --offline build:accounts

              # Build auth. Build output to be served is present at apps/auth/out
              yarn --offline build:auth

              # Build cast. Build output to be served is present at apps/cast/out
              yarn --offline build:cast

              # Build public locker. Build output to be served is present at apps/share/out
              yarn --offline build:share

              # Build embed. Build output to be served is present at apps/embed/out
              yarn --offline build:embed

              runHook postBuild
            '';

            installPhase = ''
              mkdir -p $out

              # Photos
              cp -r apps/photos/out $out/photos
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
                accounts = "accounts";
                auth = "auth";
                cast = "cast";
                embed-albums = "embed";
                photos = "photos";
                public-albums = "albums";
                public-locker = "share";
                family = "family";
              };
            };
            port = mkOption {
              type = types.int;
              default = 8080;
              description =
                "port that the ente server binds to. ente apps are file-served and can therefore just be served by nginx directly, they don't need local ports.";
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
                apps = mapAttrs (n: v: "${n}.${cfg.domain}") cfg.apps;
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
              environment = { ENVIROMENT = "production"; };
              serviceConfig = {
                User = "ente";
                Group = "ente";
                WorkingDirectory = configDir;
                ExecStart = "${configDir}/bin/museum";
              };
            };

            services.nginx.recommendedTlsSettings = true;
            services.nginx.virtualHosts = let
              webRoot = pkgs.runCommand "ente-web-configured" { } ''
                cp -r ${perSystem.config.packages.ente-web} $out
                find $out -name "*.js" -type f -exec sed -i \
                  -e 's|NEXT_PUBLIC_ENTE_ENDPOINT|https://${cfg.domain}|g' \
                  -e 's|NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT|https://albums.${cfg.domain}|g' \
                  -e 's|NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT|https://photos.${cfg.domain}|g' \
                  -e 's|NEXT_PUBLIC_ENTE_SHARE_ENDPOINT|https://share.${cfg.domain}|g' \
                  {} +
              '';
            in {
              ${cfg.domain} = {
                forceSSL = true;
                enableACME = true;
                locations."/".proxyPass =
                  "http://localhost:${toString cfg.port}";
              };
            } // mapAttrs' (n: subdomain:
              (nameValuePair "${subdomain}.${cfg.domain}" {
                forceSSL = true;
                enableACME = true;
                root = "${webRoot}/${subdomain}";
                locations."/" = { tryFiles = "$uri $uri.html /index.html"; };
              })) cfg.apps;
          };
        });
    });
}
