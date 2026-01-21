{ buildEnv, htop, cloc, tmux, git, curl, websocat, jq, tree, unzip, bash-completion, nixd, xclip }:

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
    xclip
  ];
}
