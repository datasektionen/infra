{ config, secretsDir, ... }:
let
  device = "ens3";
  servers = [ "zeus.betasektionen.se" "poseidon.betasektionen.se" "hades.betasektionen.se" ];
in
{
  services.consul = {
    enable = true;
    webUi = true;
    forceAddrFamily = "ipv4";
    extraConfig = {
      node_name = config.networking.hostName;
      server = true;
      bootstrap_expect = builtins.length servers;
      retry_join = servers;
      client_addr = "0.0.0.0";
      bind_addr = "0.0.0.0";
      ports.https = 8501;
      acl = {
        enabled = true;
        default_policy = "deny";
      };
      tls.defaults = {
        ca_file = ../../files/consul-agent-ca.pem;
        cert_file = "/var/lib/consul-certs/dc1-server-consul-0.pem";
        key_file = "/var/lib/consul-certs/dc1-server-consul-0-key.pem";
        verify_outgoing = true;
      };
    };
    extraConfigFiles = [ config.age.secrets.consul-gossip-key.path ];
    interface.advertise = device;
  };

  networking.firewall.allowedTCPPorts = [ 8600 8500 8501 8502 8503 8300 8301 8302 ];

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
