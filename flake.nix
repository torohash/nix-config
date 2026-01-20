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
          python-store = stores.python;
          default = stores.common;
        };
    in
    {
      packages = forAllSystems mkPackages;
    };
}
