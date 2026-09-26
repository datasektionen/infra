{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    nomad.mounts
    # patroni
    traefik
  ];

  dsekt.nomad.volumes.host.immich = {
    userId = 0;
    dirs = ["thumbs"];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.11";
}
