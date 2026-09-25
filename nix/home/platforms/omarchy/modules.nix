# Omarchy (Arch Linux + Hyprland) 向けの構成。
#
# Omarchyを優先する。Omarchyが配置・テーマ追従・refreshするファイルと、
# Omarchyが pacman / mise で入れるパッケージ・CLIはHome Managerで扱わない。
# そのため common/modules.nix は読み込まず、AIエージェント設定だけを扱う。
# 所有者の一覧は docs/omarchy.md を参照。
{ ... }:
{
  imports = [
    ../../common/agents.nix
  ];

  programs.home-manager.enable = true;
  # man-db は Omarchy が pacman で入れている。
  programs.man.enable = false;
}
