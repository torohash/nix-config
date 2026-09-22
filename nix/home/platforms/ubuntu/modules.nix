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
  openwhispr = pkgs.callPackage ../../../packages/openwhispr.nix { };
in
{
  imports = [
    ../../common/openwhispr.nix
    ../../common/ydotool.nix
  ];

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
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      kdePackages.fcitx5-qt
    ];
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
      # fcitx5 の既定値は AltTriggerKeys=Shift_L で、Shift 単独でも切り替わる。
      # 切り替えは Control+space だけにするため、空にして既定値を打ち消す。
      [Hotkey]
      AltTriggerKeys=
      [Hotkey/TriggerKeys]
      0=Control+space
    '';
  };

  # 設定ファイルを差し替えたときに fcitx5 が読み直すようにする。
  systemd.user.services.fcitx5-daemon.Unit.X-Restart-Triggers = [
    config.xdg.configFile."fcitx5/config".source
  ];

  xdg.configFile."zellij/config.kdl" = {
    text = ''
      default_shell "${config.home.homeDirectory}/.nix-profile/bin/zsh"
    '';
    force = true;
  };

  home.packages = with pkgs; [
    hackgen-nf-font
    obsidian
    google-chrome
    ticktick
    bitwarden-desktop
    openwhispr
    gnomeExtensions.kimpanel
  ];
}
