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

        postgres   CNAME ares
        ldap-proxy CNAME mjukglass
      '';
      allowQuery = allowedNetworks;
    };
  };
}
