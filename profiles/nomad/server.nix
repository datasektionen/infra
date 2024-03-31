{ config, secretsDir, ... }:
{
  services.nomad = {
    enable = true;
    dropPrivileges = true;
    enableDocker = false;
    settings = {
      bind_addr = "{{ GetPublicIP }}";
      server = {
        enabled = true;
        bootstrap_expect = config.services.consul.extraConfig.bootstrap_expect;
      };
      consul = { };
    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };
  systemd.services.nomad.serviceConfig.EnvironmentFile = config.age.secrets.nomad-consul-token.path;

  networking.firewall.allowedTCPPorts = [ 4646 4647 4648 ];

  age.secrets.nomad-consul-token.file = secretsDir + "/nomad-consul-token.env.age";
  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
