# Taken from https://github.com/NixOS/nixpkgs/blob/49ee0e94463abada1de470c9c07bfc12b36dcf40/nixos/modules/services/web-servers/traefik.nix
# and modified to allow for running multiple instances of traefik.
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dsekt.services.traefik;
  jsonValue = with types;
    let
      valueType = nullOr
        (oneOf [
          bool
          int
          float
          str
          (lazyAttrsOf valueType)
          (listOf valueType)
        ]) // {
        description = "JSON value";
        emptyValue.value = { };
      };
    in
    valueType;
  mkDynamicConfigFile = name:
    if cfg.servers.${name}.dynamicConfigFile == null then
      pkgs.runCommand "config.toml"
        {
          buildInputs = [ pkgs.remarshal ];
          preferLocalBuild = true;
        } ''
        remarshal -if json -of toml \
          < ${
            pkgs.writeText "dynamic_config.json"
            (builtins.toJSON cfg.servers.${name}.dynamicConfigOptions)
          } \
          > $out
      ''
    else
      cfg.dynamicConfigFile;
  mkStaticConfigFile = name:
    if cfg.servers.${name}.staticConfigFile == null then
      pkgs.runCommand "config.toml"
        {
          buildInputs = [ pkgs.yj ];
          preferLocalBuild = true;
        } ''
        yj -jt -i \
          < ${
            pkgs.writeText "static_config.json" (builtins.toJSON
              (recursiveUpdate cfg.servers.${name}.staticConfigOptions {
                providers.file.filename = "${mkDynamicConfigFile name}";
              }))
          } \
          > $out
      ''
    else
      cfg.staticConfigFile;

  mkFinalStaticConfigFile = name:
    if cfg.servers.${name}.environmentFiles == [ ]
    then mkStaticConfigFile name
    else "/run/traefik-${name}/config.toml";
in
{
  options.dsekt.services.traefik = {
    package = mkPackageOption pkgs "traefik" { };

    servers = mkOption {
      type = types.attrsOf (types.submodule ({ config, name, ... }: {
        options = {
          staticConfigFile = mkOption {
            default = null;
            example = literalExpression "/path/to/static_config.toml";
            type = types.nullOr types.path;
            description = ''
              Path to traefik's static configuration to use.
              (Using that option has precedence over `staticConfigOptions` and `dynamicConfigOptions`)
            '';
          };

          staticConfigOptions = mkOption {
            description = ''
              Static configuration for Traefik.
            '';
            type = jsonValue;
            default = { entryPoints.http.address = ":80"; };
            example = {
              entryPoints.web.address = ":8080";
              entryPoints.http.address = ":80";

              api = { };
            };
          };

          dynamicConfigFile = mkOption {
            default = null;
            example = literalExpression "/path/to/dynamic_config.toml";
            type = types.nullOr types.path;
            description = ''
              Path to traefik's dynamic configuration to use.
              (Using that option has precedence over `dynamicConfigOptions`)
            '';
          };

          dynamicConfigOptions = mkOption {
            description = ''
              Dynamic configuration for Traefik.
            '';
            type = jsonValue;
            default = { };
            example = {
              http.routers.router1 = {
                rule = "Host(`localhost`)";
                service = "service1";
              };

              http.services.service1.loadBalancer.servers =
                [{ url = "http://localhost:8080"; }];
            };
          };

          dataDir = mkOption {
            default = "/var/lib/traefik-${name}";
            type = types.path;
            description = ''
              Location for any persistent data traefik creates, ie. acme
            '';
          };

          group = mkOption {
            default = "traefik";
            type = types.str;
            example = "docker";
            description = ''
              Set the group that traefik runs under.
              For the docker backend this needs to be set to `docker` instead.
            '';
          };

          environmentFiles = mkOption {
            default = [ ];
            type = types.listOf types.path;
            example = [ "/run/secrets/traefik.env" ];
            description = ''
              Files to load as environment file. Environment variables from this file
              will be substituted into the static configuration file using envsubst.
            '';
          };
        };
      }));
      description = lib.mdDoc "Configuration of multiple traefik instances";
      default = { };
    };
  };

  config = mkIf (cfg.servers != { }) {
    systemd.tmpfiles.rules = lib.mapAttrsToList
      (_: c: "d '${c.dataDir}' 0700 traefik traefik - -")
      cfg.servers
    ;

    systemd.services = lib.mapAttrs'
      (name: c: lib.nameValuePair "traefik-${name}" {
        description = "Traefik web server";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 86400;
        startLimitBurst = 5;
        serviceConfig = {
          EnvironmentFile = c.environmentFiles;
          ExecStartPre = lib.optional (c.environmentFiles != [ ])
            (pkgs.writeShellScript "pre-start" ''
              umask 077
              ${pkgs.envsubst}/bin/envsubst -i "${mkStaticConfigFile name}" > "${mkFinalStaticConfigFile name}"
            '');
          ExecStart = "${cfg.package}/bin/traefik --configfile=${mkFinalStaticConfigFile name}";
          Type = "simple";
          User = "traefik";
          Group = c.group;
          Restart = "on-failure";
          AmbientCapabilities = "cap_net_bind_service";
          CapabilityBoundingSet = "cap_net_bind_service";
          NoNewPrivileges = true;
          LimitNPROC = 64;
          LimitNOFILE = 1048576;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectSystem = "full";
          ReadWritePaths = [ c.dataDir ];
          RuntimeDirectory = "traefik-${name}";
        };
      })
      cfg.servers;

    users.users.traefik = {
      group = "traefik";
      isSystemUser = true;
    };

    users.groups.traefik = { };
  };
}
