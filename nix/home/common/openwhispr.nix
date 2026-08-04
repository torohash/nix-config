{ pkgs, ... }:

let
  shortcutPath =
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/openwhispr/";
in
{
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ shortcutPath ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/openwhispr" = {
      name = "OpenWhispr Toggle";
      binding = "<Control><Shift>k";
      command = "${pkgs.dbus}/bin/dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.Toggle";
    };
  };
}
