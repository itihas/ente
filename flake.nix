{
  description =
    "End-to-end encrypted cloud for photos, videos and 2FA secrets.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, moduleWithSystem, ... }: {
      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        packages = with pkgs; {

          ente-server = buildGoModule {
            pname = "ente-server";
            version = "main";
            src = ./server;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libsodium ];
            vendorHash = "sha256-napF55nA/9P8l5lddnEHQMjLXWSyTzgblIQCbSZ20MA=";
            doCheck = false;
            postInstall = "cp -R configurations/ $out/configurations";
          };

          ente-web = stdenv.mkDerivation (finalAttrs: {
            pname = "ente-web";
            version = "main";
            src = ./web;

            nativeBuildInputs = [ yarn nodejs yarnConfigHook ];

            yarnOfflineCache = fetchYarnDeps {
              yarnLock = ./web/yarn.lock;
              hash = "sha256-omFNobZ+2hb1cEO2Gfn+F3oYy7UDSrtIY4cliQ80CUs=";
            };

            NEXT_PUBLIC_ENTE_ENDPOINT = "ENTE_API_ORIGIN_PLACEHOLDER";
            NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = "ENTE_ALBUMS_ORIGIN_PLACEHOLDER";
            NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT = "ENTE_PHOTOS_ORIGIN_PLACEHOLDER";

            buildPhase = ''
              runHook preBuild

              # These commands are executed inside web directory
              # Build photos. Build output to be served is present at apps/photos/out
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
              type = types.listOf (types.enum [
                "auth"
                "cast"
                "embed"
                "photos"
                "share"
                "accounts"
              ]);
              default = [ "auth" "cast" "embed" "photos" "share" "accounts" ];
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
                apps = genAttrs cfg.apps (n: "${n}.ente.${cfg.domain}");
              };
              configDir = pkgs.symlinkJoin {
                name = "ente-config";
                paths = [
                  perSystem.config.packages.ente-server
                  (if cfg.museumYaml != null then
                    cfg.museumYaml
                  else
                    (pkgs.writeTextDir "museum.yaml" (builtins.toJSON
                      (mkMerge [ museumConfig cfg.museumExtraConfig ]))))
                ];
              };
            in {
              wantedBy = [ "multi-user.target" ];
              environment = { ENVIROMENT = "production"; };
              serviceConfig = {
                RootDirectory = configDir;
                ExecStart = "./bin/museum";
              };
            };

            services.nginx.virtualHosts = {
              ${cfg.domain} = {
                forceSSL = true;
                enableACME = true;
                locations."/".proxyPass =
                  "http://localhost:${toString cfg.port}";
              };
            } // genAttrs (map (n: "${n}.${cfg.domain}") cfg.apps) (subdomain: {
              forceSSL = true;
              enableACME = true;
              root = "${perSystem.config.packages.ente-web}/${subdomain}";
              locations."/" = { tryFiles = "$uri $uri.html /index.html"; };
            });
          };
        });
    });
}
