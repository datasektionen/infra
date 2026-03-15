# A basic configuration for systems meant to run on standalone hardware, i.e.
# hardware which isn't a Hetzner instance and isn't connected to Nomad.
{
  profiles,
  pkgs,
  agenix,
  ...
}:
{
  imports = with profiles; [
    nix
    users
    dns
    monitoring
    agenix.nixosModules.default
  ];

  time.timeZone = "Europe/Stockholm";

  environment.systemPackages = with pkgs; [
    curl
    htop
    neovim
    git
  ];

  environment.enableAllTerminfo = true;
  documentation.man.generateCaches = false;

  programs.fish.enable = true;
  programs.zsh.enable = true;

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  hardware.enableRedistributableFirmware = true;
}
