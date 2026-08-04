# packages

## common-store

- htop: 端末で動作するプロセスビューア。
- btop: CPU/メモリ/ディスク/ネットワークを見やすく表示するリソースモニタ。
- cloc: 言語別のコード行数を集計するツール。
- tmux: 端末セッションを分割・管理するためのマルチプレクサ。
- zellij: Rust 製の端末マルチプレクサ。
- git: 分散バージョン管理システム。
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
- openwhispr: ローカルまたはクラウドの音声認識を利用できる音声入力アプリ（Ubuntu/Fedora、x86_64 Linux。Fedora では nixGL NVIDIA wrapper を適用し、両環境で Wayland の自動貼り付け用 `ydotoold` user service を有効化）。
- ghostty: GPU アクセラレーション対応のターミナルエミュレーター（Ubuntu/Fedora、`programs.ghostty.enable` で有効化。Fedora では nixGL NVIDIA wrapper を適用）。
- zed-editor: GPU アクセラレーション対応のコードエディタ（Ubuntu/Fedora、`programs.zed-editor.enable` で有効化。Fedora では nixGL NVIDIA GL/Vulkan wrapper、Ubuntu では Nix 側 Mesa の Vulkan ICD 明示 wrapper を適用）。
- gnomeExtensions.kimpanel: GNOME Shell の入力メソッド候補ウィンドウ拡張（Ubuntu/Fedora）。

`ydotoold` を使うには、ホスト側で `/dev/uinput` への書き込み権限が必要です。Home Manager 単体では udev rule やユーザーのグループ所属を変更できないため、権限がない環境ではホスト側で設定してください。
