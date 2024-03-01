{ config, ... }:
let
  device = "ens3";
in
{
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
    };
    extraConfigFiles = [ config.age.secrets.consul-gossip-key.path ];
    interface.advertise = device;
    interface.bind = device;
  };
}
