{ config, profiles, ... }:
{
  imports = [ profiles.consul.shared ];

  services.consul = {
    extraConfig = {
      server = true;
      bootstrap_expect = builtins.length config.dsekt.addresses.cluster-servers;
    };
  };

  networking.firewall.allowedTCPPorts = [
    8300 # server rpc
    8302 # wan serf
  ];
}
