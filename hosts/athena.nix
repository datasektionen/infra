{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    traefik
  ];

  dsekt.nomad.volumes.host.meta-tv = {
    userId = 1000;
    dirs = [
      "uploads"
    ];
  };

  dsekt.nomad.volumes.host.prometheus = {
    userId = 65534; # Runs as nobody
    dirs = [ "prometheus" ];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.11";
}
