{
  modulesPath,
  disko,
  lib,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    disko.nixosModules.disko
    ./disks.nix
  ];

  boot.loader.grub = {
    enable = lib.mkDefault true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
