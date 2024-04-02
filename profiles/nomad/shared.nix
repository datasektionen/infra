{ config, secretsDir, ... }:
{
  services.nomad = {
    enable = true;
    settings = {
      bind_addr = "{{ GetPublicIP }}";
      # consul = { };
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
      acl.enabled = true;
    };
  };
  systemd.services.nomad.serviceConfig = {
    EnvironmentFile = config.age.secrets.nomad-consul-token.path;
    LoadCredential = [
      "cert.pem:/var/lib/consul-certs/dc1-consul-0.pem"
      "key.pem:/var/lib/consul-certs/dc1-consul-0-key.pem"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 4646 4647 ];

  age.secrets.nomad-consul-token.file = secretsDir + "/nomad-consul-token.env.age";
}
