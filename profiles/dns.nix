{
  config,
  pkgs,
  lib,
  ...
}:
let
  # We must allow the 83-address, otherwise queries from the host are denied. The 127-address
  # probably doesn't have to be allowed, but it's probably be nice if `host some-domain.name
  # localhost` works. The 172-address is needed to allow docker containers to make queries.
  allowedNetworks = [
    config.dsekt.addresses.subnet
    "127.0.0.0/24"
    "172.16.0.0/12"
  ];

  # Creates monitoring DNS records like:
  #
  # _node._tcp.monitoring.dsekt.internal. 86400 IN SRV 10 5 9100 node-1.dsekt.internal.
  # _node._tcp.monitoring.dsekt.internal. 86400 IN SRV 10 5 9100 node-2.dsekt.internal.
  # ...
  #
  # These SRV recors can be used by Prometheus to discover targets for scraping.
  mkMonitoringRecords =
    name: group: port:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        hostname: address:
        "${name}._tcp.monitoring.dsekt.internal. 86400 IN SRV 10 5 ${builtins.toString port} ${hostname}.dsekt.internal."
      ) group
    );
in
{
  environment.etc."resolv.conf".text = ''
    nameserver ${config.dsekt.addresses.hosts.self}
    options edns0
  '';

  # We must open the ports to make docker containers be able to reach the dns server. Opening up the
  # ports on just `docker0` would also not work since docker creates interfaces dynamically when
  # creating networks.
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.bind = {
    enable = true;

    # All queries must be made to the ip address in the private "cluster" network. This is also the
    # only network that works from both the host and docker containers.
    listenOn = [ config.dsekt.addresses.subnet ];
    ipv4Only = true;
    cacheNetworks = allowedNetworks;

    forward = "first";
    forwarders = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    zones."dsekt.internal" = {
      master = true;
      file = pkgs.writeText "dsekt.internal" ''
        $TTL 2h
        $ORIGIN dsekt.internal.
        @ SOA ns hostmaster (
          1984 ; serial
          12h  ; refresh
          15m  ; update retry
          3w   ; expiry
          2h   ; minimum ttl
        )
                 NS    ns
        ns       A     ${config.dsekt.addresses.hosts.self}

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (hostname: address: "${hostname} A ${address}") config.dsekt.addresses.hosts
        )}
        *.nomad  A     ${config.dsekt.addresses.hosts.self}

        # Prometheus node exporter for all monitoring nodes.
        ${mkMonitoringRecords "_node" config.dsekt.addresses.groups.monitoring
          config.services.prometheus.exporters.node.port
        }

        # Nomad client metrics for all nomad client nodes.
        ${mkMonitoringRecords "_nomad" config.dsekt.addresses.groups.cluster-clients 4646}

        postgres   CNAME ares
        ldap-proxy CNAME mjukglass
        mediawiki  CNAME ares
      '';
      allowQuery = allowedNetworks;
    };
  };
}
