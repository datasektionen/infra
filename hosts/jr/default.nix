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
  ];

  networking.networkmanager.enable = true;

  # Configuration for the VM build of this NixOS configuration, built with
  # `nixos-rebuild build-vm --flake .#jr`.
  virtualisation.vmVariant = {
    imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

    virtualisation.memorySize = 4096;
    virtualisation.qemu = {
      options = [
        # Configure one connected 1920x1080 screens.
        "-vga none"
        "-device virtio-gpu-pci,max_outputs=1,xres=1920,yres=1080"
        # Use GTK for the host window, which shows drop-down menus.
        "-display gtk,gl=on"
      ];
    };
  };

  users.users."jr" = {
    isNormalUser = true;
    home = "/home/jr";
    createHome = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDbk+jGRrhHKrGyLxEqoMFAXngWyX3xGulpHF1iiRdW oskar@Oskars-MacBook-Air.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIy8Um/ysc1Or8r6t39qz97HEFmfRRFfWCEUJKN/m9Dk rasmus@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4o+kiVWP3EBrNOvRzxv4wJZXTHnlo3UkijIShC8xRZ emma@krlsg.se"
    ];
    hashedPassword = "$y$j9T$MuvUDHty2E3GvqzOPTshd/$gYBqTBSklHnboZr0WnNndNyZMr2PPIYP/8uvnInHwM6";
    shell = pkgs.fish;
  };
  # Force the configured password to be used.
  users.mutableUsers = false;

  networking.firewall.checkReversePath = "loose";

  networking.wg-quick.interfaces.wg-dsekt = {
    address = [ "10.83.1.4/32" ];
    privateKeyFile = config.age.secrets.wireguard-jr-private-key.path;
    peers = [
      {
        endpoint = "zeus.datasektionen.se:51800";
        presharedKeyFile = config.age.secrets.wireguard-preshared-key.path;
        publicKey = "BTpGRxLRjCYUiti/5A4uNvKYp0biNkA6PTV7Yck/NxM=";
        allowedIPs = [ "10.83.0.0/16" ];
        persistentKeepalive = 25;
      }
    ];

    postUp = ''
      ${pkgs.networkmanager}/bin/nmcli d modify wlan0 ipv4.dns "127.0.0.1"
    '';

    preDown = ''
      ${pkgs.networkmanager}/bin/nmcli d modify wlan0 ipv4.dns "1.1.1.1";
    '';
  };

  age.secrets.wireguard-jr-private-key.file = secretsDir + "/wireguard-jr-private-key.age";
  age.secrets.wireguard-preshared-key.file = secretsDir + "/wireguard-preshared-key.age";

  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  environment.systemPackages = with pkgs; [
    alacritty
    git
  ];

  # Configure Swedish keyboard layout for TTYs.
  console.keyMap = "sv-latin1";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "jr";
        command = "${pkgs.hyprland}/bin/start-hyprland";
      };
    };
  };

  environment.etc."xdg/hypr/hyprland.lua".text = ''
    -- Import the default configuration.
    require("${pkgs.hyprland}/share/hypr/hyprland.lua")

    hl.monitor{
      output   = "",
      mode     = "1920x1080@60",
      position = "auto",
      scale    = "1",
    }
    hl.monitor{
      output   = "HDMI-A-1",
      mode     = "1920x1080@60",
      position = "auto",
      scale    = 1,
    }

    hl.workspace_rule{ workspace = "1", monitor = "HDMI-A-1" }

    hl.on("hyprland.start", function()
      -- Use orange Catppuccin unicat wallpaper. :)
      -- It is MIT licensed, so it should be fine.
      hl.exec_cmd("${pkgs.swaybg}/bin/swaybg --mode fill --image ${
        pkgs.fetchurl {
          url = "https://github.com/VipinVIP/wallpapers/blob/283af350981b2335f50239096927fd6cf553a82d/minimalistic/peach_unicat.png?raw=true";
          name = "peach_unicat.png";
          hash = "sha256-p00U9t32Zy7Dfa4HOJz3MX7wyd4Fk96YrVrvpiGiCPY=";
        }
      }")

      -- Launch METAclock
      hl.exec_cmd("${pkgs.firefox}/bin/firefox --kiosk https://sl.datasektionen.se/tv", { workspace = "1 silent" })
    end)

    local terminal = "${pkgs.alacritty}/bin/alacritty"

    hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
    -- For some reason the default config configures Super+Q to launch a
    -- terminal... Make sure we're consistent with it.
    hl.bind("SUPER + Q", hl.dsp.exec_cmd(terminal))

    hl.config{
      -- Configure Swedish keyboard layout.
      input = {
        kb_layout = "se"
      },

      -- Hide cursor when inactive
      cursor = {
        inactive_timeout = 5
      },
    }
  '';

  environment.etc."alacritty/alacritty.toml".text = ''
    [font]
    # Increase the font size so that the text is readable on the TV.
    size = 24
  '';

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "26.11";

  ## Hardware configuration

  boot.initrd.availableKernelModules = [
    "usbhid"
    "sdhci_brcmstb"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
}
