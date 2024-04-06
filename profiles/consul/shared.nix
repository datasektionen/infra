{ config, secretsDir, ... }:
{
  services.consul = {
    enable = true;
    webUi = true;
    forceAddrFamily = "ipv4";
    extraConfig = {
      node_name = config.networking.hostName;
      retry_join = config.dsekt.addresses.cluster-servers;
      client_addr = "0.0.0.0";
      bind_addr = "0.0.0.0";
      advertise_addr = "{{ GetPublicIP }}";
      ports = {
        https = 8501;
        grpc_tls = 8503;
      };
      acl = {
        enabled = true;
        default_policy = "deny";
      };
      tls.defaults = {
        ca_file = ../../files/consul-agent-ca.pem;
        cert_file = "/run/credentials/consul.service/cert.pem";
        key_file = "/run/credentials/consul.service/key.pem";
        verify_outgoing = true;
      };
    };
    extraConfigFiles = [ config.age.secrets.consul-gossip-key.path ];
  };
  systemd.services.consul.serviceConfig.LoadCredential = [
    "cert.pem:/var/lib/consul-certs/nomad-consul-cert.pem"
    "key.pem:/var/lib/consul-certs/nomad-consul-key.pem"
  ];

  networking.firewall.allowedTCPPorts = [
    8600 # dns
    8500 # http
    8501 # https
    8502 # grpc
    8503 # grpc tls
    8301 # lan serf
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/consul-certs 0750 consul consul"
  ];

  age.secrets.consul-gossip-key = {
    file = secretsDir + "/consul-gossip-key.hcl.age";
    name = "gossip-key.hcl";
    owner = "consul";
    group = "consul";
    mode = "440";
  };
}
