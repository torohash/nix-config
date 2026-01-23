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
      homeConfig = import ./nix/home/config.nix;
      homeSystem = homeConfig.system;
      homeUsername = homeConfig.username;
      homeDirectory = homeConfig.homeDirectory;
      homeStateVersion = homeConfig.stateVersion;
      mkPackages = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          stores = import ./nix/lib/stores.nix { inherit pkgs; };
        in
        rec {
          common-store = stores.common;
          neovim-store = stores.neovim;
          default = stores.common;
        };
      mkDevShells = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          devshells = import ./nix/lib/devshells.nix { inherit pkgs; };
          pythonShell = devshells.python;
        in
        {
          python = pythonShell;
          default = pythonShell;
        };
    in
    {
      packages = forAllSystems mkPackages;
      devShells = forAllSystems mkDevShells;
      homeConfigurations = {
        ${homeUsername} = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${homeSystem};
          modules = [
            ./nix/home/common.nix
            {
              home.username = homeUsername;
              home.homeDirectory = homeDirectory;
              home.stateVersion = homeStateVersion;
            }
          ];
        };
      };
    };
}
