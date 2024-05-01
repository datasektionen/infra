{ config, profiles, secretsDir, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = true;
    enableDocker = false;
    settings = {
      addresses = {
        rpc = "{{ GetPrivateInterfaces | include `address` `^10[.]83[.]` | attr `address` }}";
        serf = "{{ GetPrivateInterfaces | include `address` `^10[.]83[.]` | attr `address` }}";
      };
      server = {
        enabled = true;
        bootstrap_expect = builtins.length config.dsekt.addresses.private.cluster-servers;
        server_join.retry_join = config.dsekt.addresses.private.cluster-servers;
      };
    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };

  networking.firewall.allowedTCPPorts = [ 4648 ];

  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
