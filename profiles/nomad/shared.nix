{ config, ... }:
{
  services.nomad = {
    enable = true;
    settings = {
      bind_addr = config.dsekt.addresses.hosts.self;
      advertise =
        let
          addr = config.dsekt.addresses.hosts.self;
        in
        {
          http = addr;
          rpc = addr;
          serf = addr;
        };
      tls = {
        ca_file = ../../files/nomad-agent-ca.pem;
        # WARNING: not sure if these paths are stable, but you can't read env
        # variables in the config file... The ideal solution would probably be
        # to generate this config at run time using $CREDENTIALS_DIRECTORY.
        cert_file = "/run/credentials/nomad.service/cert.pem";
        key_file = "/run/credentials/nomad.service/key.pem";
        http = true;
        rpc = true;
      };
      acl = {
        enabled = true;
        token_max_expiration_ttl = "8760h"; # can set no expiry anyway
      };
    };
  };
  systemd.services.nomad.serviceConfig = {
    LoadCredential = [
      "cert.pem:/var/lib/nomad-certs/cert.pem"
      "key.pem:/var/lib/nomad-certs/key.pem"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    4646
    4647
  ];

  systemd.tmpfiles.rules = [ "d /var/lib/nomad-certs 0750 root root" ];
}
