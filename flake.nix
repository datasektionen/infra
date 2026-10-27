{
  description = "NixOS configurations for Konglig Datasektionen's servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware-unstable = {
      url = "github:nixos/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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
      nixpkgs-unstable,
      nixos-hardware-unstable,
      disko,
      nixos-anywhere,
      agenix,
      ...
    }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };

      mkHost = hostname: path: {
        inherit hostname path;
        machineInfo = import (path + "/machine-info.nix");
        configuration = import (path + "/default.nix");
      };
      hostnames = (
        lib.filterAttrs (
          name: type: type == "directory" && lib.pathExists (./hosts + "/${name}/machine-info.nix")
        ) (builtins.readDir ./hosts)
      );
      hosts = builtins.mapAttrs (hostname: _: mkHost hostname (./hosts + "/${hostname}")) hostnames;

      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
      nixosConfigurations =
        let
          mkConfiguration =
            _: m:
            let
              nixpkgs-impl = if (m.machineInfo.unstable or false) then nixpkgs-unstable else nixpkgs;
            in
            nixpkgs-impl.lib.nixosSystem {
              system = m.machineInfo.arch;
              pkgs = import nixpkgs-impl {
                system = m.machineInfo.arch;
                config.allowUnfree = true;
              };
              specialArgs = {
                inherit
                  agenix
                  disko
                  nixos-hardware-unstable
                  nixpkgs-unstable
                  ;
                # even unstable-default hosts can access stable through this
                nixpkgs-stable = nixpkgs;
                nixpkgs = nixpkgs-impl;

                profiles = lib.rakeLeaves ./profiles;
                secretsDir = ./secrets;
              };
              modules = [
                {
                  networking.hostName = m.hostname;
                }
                m.configuration
              ]
              ++ (lib.collect builtins.isPath (lib.rakeLeaves ./modules));
            };
        in
        builtins.mapAttrs mkConfiguration hosts;

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages =
            let
              inherit (pkgs.stdenv.hostPlatform) system;
            in
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
              nixos-rebuild
            ]);
        };
      });
    };
}
