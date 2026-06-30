{ config, lib, pkgs, nixgl, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = lib.mkAfter ''
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi
    '';
    oh-my-zsh = {
      enable = true;
      theme = "essembeh";
      plugins = [ "git" ];
    };
  };

  programs.direnv.enableZshIntegration = true;

  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = nixgl.packages;
      # Fedora は proprietary NVIDIA 前提。Mesa ICD を固定せず、
      # nixGL の NVIDIA wrapper で GL/Vulkan のユーザー空間を揃える。
      defaultWrapper = "nvidia";
      vulkan.enable = true;
    };
  };

  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;
    enableZshIntegration = true;
    settings = {
      font-family = [
        "HackGen Console NF"
      ];
      font-size = 13;
      adjust-cell-height = "10%";
      background-opacity = 0.94;
      background-opacity-cells = true;
      background-blur = 20;
    };
  };

  programs.zed-editor = {
    enable = true;
    # Mesa ICD は llvmpipe を選ぶため、Fedora/NVIDIA では nixGL に任せる。
    package = config.lib.nixGL.wrap pkgs.zed-editor;
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
      disable-extension-version-validation = true;
      enabled-extensions = [
        "kimpanel@kde.org"
        "Vitals@CoreCoding.com"
      ];
    };
    "org/gnome/shell/extensions/vitals" = {
      hot-sensors = [
        "_processor_usage_"
        "_memory_usage_"
      ];
      update-time = 2;
      show-processor = true;
      show-memory = true;
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
    obsidian
    (config.lib.nixGL.wrap google-chrome)
    ticktick
    bitwarden-desktop
    gnomeExtensions.kimpanel
    gnomeExtensions.vitals
  ];
}
