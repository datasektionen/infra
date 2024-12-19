{
  config,
  pkgs,
  profiles,
  secretsDir,
  ...
}:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.server
  ];

  # Requires `hcloud_network_route.wireguard-router` in tf for `10.83.0.0/24`
  # to route packets to `10.83.1.0/24` to here.
  networking.wg-quick.interfaces.wg-dsekt = {
    address = [ "10.83.1.0/24" ];
    listenPort = 51800;
    privateKeyFile = config.age.secrets.wireguard-hades-private-key.path;
    # For some reason, specifying `-o ens10` here and adding a rule for
    # forwarding from ens10 to wg-dsekt makes stuff not work at all. This seems
    # to, however to allow forwarding between `10.83.0.0/24` and `10.83.1.0/24`
    # but not from `10.83.1.0/24` to the internet. That is exactly what we want
    # so even though I have no idea why it works, I'm happy that it does 💀.
    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg-dsekt -j ACCEPT
    '';
    preDown = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg-dsekt -j ACCEPT
    '';
    peers = [
      {
        # mjukglass
        presharedKeyFile = config.age.secrets.wireguard-preshared-key.path;
        publicKey = "QszePOBh9UBg8v4BNHkY4ZeqBfiLXr5uwDVjTSRqHX0=";
        allowedIPs = [ "10.83.1.1/32" ];
      }
    ];
  };
  networking.firewall.allowedUDPPorts = [ 51800 ];
  # Needed to forward packets between the subnets.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  age.secrets.wireguard-preshared-key.file = secretsDir + "/wireguard-preshared-key.age";
  age.secrets.wireguard-hades-private-key.file = secretsDir + "/wireguard-hades-private-key.age";

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "23.11";
}
