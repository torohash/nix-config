{ config, lib, pkgs, nixgl, ... }:
let
  mesaVulkanIcdDir = "${pkgs.mesa}/share/vulkan/icd.d";
  mesaVulkanIcdFiles = builtins.filter
    (name: lib.hasSuffix ".x86_64.json" name)
    (builtins.attrNames (builtins.readDir mesaVulkanIcdDir));
  mesaVulkanIcdList = lib.concatStringsSep ":"
    (map (name: "${mesaVulkanIcdDir}/${name}") mesaVulkanIcdFiles);

  zedWithNixVulkanIcd = pkgs.symlinkJoin {
    name = "zed-editor-with-nix-vulkan-icd";
    paths = [ (config.lib.nixGL.wrap pkgs.zed-editor) ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in zed zeditor zed-editor; do
        if [ -x "$out/bin/$bin" ]; then
          wrapProgram "$out/bin/$bin" \
            --set VK_ICD_FILENAMES "${mesaVulkanIcdList}" \
            --set VK_DRIVER_FILES "${mesaVulkanIcdList}"
        fi
      done
    '';
  };
in
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
      font-size = 13;
      adjust-cell-height = "10%";
      background-opacity = 0.94;
      background-opacity-cells = true;
      background-blur = 20;
    };
  };

  programs.zed-editor = {
    enable = true;
    # ホストの libc と混在させず、Nix 側 Vulkan ICD を明示して起動を安定化する。
    package = zedWithNixVulkanIcd;
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
    obsidian
    (config.lib.nixGL.wrap google-chrome)
    ticktick
    bitwarden-desktop
    gnomeExtensions.kimpanel
  ];
}
