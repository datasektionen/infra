{ config, ... }:
let
  device = "ens3";
in
{
  # `encrypt = "base64keythatis32byteslong"`
  age.secrets.consul-gossip-key = {
    file = ../secrets/consul-gossip-key.hcl.age;
    name = "gossip-key.hcl";
    owner = "consul";
    group = "consul";
    mode = "440";
  };

  services.consul = {
    enable = true;
    webUi = true;
    forceAddrFamily = "ipv4";
    extraConfig = {
      node_name = config.networking.hostName;
      server = true;
      bootstrap_expect = 1;
      client_addr = "0.0.0.0";
      acl = {
        enabled = true;
        default_policy = "deny";
      };
    };
    extraConfigFiles = [ config.age.secrets.consul-gossip-key.path ];
    interface.advertise = device;
    interface.bind = device;
  };

  networking.firewall.allowedTCPPorts = [ 8600 8500 8501 8502 8503 8300 8301 8302 ];
}
