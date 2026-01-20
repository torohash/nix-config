{ pkgs }:
{
  common = pkgs.callPackage ../packages/common-store.nix {};
}
