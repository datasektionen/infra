{ profiles, pkgs, ... }:
{
  imports = with profiles; [
    nix
    users
  ];

  environment.systemPackages = with pkgs; [
    curl
    htop
  ];

  time.timeZone = "Europe/Stockholm";

  programs.command-not-found.enable = false;
  programs.fish.enable = true;

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
