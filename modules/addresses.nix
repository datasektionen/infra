{ config, lib, ... }:
let
  cfg = config.dsekt.addresses;
  opt = type: lib.mkOption { inherit type; readOnly = true; };
in
{
  options.dsekt.addresses.hosts = opt (lib.types.attrsOf lib.types.str);
  options.dsekt.addresses.groups = opt (lib.types.attrsOf (lib.types.listOf lib.types.str));
  options.dsekt.addresses.subnet = opt lib.types.str;

  config.dsekt.addresses = {
    # Must be kept in sync with `local.cluster_hosts` tf
    hosts = {
      zeus = "10.83.0.2";
      poseidon = "10.83.0.3";
      hades = "10.83.0.4";
      ares = "10.83.0.5";
    };

    groups.cluster-servers = with cfg.hosts; [ zeus poseidon hades ];

    # Must be kept in sync with `hcloud_network_subnet.cluster-main.ip_range` in tf
    subnet = "10.83.0.0/16";
  };
}
