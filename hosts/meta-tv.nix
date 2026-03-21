{
  config,
  profiles,
  pkgs,
  lib,
  modulesPath,
  secretsDir,
  ...
}:
{
  imports = with profiles; [
    base
    nomad.client
    traefik
  ];

  networking.networkmanager.enable = true;

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
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIy8Um/ysc1Or8r6t39qz97HEFmfRRFfWCEUJKN/m9Dk rasmus@nixos"
    ];
    hashedPassword = "$y$j9T$MuvUDHty2E3GvqzOPTshd/$gYBqTBSklHnboZr0WnNndNyZMr2PPIYP/8uvnInHwM6";
    shell = pkgs.fish;
  };
  # Force the configured password to be used.
  users.mutableUsers = false;

  networking.wg-quick.interfaces.wg-dsekt = {
    address = [ "10.83.1.3/32" ];
    privateKeyFile = config.age.secrets.wireguard-meta-tv-private-key.path;
    peers = [
      {
        endpoint = "hades.datasektionen.se:51800";
        presharedKeyFile = config.age.secrets.wireguard-preshared-key.path;
        publicKey = "BTpGRxLRjCYUiti/5A4uNvKYp0biNkA6PTV7Yck/NxM=";
        allowedIPs = [ "10.83.0.0/16" ];
        persistentKeepalive = 25;
      }
    ];
  };

  age.secrets.wireguard-meta-tv-private-key.file = secretsDir + "/wireguard-meta-tv-private-key.age";
  age.secrets.wireguard-preshared-key.file = secretsDir + "/wireguard-preshared-key.age";

  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  environment.systemPackages = with pkgs; [ alacritty git ];

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
    # terminal... Make sure we're consistent with it.
    bind = Super, Q, exec, $terminal

    # Configure Swedish keyboard layout.
    input {
      kb_layout = se
    }

    # Use orange Catppuccin unicat wallpaper. :)
    # It is MIT licensed, so it should be fine.
    exec-once = ${pkgs.swaybg}/bin/swaybg --mode fill --image ${
      pkgs.fetchurl {
        url = "https://github.com/VipinVIP/wallpapers/blob/283af350981b2335f50239096927fd6cf553a82d/minimalistic/peach_unicat.png?raw=true";
        name = "peach_unicat.png";
        hash = "sha256-p00U9t32Zy7Dfa4HOJz3MX7wyd4Fk96YrVrvpiGiCPY=";
      }
    }
  '';

  environment.etc."alacritty/alacritty.toml".text = ''
    [font]
    # Increase the font size so that the text is readable on the TVs.
    size = 24
  '';

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "25.11";

  services.cloudflare-ddns = {
    enable = true;
    domains = [ "meta.datasektionen.se" ];
    recordComment = "Updated dynamically by meta tv";
    credentialsFile = config.age.secrets.cloudflare-ddns-api-token.path;
  };

  age.secrets.cloudflare-ddns-api-token = {
    file = secretsDir + "/cloudflare-dns-api-token.env.age";
    inherit (config.services.cloudflare-ddns) group;
    owner = config.services.cloudflare-ddns.user;
    mode = "0440";
  };

  # ## NVIDIA GPU support (for Nomad jobs requiring GPU access)
  #
  # # Enable NVIDIA drivers.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
  };

  # Enable the NVIDIA Container Toolkit so Docker containers can access the GPU.
  hardware.nvidia-container-toolkit.enable = true;

  # # Configure the Nomad nvidia-gpu device plugin so Nomad can fingerprint
  # # and allocate GPU resources to jobs.
  # services.nomad.settings.plugin.nvidia-gpu.config = {
  #   enabled = true;
  #   fingerprint_period = "1m";
  # };

  ## Hardware configuration

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # ++ [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
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
