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
  programs.zsh.enable = true;

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  hardware.enableRedistributableFirmware = true;
}
