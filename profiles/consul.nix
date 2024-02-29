{ options, ... }:
let
  device = "ens3";
in
{
  services.consul = {
    enable = true;
    webUi = true;
    forceAddrFamily = "ipv4";
    extraConfig = {
      node_name = options.networking.hostName.value;
      server = true;
      bootstrap_expect = 1;
      client_addr = "0.0.0.0";
    };
    interface.advertise = device;
    interface.bind = device;
  };
}
