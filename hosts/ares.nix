{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    consul.client
    nomad.client
  ];

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "23.11";
}