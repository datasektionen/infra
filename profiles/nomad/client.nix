{
  config,
  profiles,
  secretsDir,
  ...
}:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client = {
        enabled = true;
        server_join.retry_join = builtins.attrValues config.dsekt.addresses.groups.cluster-servers;
        network_interface = "{{ GetPrivateInterfaces | include `address` `10[.]83[.]` | attr `name` }}";

        host_volume."docker-socket" = {
          path = "/var/run/docker.sock";
          read_only = true;
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
}
