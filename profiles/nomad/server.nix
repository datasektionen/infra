{
  config,
  profiles,
  secretsDir,
  ...
}:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = true;
    enableDocker = false;
    settings = {
      server = {
        enabled = true;
        bootstrap_expect = builtins.length config.dsekt.addresses.groups.cluster-servers;
        server_join.retry_join = config.dsekt.addresses.groups.cluster-servers;
      };

      plugin.docker.config.extra_labels = [
        "job_name"
        "task_group_name"
        "task_name"
        "namespace"
        "node_name"
      ];

      client.host_volume."docker-socket-ro" = {
        path = "/var/run/docker.sock";
        read_only = true;
      };

    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };

  networking.firewall.allowedTCPPorts = [ 4648 ];

  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
