{ options, ... }:
{
  services.consul = {
    enable = true;
    webUi = true;
    forceAddrFamily = "ipv4";
    extraConfig = {
      node_name = options.networking.hostName.value;
      server = true;
      bootstrap_expect = 1;
    };
    interface.advertise = "enp1s0";
    interface.bind = "enp1s0";
  };
}
