# AIエージェントの設定。
# 一度すべて外し、残す価値のあるものだけを配置する。
{ pkgs, lib, ... }:
{
  # Claude Codeのグローバル指示(回答の言語・コミットの署名)を配置する。
  # settings.jsonはOmarchyとClaude Code自身も書くため、ここでは扱わない。
  home.file.".claude/CLAUDE.md" = {
    source = ../../../dotfiles/claude/CLAUDE.md;
    force = true;
  };

  # Piモデルの長いコンテキストを有効にする設定を配置する。
  home.file.".pi/agent/models.json" = {
    source = ../../../dotfiles/pi/models.json;
    force = true;
  };

  # Piが更新する設定を残したまま、自動圧縮の余白だけを設定する。
  # packageはPi自身の `pi install` で管理する (docs/pi-packages.md)。
  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="$HOME/.pi/agent"
    settings_file="$settings_dir/settings.json"
    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "$settings_file.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp_file"' EXIT

    if [ -f "$settings_file" ]; then
      ${pkgs.jq}/bin/jq \
        '.compaction = ((.compaction // {}) + {"enabled": true, "reserveTokens": 150000})' \
        "$settings_file" > "$tmp_file"
    else
      ${pkgs.jq}/bin/jq \
        --null-input \
        '{
          "compaction": {
            "enabled": true,
            "reserveTokens": 150000
          }
        }' > "$tmp_file"
    fi

    ${pkgs.coreutils}/bin/chmod 0644 "$tmp_file"
    ${pkgs.coreutils}/bin/mv "$tmp_file" "$settings_file"
    trap - EXIT
  '';

  # Pi Web Accessの検索順序と切り替え条件を配置する。
  home.file.".pi/web-search.json" = {
    source = ../../../dotfiles/pi/web-search.json;
    force = true;
  };
}
