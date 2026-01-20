{ pkgs }:
{
  common = pkgs.callPackage ../packages/common-store.nix {};
  python = pkgs.callPackage ../packages/python-store.nix {};
}
