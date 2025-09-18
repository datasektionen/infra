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
    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };

  networking.firewall.allowedTCPPorts = [ 4648 ];

  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
