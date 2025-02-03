{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    traefik
  ];

  dsekt.nomad.volumes.host.vault = {
    userId = 0; # vaultwarden runs as root
    dirs = [ "data" ];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.05";
}
