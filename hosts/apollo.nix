{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
  ];

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.11";
}
