{ pkgs, ... }:
{
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
  };

  xdg.configFile."fcitx5/config" = {
    text = ''
      [Hotkey/TriggerKeys]
      0=Shift_L
      1=Control+space
    '';
  };

  home.packages = with pkgs; [
    google-chrome
    obsidian
    ticktick
    bitwarden-desktop
    gnomeExtensions.kimpanel
  ];
}
