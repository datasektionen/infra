{ config, ... }:
{
  services.nomad = {
    enable = true;
    settings = {
      addresses.http = "{{ GetPublicIP }}";
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
      acl.enabled = true;
    };
  };
  systemd.services.nomad.serviceConfig = {
    LoadCredential = [
      "cert.pem:/var/lib/nomad-certs/cert.pem"
      "key.pem:/var/lib/nomad-certs/key.pem"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 4646 4647 ];

  systemd.tmpfiles.rules = [
    "d /var/lib/nomad-certs 0750 root root"
  ];
}
