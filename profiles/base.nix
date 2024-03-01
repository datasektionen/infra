{ profiles, pkgs, agenix, ... }:
{
  imports = with profiles; [
    nix
    users
    agenix.nixosModules.default
  ];

  time.timeZone = "Europe/Stockholm";

  environment.systemPackages = with pkgs; [
    curl
    htop
    neovim
  ];

  environment.enableAllTerminfo = true;

  programs.command-not-found.enable = false;
  programs.fish.enable = true;

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
