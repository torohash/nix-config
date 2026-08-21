# packages

## common-store

- htop: 端末で動作するプロセスビューア。
- btop: CPU/メモリ/ディスク/ネットワークを見やすく表示するリソースモニタ。
- cloc: 言語別のコード行数を集計するツール。
- tmux: 端末セッションを分割・管理するためのマルチプレクサ。
- zellij: Rust 製の端末マルチプレクサ。
- git: 分散バージョン管理システム。
- gh: GitHub を操作する公式 CLI。
- lazygit: Git の TUI クライアント。
- curl: HTTP/HTTPS クライアント。
- websocat: WebSocket クライアント。
- jq: JSON フィルタ/整形ツール。
- tree: ディレクトリ構造表示ツール。
- yazi: Rust 製ファイルマネージャ。
- unzip: ZIP 展開ツール。
- bash-completion: bash の補完定義。
- chafa: 端末画像ビューア。
- ripgrep: 高速な検索ツール（rg）。
- xclip: X11 クリップボード操作ツール。
- nodejs: Node.js ランタイム。
- mise: 複数言語のツールチェーンとバージョンを管理するランタイムマネージャー。
- vim: 軽量で拡張性の高いテキストエディタ。
- terraform: Terraform CLI。
- terraform-ls: Terraform の LSP サーバ。
- awscli2: AWS CLI v2。
- ssm-session-manager-plugin: AWS SSM Session Manager 用のプラグイン。
- turso-cli: Turso/libSQL のデータベース操作 CLI。

## lsp-store

- nixd: Nix の LSP サーバ。
- marksman: Markdown 向けの LSP サーバ。
- lua-language-server: Lua の LSP サーバ。

## home-manager (platform)

- zsh: シェル本体（Ubuntu/Fedora）。
- oh-my-zsh: zsh のフレームワーク（Ubuntu/Fedora）。
- zsh-autosuggestions: zsh のコマンド補完提案（Ubuntu/Fedora）。
- zsh-syntax-highlighting: zsh のシンタックスハイライト（Ubuntu/Fedora）。
- fcitx5: 入力メソッドフレームワーク（Ubuntu/Fedora）。
- fcitx5-mozc: Mozc エンジン（Ubuntu/Fedora）。
- fcitx5-gtk: GTK アプリ連携（Ubuntu/Fedora）。
- kdePackages.fcitx5-qt: Qt アプリ連携（Ubuntu/Fedora）。
- hackgen-nf-font: 日本語を含む HackGen Nerd Font（Ubuntu/Fedora）。
- obsidian: Markdown ベースのノートアプリ（Ubuntu/Fedora）。
- google-chrome: Web ブラウザ（Ubuntu/Fedora。Fedora では nixGL NVIDIA wrapper を適用）。
- ticktick: タスク管理アプリ（Ubuntu/Fedora）。
- bitwarden-desktop: パスワードマネージャー（Ubuntu/Fedora）。
- openwhispr: ローカルまたはクラウドの音声認識を利用できる音声入力アプリ（Ubuntu/Fedora、x86_64 Linux。Fedora では nixGL NVIDIA wrapper を適用。両環境で Wayland の自動貼り付け用 `ydotoold` user service と、`Super+Shift+K` から D-Bus 経由で起動する GNOME グローバルショートカットを有効化）。
- ghostty: GPU アクセラレーション対応のターミナルエミュレーター（Ubuntu/Fedora、`programs.ghostty.enable` で有効化。Fedora では nixGL NVIDIA wrapper を適用し、`flake.nix` のNVIDIAドライバー版をホスト側と一致させる）。
- zed-editor: GPU アクセラレーション対応のコードエディタ（Ubuntu/Fedora、`programs.zed-editor.enable` で有効化。Fedora では nixGL NVIDIA GL/Vulkan wrapper、Ubuntu では Nix 側 Mesa の Vulkan ICD 明示 wrapper を適用）。
- gnomeExtensions.kimpanel: GNOME Shell の入力メソッド候補ウィンドウ拡張（Ubuntu/Fedora）。

`ydotoold` を使うには、ホスト側で `/dev/uinput` への書き込み権限が必要です。Home Manager 単体では udev rule を変更できないため、Fedora では次の手順で、現在アクティブなグラフィカルセッションのユーザーだけに読み書き ACL を付けます。

```bash
cd /home/torohash/nix-config
sudo install -D -o root -g root -m 0644 \
  host/fedora/udev/72-openwhispr-uinput.rules \
  /etc/udev/rules.d/72-openwhispr-uinput.rules
sudo udevadm verify /etc/udev/rules.d/72-openwhispr-uinput.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --action=change --settle /sys/class/misc/uinput
```

`uaccess` は systemd-logind が現在アクティブなローカル seat ユーザーへ ACL を付け、セッションが非アクティブになったときに回収します。udev rule の基礎権限は `root:root` の `0600` で、グループや全ユーザーには開放しません。ACL 付与中は ACL マスクが `stat` のグループビットへ反映されるため、数値モードが `660` と表示されることがあります。適用後は次の結果を確認し、`ydotoold` を再起動します。

```bash
stat -c '%U:%G %a %n' /dev/uinput
getfacl -p /dev/uinput
test -r /dev/uinput && test -w /dev/uinput
systemctl --user restart ydotoold.service
systemctl --user is-active ydotoold.service
journalctl --user -u ydotoold.service -n 20 --no-pager
```

所有者とグループが `root:root`、`getfacl` で現在のユーザーが `rw-`、`group::---` と `other::---`、`is-active` が `active` なら適用済みです。ルールは `/etc/udev/rules.d` に置かれるため、再起動後も同じ条件で適用されます。

OpenWhispr のクラウド音声認識は BYOK（自分の API キー）を利用する。API キーは Nix の評価結果や Nix store に含めず、OpenWhispr の設定画面から登録する。通常の日本語音声入力は OpenAI の `GPT-4o Mini Transcribe` を既定とし、ローカルモデルへのフォールバックは無効にする。プロバイダー、モデル、言語などの可変設定もアプリ側で管理する。
