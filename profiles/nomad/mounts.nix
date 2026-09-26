{
  pkgs,
  config,
  profiles,
  secretsDir,
  ...
}:
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/mnt/immich" = {
    device = "//u620148-sub1.your-storagebox.de/u620148-sub1";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.immich-storagebox-credentials.path}"
      "seal"
      "uid=0"
      "gid=0"
      "file_mode=0644"
      "dir_mode=0755"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  fileSystems."/mnt/planka" = {
    device = "//u620148-sub2.your-storagebox.de/u620148-sub2";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.planka-storagebox-credentials.path}"
      "seal"
      "uid=1000"
      "gid=1000"
      "file_mode=0644"
      "dir_mode=0755"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  fileSystems."/mnt/apollo" = {
    device = "//u620148-sub3.your-storagebox.de/u620148-sub3";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.apollo-storagebox-credentials.path}"
      "seal"
      "uid=0"
      "gid=0"
      "file_mode=0644"
      "dir_mode=0755"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  fileSystems."/mnt/mattermost" = {
    device = "//u620148-sub4.your-storagebox.de/u620148-sub4";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.mattermost-storagebox-credentials.path}"
      "seal"
      "uid=2000"
      "gid=2000"
      "file_mode=0644"
      "dir_mode=0755"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  services.nomad.settings.client.host_volume = {
    "docker-socket" = {
      path = "/var/run/docker.sock";
      read_only = true;
    };

    "planka/user-avatars" = {
      path = "/mnt/planka/user-avatars";
      read_only = false;
    };

    "planka/background-images" = {
      path = "/mnt/planka/background-images";
      read_only = false;
    };

    "planka/favicons" = {
      path = "/mnt/planka/favicons";
      read_only = false;
    };

    "planka/attachments" = {
      path = "/mnt/planka/attachments";
      read_only = false;
    };

    "apollo" = {
      path = "/mnt/apollo";
      read_only = false;
    };

    "immich" = {
      path = "/mnt/immich";
      read_only = false;
    };

    "mattermost/data" = {
      path = "/mnt/mattermost";
      read_only = false;
    };
  };
}
