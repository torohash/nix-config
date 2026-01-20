{ buildEnv, htop, cloc, tmux, git, curl, websocat, jq, tree, unzip, bash-completion, nixd }:

buildEnv {
  name = "common-store";
  paths = [
    htop
    cloc
    tmux
    git
    curl
    websocat
    jq
    tree
    unzip
    bash-completion
    nixd
  ];
}
