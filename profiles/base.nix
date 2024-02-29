{ profiles, pkgs, ... }:
{
  imports = with profiles; [
    nix
    users
  ];

  time.timeZone = "Europe/Stockholm";

  environment.systemPackages = with pkgs; [
    curl
    htop
  ];

  environment.enableAllTerminfo = true;

  programs.command-not-found.enable = false;
  programs.fish.enable = true;

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
