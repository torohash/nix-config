# Dotfiles

## Bash aliases

- clip: `xclip -selection clipboard`

`.bash_aliases` が存在する場合は自動で読み込まれます。

## Tmux key bindings

- Prefix: Ctrl+a
- Ctrl+h/j/k/l: Vim を検知して pane 移動またはキー送信
- (copy-mode-vi) Ctrl+h/j/k/l: pane 移動

## Herdr key bindings

Herdr本体はNixで管理せず、`dotfiles/herdr/config.toml`だけを
`~/.config/herdr/config.toml`へ強制配置します。Home Manager管理後は読み取り専用になるため、
設定変更はリポジトリ側で行ってください。

- Prefix: `Ctrl+b`（Herdr既定値）
- `Prefix+,` / `Prefix+.`: 前 / 次のagentへ移動
- `Prefix+Shift+,` / `Prefix+Shift+.`: 前 / 次のworkspaceへ移動
