# GNOMEショートカットと関連設定メモ

## 目的

- Ubuntu/Fedora 向け Home Manager 設定で追加した GNOME ショートカットを忘れないための記録。
- 同じ差分で入った関連変更（アプリ追加・端末設定）も合わせて記録。

## 対象ファイル

- `nix/home/platforms/ubuntu/modules.nix`
- `nix/home/platforms/fedora/modules.nix`

## 追加した GNOME ショートカット

`dconf.settings` の `"org/gnome/shell/keybindings"` に以下を追加。

- `show-screenshot-ui = [ "<Super><Shift>s" ];`
- `screenshot = [ "<Super><Shift>3" ];`
- `screenshot-window = [ "<Super><Shift>4" ];`

## 同時に入った関連変更

### 1) Zellij のデフォルトシェル固定

`xdg.configFile."zellij/config.kdl"` を追加し、以下を設定。

- `default_shell "${config.home.homeDirectory}/.nix-profile/bin/zsh"`
- `force = true`（既存ファイルがあっても Home Manager 側設定を優先）

### 2) Ghostty の追加

Ubuntu/Fedora の `programs.ghostty` を有効化。

- `programs.ghostty.enable = true`
- `programs.ghostty.enableZshIntegration = true`

補足: パッケージ一覧の説明は `docs/packages.md` を参照。

## 反映・確認

設定反映:

```bash
home-manager switch --flake nixcfg#torohash_ubuntu
# または
home-manager switch --flake nixcfg#torohash_fedora
```

ショートカット設定確認:

```bash
gsettings get org.gnome.shell.keybindings show-screenshot-ui
gsettings get org.gnome.shell.keybindings screenshot
gsettings get org.gnome.shell.keybindings screenshot-window
```

補足: `gsettings get` の出力は環境により修飾キー順序が入れ替わって見える場合がある（例: `<Shift><Super>`）。
