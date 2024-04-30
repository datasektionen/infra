{ config, ... }:
{
  services.nomad = {
    enable = true;
    settings = {
      bind_addr = "{{ GetPublicIP }}";
      consul = {
        ssl = true;
        address = "127.0.0.1:8501";
        ca_file = ../../files/consul-agent-ca.pem;

        grpc_ca_file = ../../files/consul-agent-ca.pem;
        grpc_address = "127.0.0.1:8503";
      };
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
    EnvironmentFile = config.age.secrets.consul-admin-token.path;
    LoadCredential = [
      "cert.pem:/var/lib/consul-certs/nomad-consul-cert.pem"
      "key.pem:/var/lib/consul-certs/nomad-consul-key.pem"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 4646 4647 ];
}
