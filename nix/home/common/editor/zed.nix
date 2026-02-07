{ config, lib, ... }:
{
  programs.zed-editor.userSettings = {
    ui_font_family = "HackGen Console NF";
    buffer_font_family = "HackGen Console NF";
    terminal = {
      font_family = "HackGen Console NF";
    };
  };

  programs.zsh.shellAliases = lib.mkIf config.programs.zed-editor.enable {
    zed = "zeditor";
  };
}
