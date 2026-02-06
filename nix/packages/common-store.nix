{ buildEnv, htop, btop, cloc, tmux, zellij, git, curl, websocat, jq, tree, unzip, bash-completion, chafa, ripgrep, xclip, nodejs, yazi, lazygit, terraform, terraform-ls, awscli2, ssm-session-manager-plugin }:

buildEnv {
  name = "common-store";
  paths = [
    htop
    btop
    cloc
    tmux
    zellij
    git
    curl
    websocat
    jq
    tree
    unzip
    bash-completion
    chafa
    ripgrep
    xclip
    nodejs
    yazi
    lazygit
    terraform
    terraform-ls
    awscli2
    ssm-session-manager-plugin
  ];
}
