{
  description = "Generic config store with common tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      mkPackages = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          stores = import ./nix/lib/stores.nix { inherit pkgs; };
        in
        rec {
          common-store = stores.common;
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
    };
}
