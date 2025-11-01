{ config, lib, ... }:
let
  cfg = config.dsekt.addresses;
  opt =
    type:
    lib.mkOption {
      inherit type;
      readOnly = true;
    };

  keepAttrs =
    attrs: keys:
    builtins.listToAttrs (
      map (k: {
        name = k;
        value = attrs.${k};
      }) keys
    );
in
{
  options.dsekt.addresses.hosts = opt (lib.types.attrsOf lib.types.str);
  options.dsekt.addresses.groups = opt (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
  options.dsekt.addresses.subnet = opt lib.types.str;

  config.dsekt.addresses = {
    hosts = lib.fix (self: {
      # Must be kept in sync with `local.cluster_hosts` tf
      zeus = "10.83.0.2";
      poseidon = "10.83.0.3";
      hades = "10.83.0.4";
      ares = "10.83.0.5";
      artemis = "10.83.0.6";
      apollo = "10.83.0.7";
      athena = "10.83.0.8";

      mjukglass = "10.83.1.1";
      drifvarkaden = "10.83.1.2";

      self = self.${config.networking.hostName};
    });

    groups.cluster-servers = keepAttrs cfg.hosts [
      "zeus"
      "poseidon"
      "hades"
    ];

    groups.cluster-clients = keepAttrs cfg.hosts [
      "ares"
      "artemis"
      "apollo"
      "athena"
    ];

    # Enables node exporter metrics server on these hosts
    groups.monitoring = lib.removeAttrs cfg.hosts [
      "mjukglass"
      "drifvarkaden"
      "self"
    ];

    # Must be kept in sync with `hcloud_network.cluster.ip_range` in tf
    subnet = "10.83.0.0/16";
  };
}
