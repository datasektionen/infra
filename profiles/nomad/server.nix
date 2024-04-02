{ config, profiles, secretsDir, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = true;
    enableDocker = false;
    settings = {
      server = {
        enabled = true;
        bootstrap_expect = config.services.consul.extraConfig.bootstrap_expect;
      };
    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };

  networking.firewall.allowedTCPPorts = [ 4648 ];

  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
