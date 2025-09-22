{ config, lib, ... }:
let
  self = config.dsekt.addresses.hosts.self;
  monitor-hosts = builtins.attrNames config.dsekt.addresses.groups.monitoring;
in
{
  services.prometheus.exporters.node = {
    enable = lib.mkIf (builtins.elem self monitor-hosts) true;
    enabledCollectors = [ "systemd" ];
    openFirewall = true;
    port = 9100; # default port
  };
}
