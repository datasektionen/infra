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

  age.secrets.nomad-docker-auth.file = secretsDir + "/nomad-docker-auth.json.age";
}
