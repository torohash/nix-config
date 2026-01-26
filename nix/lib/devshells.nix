{ pkgs }:
{
  python = pkgs.callPackage ../devshells/python.nix {};
  typescript = pkgs.callPackage ../devshells/typescript.nix {};
}
