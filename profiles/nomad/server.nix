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
      tls = {
        ca_file = ../../files/consul-agent-ca.pem;
        # TODO: not sure if these paths are stable, but you can read env
        # variables in the config file... The ideal solution would probably be
        # to generate this config at run time using $CREDENTIALS_DIRECTORY.
        cert_file = "/run/credentials/nomad.service/cert.pem";
        key_file = "/run/credentials/nomad.service/key.pem";
        http = true;
        rpc = true;
      };
    };
    credentials."gossip_key.json" = config.age.secrets.nomad-gossip-key.path;
  };
  systemd.services.nomad.serviceConfig = {
    EnvironmentFile = config.age.secrets.nomad-consul-token.path;
    LoadCredential = [
      "cert.pem:/var/lib/consul-certs/dc1-server-consul-0.pem"
      "key.pem:/var/lib/consul-certs/dc1-server-consul-0-key.pem"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 4646 4647 4648 ];

  age.secrets.nomad-consul-token.file = secretsDir + "/nomad-consul-token.env.age";
  age.secrets.nomad-gossip-key.file = secretsDir + "/nomad-gossip-key.json.age";
}
