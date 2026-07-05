{
  pkgs,
  config,
  profiles,
  secretsDir,
  ...
}:
{
  imports = [ profiles.nomad.shared ];

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
      "uid=0"
      "gid=0"
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

  dsekt.nomad.volumes.host.immich = {
    userId = 0;
    dirs = [
      "thumbs"
    ];
  };


  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client = {
        enabled = true;
        server_join.retry_join = builtins.attrValues config.dsekt.addresses.groups.cluster-servers;
        network_interface = "{{ GetPrivateInterfaces | include `address` `10[.]83[.]` | attr `name` }}";

        host_volume = {
          "docker-socket" = {
            path = "/var/run/docker.sock";
            read_only = true;
          };

          "immich" = {
            path = "/mnt/immich";
            read_only = false;
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
        };
      };

      telemetry = {
        publish_allocation_metrics = true;
        publish_node_metrics = true;
        prometheus_metrics = true;
      };

      plugin.docker.config = {
        extra_labels = [
          "job_name"
          "task_group_name"
          "task_name"
          "namespace"
          "node_name"
        ];

        auth.config = config.age.secrets.nomad-docker-auth.path;
      };
    };
  };

  virtualisation.docker.daemon.settings.dns = [ config.dsekt.addresses.hosts.self ];

  # Let any docker containers access the host through it's local IP address
  networking.firewall.extraCommands = ''
    iptables -I INPUT -s 172.16.0.0/12 -d ${config.dsekt.addresses.hosts.self} -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -s 172.16.0.0/12 -d ${config.dsekt.addresses.hosts.self} -j ACCEPT || true
  '';

  age.secrets.nomad-docker-auth.file = secretsDir + "/nomad-docker-auth.json.age";
  age.secrets.immich-storagebox-credentials.file = secretsDir + "/immich-storagebox-credentials.age";
  age.secrets.planka-storagebox-credentials.file = secretsDir + "/planka-storagebox-credentials.age";
  age.secrets.apollo-storagebox-credentials.file = secretsDir + "/apollo-storagebox-credentials.age";
}
