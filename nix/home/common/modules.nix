{ ... }:
{
  imports = [
    ./shell/bash.nix
    ./shell/zsh.nix
    ./editor/neovim.nix
    ./editor/zed.nix
    ./git.nix
    ./dotfiles.nix
    ./herdr.nix
  ];
}
