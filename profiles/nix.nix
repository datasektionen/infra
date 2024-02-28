{ pkgs, nixpkgs, ... }:
{
  nix.registry.nixpkgs.flake = nixpkgs;
  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
  ];

  nix.settings.trusted-users = [ "@wheel" ];

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes

    min-free = ${toString (1024 * 1024 * 1024)}
    max-free = ${toString (10 * 1024 * 1024 * 1024)}
  '';
}
