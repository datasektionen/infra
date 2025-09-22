{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.server
  ];

  dsekt.nomad.volumes.host.prometheus = {
    userId = 65534; # Runs as nobody
    dirs = [ "prometheus" ];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "23.11";
}
