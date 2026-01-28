{ buildEnv, htop, cloc, tmux, git, curl, websocat, jq, tree, unzip, bash-completion, xclip, nodejs, ripgrep, terraform, terraform-ls, awscli2, ssm-session-manager-plugin }:

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
    terraform
    terraform-ls
    awscli2
    ssm-session-manager-plugin
  ];
}
