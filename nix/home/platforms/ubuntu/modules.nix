{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      kdePackages.fcitx5-qt
    ];
  };

  home.packages = with pkgs; [
    google-chrome
    obsidian
    ticktick
    bitwarden-desktop
  ];
}
