{ ... }:
{
  # Herdr本体は管理せず、設定だけをリポジトリ側で一元管理する。
  xdg.configFile."herdr/config.toml" = {
    source = ../../../dotfiles/herdr/config.toml;
    force = true;
  };
}
