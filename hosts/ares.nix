{
  lib,
  pkgs,
  config,
  profiles,
  secretsDir,
  ...
}:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    postgres
    traefik-external
  ];

  dsekt.nomad.volumes.host.mattermost = {
    userId = 2000;
    dirs = [
      "config"
      "data"
      "logs"
      "plugins"
      "client/plugins"
      "bleve-indexes"
    ];
  };

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
