{ config, lib, ... }:
{
  programs.zed-editor.userSettings = {
    ui_font_family = "HackGen Console NF";
    buffer_font_family = "HackGen Console NF";
    icon_theme = "Catppuccin Mocha";
    theme_overrides = {
      "One Dark" = {
        "background.appearance" = "transparent";
        "background" = "#00000066";
        "title_bar.background" = "#00000099";
        "title_bar.inactive_background" = "#00000080";
        "toolbar.background" = "#00000099";
        "status_bar.background" = "#000000a6";
        "tab_bar.background" = "#0000008c";
        "tab.inactive_background" = "#0000008c";
        "tab.active_background" = "#000000b3";
        "panel.background" = "#0000008c";
        "editor.background" = "#000000b0";
        "editor.gutter.background" = "#000000b0";
        "surface.background" = "#000000a6";
        "elevated_surface.background" = "#000000b3";
        "element.background" = "#00000080";
        "ghost_element.background" = "#00000033";
      };
    };
    auto_install_extensions = {
      "catppuccin-icons" = true;
      "git-firefly" = true;
      "nix" = true;
    };
    languages = {
      Nix = {
        language_servers = [ "nixd" "!nil" ];
      };
    };
    terminal = {
      font_family = "HackGen Console NF";
    };
  };

  programs.zsh.shellAliases = lib.mkIf config.programs.zed-editor.enable {
    zed = "zeditor";
  };
}
