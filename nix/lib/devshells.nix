{ pkgs }:
{
  python = pkgs.callPackage ../devshells/python.nix {};
  typescript = pkgs.callPackage ../devshells/typescript.nix {};
  pencil = pkgs.callPackage ../devshells/pencil.nix {};
  jupyterlab = pkgs.callPackage ../devshells/jupyterlab.nix {};
  godot = pkgs.callPackage ../devshells/godot.nix {};
}
