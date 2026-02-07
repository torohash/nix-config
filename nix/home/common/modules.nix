{ ... }:
{
  imports = [
    ./shell/bash.nix
    ./editor/neovim.nix
    ./editor/zed.nix
    ./git.nix
    ./dotfiles.nix
  ];
}
