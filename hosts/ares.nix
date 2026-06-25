{
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
    mediawiki
  ];

  dsekt.nomad.volumes.host.mattermost = {
    userId = 2000;
    dirs = [
      "config"
      "logs"
      "plugins"
      "client/plugins"
    ];
  };

  dsekt.nomad.volumes.host.immich = {
    userId = 3000;
    dirs = [
      "uploads"
    ];
  };

  dsekt.nomad.volumes.host.vault = {
    userId = 0; # vaultwarden runs as root
    dirs = [ "data" ];
  };

  dsekt.nomad.volumes.host.planka = {
    userId = 1000;
    dirs = [
      "user-avatars"
      "background-images"
      "favicons"
      "attachments"
    ];
  };

  dsekt.nomad.volumes.host.prometheus = {
    userId = 65534; # Runs as nobody?
    dirs = [ "data" ];
  };

  dsekt.nomad.volumes.host.apollo = {
    userId = 65533; # Runs as nobody?
    dirs = [ "data" ];
  };

  dsekt.restic = {
    backupPrepareCommand = ''
      ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dumpall > /root/postgres_dump.sql
    '';

    paths = [
      "/root/postgres_dump.sql"
      "/var/lib/nomad-volumes/mattermost"
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
