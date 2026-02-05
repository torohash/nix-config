{
  description = "Generic config store with common tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      homeSystem = "x86_64-linux";
      homeUsername = "torohash";
      homePlatforms = [
        "ubuntu"
        "fedora"
        "wsl"
      ];
      hostModule = platform:
        ./nix/home/hosts + "/${homeUsername}_${platform}.nix";
      mkHomeConfiguration = platform:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${homeSystem};
          modules = [
            (hostModule platform)
          ];
        };
      homeConfigurations = nixpkgs.lib.listToAttrs (map
        (platform: {
          name = "${homeUsername}_${platform}";
          value = mkHomeConfiguration platform;
        })
        homePlatforms);
      mkPackages = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          stores = import ./nix/lib/stores.nix { inherit pkgs; };
        in
        rec {
          common-store = stores.common;
          lsp-store = stores.lsp;
          default = stores.common;
        };
      mkDevShells = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          devshells = import ./nix/lib/devshells.nix { inherit pkgs; };
          pythonShell = devshells.python;
          typescriptShell = devshells.typescript;
        in
        {
          python = pythonShell;
          typescript = typescriptShell;
          default = pythonShell;
        };
    in
    {
      packages = forAllSystems mkPackages;
      devShells = forAllSystems mkDevShells;
      homeConfigurations = homeConfigurations;
    };
}
