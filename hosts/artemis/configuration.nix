{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    consul
  ];

  disko.devices.disk.disk1.device = "/dev/vda";

  # No touchy touchy!
  system.stateVersion = "23.11";
}
