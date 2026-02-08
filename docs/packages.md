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
- vim: 軽量で拡張性の高いテキストエディタ。
- terraform: Terraform CLI。
- terraform-ls: Terraform の LSP サーバ。
- awscli2: AWS CLI v2。
- ssm-session-manager-plugin: AWS SSM Session Manager 用のプラグイン。

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
- google-chrome: Web ブラウザ（Ubuntu/Fedora）。
- ticktick: タスク管理アプリ（Ubuntu/Fedora）。
- bitwarden-desktop: パスワードマネージャー（Ubuntu/Fedora）。
- ghostty: GPU アクセラレーション対応のターミナルエミュレーター（Ubuntu/Fedora、`programs.ghostty.enable` で有効化）。
- zed-editor: GPU アクセラレーション対応のコードエディタ（Ubuntu/Fedora、`programs.zed-editor.enable` で有効化。起動時に Nix 側 Mesa の Vulkan ICD を `VK_ICD_FILENAMES` / `VK_DRIVER_FILES` へ明示するラッパーを適用）。
- gnomeExtensions.kimpanel: GNOME Shell の入力メソッド候補ウィンドウ拡張（Ubuntu/Fedora）。
