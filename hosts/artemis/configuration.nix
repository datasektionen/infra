{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
  ];

  # No touchy touchy!
  system.stateVersion = "23.11";
}
