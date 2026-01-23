{ buildEnv, htop, cloc, tmux, git, curl, websocat, jq, tree, unzip, bash-completion, xclip, nodejs, ripgrep }:

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
    ripgrep
    xclip
    nodejs
  ];
}
