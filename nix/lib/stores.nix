{ pkgs }:
{
  common = pkgs.callPackage ../packages/common-store.nix {};
  neovim = pkgs.callPackage ../packages/neovim-store.nix {};
}
