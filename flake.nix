{
  description = "NixOS configurations for Konglig Datasektionen's servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      nixos-anywhere,
      agenix,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;
      nixosConfigurations = nixpkgs.lib.mapAttrs' (
        name: _:
        let
          hostname = nixpkgs.lib.removeSuffix ".nix" name;
        in
        {
          name = hostname;
          value = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            specialArgs = {
              inherit nixpkgs disko agenix;
              profiles = lib.rakeLeaves ./profiles;
              secretsDir = ./secrets;
            };
            modules = [
              (./hosts + "/${name}")
              (_: { networking.hostName = hostname; })
            ] ++ (nixpkgs.lib.collect builtins.isPath (lib.rakeLeaves ./modules));
          };
        }
      ) (builtins.readDir ./hosts);
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages =
          [
            nixos-anywhere.packages.${system}.default
            agenix.packages.${system}.default
          ]
          ++ (with pkgs; [
            age
            age-plugin-yubikey
            opentofu
            nomad
            gh
            jq
          ]);
      };
    };
}
