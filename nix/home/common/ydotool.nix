{ pkgs, ... }:
{
  systemd.user.services.ydotoold = {
    Unit = {
      Description = "ydotool input automation daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionPathExists = "/dev/uinput";
    };

    Service = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
