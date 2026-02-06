{ config, pkgs, nixgl, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "essembeh";
      plugins = [ "git" ];
    };
  };

  programs.direnv.enableZshIntegration = true;

  targets.genericLinux = {
    enable = true;
    nixGL.packages = nixgl.packages;
  };

  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;
    enableZshIntegration = true;
    settings = {
      font-family = [
        "HackGen Console NF"
      ];
      font-size = 14;
      adjust-cell-height = "10%";
      background-opacity = 0.90;
      background-blur = 20;
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        kdePackages.fcitx5-qt
      ];
    };
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "kimpanel@kde.org"
      ];
    };
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = [ "<Super><Shift>s" ];
      screenshot = [ "<Super><Shift>3" ];
      screenshot-window = [ "<Super><Shift>4" ];
    };
  };

  xdg.configFile."fcitx5/config" = {
    text = ''
      [Hotkey/TriggerKeys]
      0=Shift_L
      1=Control+space
    '';
  };

  xdg.configFile."zellij/config.kdl" = {
    text = ''
      default_shell "${config.home.homeDirectory}/.nix-profile/bin/zsh"
    '';
    force = true;
  };

  home.packages = with pkgs; [
    hackgen-nf-font
    (config.lib.nixGL.wrap google-chrome)
    ticktick
    bitwarden-desktop
    gnomeExtensions.kimpanel
  ];
}
