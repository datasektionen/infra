{
  lib,
  pkgs,
  config,
  profiles,
  secretsDir,
  ...
}:
let
  mattermost-dirs = [
    "config"
    "data"
    "logs"
    "plugins"
    "client/plugins"
    "bleve-indexes"
  ];
in
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    postgres
    traefik
  ];

  services.nomad.settings.client.host_volume = lib.listToAttrs (
    lib.forEach mattermost-dirs (x: {
      name = "mattermost/${x}";
      value = {
        path = "/var/lib/mattermost/${x}";
      };
    })
  );
  systemd.tmpfiles.rules = lib.forEach mattermost-dirs (
    x: "d /var/lib/mattermost/${x} 0750 2000 2000"
  );

  dsekt.restic = {
    backupPrepareCommand = ''
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dumpall > /root/postgres_dump.sql
    '';

    paths = [
      "/root/postgres_dump.sql"
      "/var/lib/mattermost"
    ];

    passwordFile = config.age.secrets.restic-repo-pwd-ares.path;

    targets.s3 = {
      repository = "s3:https://s3.amazonaws.com/dsekt-restic-ares";
      credentialsEnvFile = config.age.secrets.restic-s3-creds-ares.path;
    };
  };

  age.secrets.restic-repo-pwd-ares.file = secretsDir + "/restic-repo-pwd-ares.age";
  age.secrets.restic-s3-creds-ares.file = secretsDir + "/restic-s3-creds-ares.env.age";

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "23.11";
}
