{
  config,
  lib,
  ...
}:
{
  options.dsekt.nomad.volumes = {
    host = lib.mkOption {
      default = { };
      description = lib.mdDoc ''
        Service-specific groups of host volumes to register with Nomad and
        create directories for. Create one group for each service, e.g.,
        "mattermost".
      '';
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              dirs = lib.mkOption {
                type = with lib.types; listOf singleLineStr;
                default = [ ];
                example = [
                  "data"
                  "logs"
                ];
                description = lib.mdDoc ''
                  Names of host volumes to create within this group.
                  For example, passing "logs" here inside a group named
                  "mattermost" would create a volume named "mattermost/logs".
                '';
              };

              userId = lib.mkOption {
                type = lib.types.int;
                example = 1000;
                description = lib.mdDoc ''
                  Linux UID who should own the directories.
                  Usually 1000, or 0 if the service runs as root inside the
                  container.
                '';
              };

              groupId = lib.mkOption {
                type = with lib.types; nullOr int;
                example = 1000;
                default = null;
                description = lib.mdDoc ''
                  Linux GID who should own the directories.
                  If null, defaults to match the provided UID.
                '';
              };

              permissionBits = lib.mkOption {
                type = lib.types.singleLineStr;
                example = "0500";
                default = "0750";
                description = lib.mdDoc ''
                  Permission bits that the directories should be created with.
                  Defaults to 0750, which means u=rwx,g=rx,o=none.
                '';
              };
            };
          }
        )
      );
    };
  };

  config =
    let
      cfg = config.dsekt.nomad.volumes;
      hostVolumes = builtins.concatLists (
        lib.mapAttrsToList (
          group: attrs:
          map (name: {
            inherit (attrs) userId permissionBits;
            groupId = with attrs; if groupId != null then groupId else userId;
            qualifiedName = "${group}/${name}";
          }) attrs.dirs
        ) cfg.host
      );
    in
    lib.mkIf (builtins.length hostVolumes != 0) {

      services.nomad.settings.client.host_volume = lib.listToAttrs (
        lib.forEach hostVolumes (volume: {
          name = volume.qualifiedName;
          value = {
            path = "/var/lib/nomad-volumes/${volume.qualifiedName}";
          };
        })
      );

      systemd.tmpfiles.rules = lib.forEach hostVolumes (
        volume:
        with volume;
        let
          path = "/var/lib/nomad-volumes/${qualifiedName}";
        in
        "d ${path} ${permissionBits} ${toString userId} ${toString groupId}"
      );
    };
}
