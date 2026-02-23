{ config, profiles, pkgs, lib, modulesPath, secretsDir, ... }:
{
  imports = with profiles; [
    base-standalone
  ];

  # Configuration for the VM build of this NixOS configuration, built with
  # `nixos-rebuild build-vm --flake .#meta-tv`.
  virtualisation.vmVariant = {
    imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

    virtualisation.qemu = {
      options = [
        # Increase available memory.
        "-m 4096"
        # Configure three connected 1920x1080 screens.
        "-vga none"
        "-device virtio-gpu-pci,max_outputs=3,xres=1920,yres=1080"
        # Use GTK for the host window, which shows drop-down menus.
        "-display gtk,gl=on"
      ];
    };
  };

  users.users."meta-tv" = {
    isNormalUser = true;
    home = "/home/meta-tv";
    createHome = true;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIy8Um/ysc1Or8r6t39qz97HEFmfRRFfWCEUJKN/m9Dk rasmus@nixos"
    ];
    hashedPassword = "$y$j9T$MuvUDHty2E3GvqzOPTshd/$gYBqTBSklHnboZr0WnNndNyZMr2PPIYP/8uvnInHwM6";
    shell = pkgs.fish;
  };

  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  environment.systemPackages = with pkgs; [ alacritty ];

  # Configure Swedish keyboard layout for TTYs.
  console.keyMap = "sv-latin1";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "meta-tv";
        command = "${pkgs.hyprland}/bin/Hyprland";
      };
    };
  };

  environment.etc."xdg/hypr/hyprland.conf".text = ''
    # Import the default configuration.
    source = ${pkgs.hyprland}/share/hypr/hyprland.conf

    monitor = , 1920x1080@60, auto, 1
    monitor = DVI-D-1, 1920x1080@60, auto, 1
    monitor = DP-1, 1920x1080@60, auto, 1
    monitor = HDMI-A-1, 1920x1080@60, auto, 1

    workspace = 1, monitor:DVI-D-1
    workspace = 2, monitor:DP-1
    workspace = 3, monitor:HDMI-A-1

    exec-once = [workspace 1 silent] ${pkgs.chromium}/bin/chromium --kiosk --no-first-run --class=tv1 --user-data-dir=/tmp/tv1 "https://tv.datasektionen.se/feed/1"
    exec-once = [workspace 2 silent] ${pkgs.chromium}/bin/chromium --kiosk --no-first-run --class=tv2 --user-data-dir=/tmp/tv2 "https://tv.datasektionen.se/feed/2"
    exec-once = [workspace 3 silent] ${pkgs.chromium}/bin/chromium --kiosk --no-first-run --class=tv3 --user-data-dir=/tmp/tv3 "https://tv.datasektionen.se/feed/3"

    $terminal = ${pkgs.alacritty}/bin/alacritty

    bind = Super, T, exec, $terminal
    # For some reason the default config configures Super+Q to launch a
    # terminal... Make sure were consistent with it.
    bind = Super, Q, exec, $terminal

    # Configure Swedish keyboard layout.
    input {
      kb_layout = se
    }

    # Only use the anime wallpaper :)
    misc {
      force_default_wallpaper = 2
    }
  '';

  environment.etc."alacritty/alacritty.toml".text = ''
    [font]
    # Increase the font size so that the text is readable on the TVs.
    size = 24
  '';

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "25.11";

  ## Hardware configuration

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Configure bootloader device.
  boot.loader.grub.device = "/dev/sda";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
