{ buildEnv, htop, cloc, tmux }:

buildEnv {
  name = "common-store";
  paths = [
    htop
    cloc
    tmux
  ];
}
