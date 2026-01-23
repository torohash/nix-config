{ pkgs }:
{
  common = pkgs.callPackage ../packages/common-store.nix {};
  lsp = pkgs.callPackage ../packages/lsp-store.nix {};
}
