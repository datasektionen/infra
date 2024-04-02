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
      ports.https = 8501;
      acl = {
        enabled = true;
        default_policy = "deny";
      };
      tls.defaults = {
        ca_file = ../../files/consul-agent-ca.pem;
        cert_file = "/var/lib/consul-certs/dc1-consul-0.pem";
        key_file = "/var/lib/consul-certs/dc1-consul-0-key.pem";
        verify_outgoing = true;
      };
    };
    extraConfigFiles = [ config.age.secrets.consul-gossip-key.path ];
  };

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
