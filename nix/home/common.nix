{ ... }:
{
  programs.home-manager.enable = true;

  programs.bash.enable = true;

  programs.direnv.enable = true;
  programs.direnv.enableBashIntegration = true;
  programs.direnv.nix-direnv.enable = true;
}
