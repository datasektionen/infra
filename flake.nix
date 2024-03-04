{
  description = "NixOS configurations for Konglig Datasektionens servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, disko, nixos-anywhere, agenix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      nixosConfigurations = builtins.mapAttrs
        (name: _: nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          specialArgs = {
            inherit nixpkgs disko agenix;
            profiles = lib.rakeLeaves ./profiles;
          };
          modules = [
            (./hosts + "/${name}/configuration.nix")
            (_: {
              networking.hostName = name;
              hardware.enableRedistributableFirmware = true;
            })
          ];
        })
        (builtins.readDir ./hosts);
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          nixos-anywhere.packages.${system}.default
          terraform
          agenix.packages.${system}.default
        ];
      };
    };
}
