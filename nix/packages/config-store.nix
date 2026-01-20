{ pkgs }:

pkgs.buildEnv {
  name = "config-store";
  paths = [
    pkgs.htop
    pkgs.cloc
    pkgs.tmux
  ];
}
