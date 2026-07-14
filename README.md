# nix-config

この flake は、共通ツール用のパッケージ、Home Manager 設定、そして `mise` を使った軽量な開発環境導線を提供します。

## 概要

このリポジトリは、Nix flake と Home Manager を使い、Ubuntu、Fedora、WSL で利用する開発ツールとユーザー設定を宣言的に一元管理するための個人用環境構成です。共通 CLI と LSP、シェル、Git、エディタ、端末ツール、プラットフォーム固有の GUI・日本語入力設定、Claude Code・Codex・OpenCode のユーザー共通設定を管理します。

日常的な言語ランタイムとプロジェクト単位のツールチェーンには `mise` を優先し、Nix の devShell は GUI アプリ、SDK、一時的な開発環境の補助手段として使用します。AI 開発支援 CLI 本体は Nix で固定せず、公式インストーラーまたは npm で導入します。

## ドキュメント

- `docs/packages.md`: packages の内容と各ツールの説明。
- `docs/mise.md`: mise の導入方針と基本操作。
- `docs/devShells.md`: devShells の内容と各ツールの説明。
- `docs/home-manager-versioning.md`: Home Manager のバージョン更新と `home.stateVersion` の扱い。
- `docs/home-manager-structure.md`: Home Manager のディレクトリ構成方針。
- `docs/ai-cli.md`: AI 開発支援 CLI ツールの導入方針とインストール。
- `docs/claude-code-config.md`: Claude Code の設定階層、配置場所、適用優先順位。
- `docs/aws-cli.md`: AWS CLI と SSM Session Manager の利用方法。
- `docs/iam-identity-center-sso.md`: IAM Identity Center（SSO）ユーザー発行手順。
- `docs/obsidian.md`: Obsidian 再構築手順と運用方針。
- `docs/neovim.md`: Neovim のキーマップとカスタム操作。
- `docs/yazi.md`: Yazi のキー操作。
- `docs/dotfiles.md`: Bash aliases と tmux キーバインド。
- `docs/gnome-fcitx5.md`: GNOME と fcitx5 の入力切替の関係。
- `docs/gnome-shortcuts.md`: GNOME のスクリーンショット系ショートカットと関連設定のメモ。

## セットアップ

以下の手順を上から順に実行してください。

### 1. Nix のインストール

Nix（2.4+）をインストールします。

詳細: https://nixos.org/download/

インストールコマンド例:

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
```

インストール後に Nix の環境変数を反映します。

```bash
source ~/.nix-profile/etc/profile.d/nix.sh
```

### 2. flakes の有効化

flakes を有効化します。

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

※ 複数回実行すると設定が重複するため、ファイルの内容を確認してください。既に `experimental-features = nix-command flakes` がある場合は置き換えてください。

### 3. Nix registry への登録

本リポジトリを `nix registry` に登録します。

```bash
nix registry add nixcfg path:/home/torohash/nix-config
```

`/home/torohash/nix-config` は環境に合わせて置き換えてください。

既に `nixcfg` が登録されている場合は、`nix registry remove nixcfg` を実行してから追加してください。

以降のコマンド例は `nixcfg` の登録を前提にしています。

### 4. ユーザーの作成（root 環境の場合）

初期セットアップで root でログインしており、通常ユーザーが存在しない場合は Home Manager 設定用のユーザーを作成する必要があります。

ユーザー作成コマンド例（汎用 Linux）:

```bash
sudo useradd -m -s /bin/bash alice
sudo usermod -aG sudo alice
```

`sudo` グループが存在しない環境では `wheel` 等に読み替えてください。`alice` は実際のユーザー名に置き換えてください。Home Manager の適用は作成したユーザーでログインして行います。

### 5. Home Manager の設定ファイルの編集

`nix/home/users/torohash.nix` を環境に合わせて変更してください：

- `username`: ユーザー名（初期値: `torohash`）
- `homeDirectory`: ホームディレクトリ（初期値: `/home/torohash`）
- `stateVersion`: 初回インストール時の Home Manager バージョン

現在の構成は、ユーザー名 `torohash`、ホームディレクトリ `/home/torohash`、システム `x86_64-linux` を前提としています。別の環境へ移植する場合は、上記のユーザー設定に加え、`flake.nix` の `homeUsername` / `homeSystem`、`nix/home/hosts/` のホストモジュール名、dotfiles 内のユーザー名と絶対パスも合わせて変更してください。

`nix/home/common/git.nix` の Git 設定も環境に合わせて変更してください：

- `programs.git.settings.user.name`: Git のユーザー名
- `programs.git.settings.user.email`: Git のメールアドレス

### 6. Home Manager の適用

初回と2回目以降で実行するコマンドが異なります。

このリポジトリの Home Manager 設定は、主に以下を管理します：

- `common-store` と `lsp-store` に含まれる共通 CLI・LSP
- bash / zsh、`mise`、direnv / nix-direnv、Git
- Neovim、Zed、tmux、Yazi、lazygit などのユーザー設定
- Claude Code の settings・rules・skills・commands・agents・hooks
- Codex のグローバル個人指示・rules・skills・委譲用 agents
- OpenCode の設定・グローバル指示・skills
- Ubuntu / Fedora 固有の GUI アプリ、fcitx5、日本語フォント、GNOME 設定

一方、AI 開発支援 CLI 本体、認証情報・会話履歴などの実行時状態、`~/.codex/config.toml`、`~/.claude/statusline-command.sh` は管理しません。必要に応じて各環境で別途導入・設定してください。

Codex の委譲用 agent は、各TOMLの`name`を実行時の`agent_role`として選択できるネイティブなサブエージェント起動経路を前提とします。モデルと推論レベルは各TOMLの`model`と`model_reasoning_effort`から適用されます。`agent_role`を指定できない汎用起動経路ではカスタムagentを利用できないため、依頼文だけで役割やモデルを指定して代替しないでください。

多くの設定ファイルは Home Manager の管理対象として強制配置されるため、既存の同名ファイルは `home-manager switch` 時に置き換えられます。初回適用前に、現在の `~/.claude`、`~/.codex`、`~/.config/opencode` などを確認し、必要な設定をバックアップするか、本リポジトリへ取り込んでください。

Home Manager の案内: https://nix-community.github.io/home-manager/

#### 初回

このリポジトリでは Home Manager を `nix profile` でインストールせず、
`nix run` で Home Manager を実行する方法を推奨します（プロファイル衝突の回避）。

根拠:
- https://nix-community.github.io/home-manager/#ch-nix-flakes
- https://github.com/nix-community/home-manager/issues/2848
- https://stackoverflow.com/questions/78047885/nix-profile-install-always-results-in-conflict-with-home-manager

初回は以下のコマンドを実行してください：

```bash
nix run github:nix-community/home-manager -- switch --flake nixcfg#<host>
```

`<host>` は `<username>_<platform>` という命名になっています（例: `torohash_fedora`）。
`platform` 単体（例: `fedora`）ではないので注意してください。指定できる値は
`torohash_ubuntu` / `torohash_fedora` / `torohash_wsl` です。

```bash
# 例: Fedora の場合
nix run github:nix-community/home-manager -- switch --flake nixcfg#torohash_fedora
```

初回の適用が完了すると、`programs.home-manager.enable = true` の設定により
`home-manager` コマンドが使用可能になります。

必要に応じて新しいシェルを開くか、`source ~/.profile` を実行してください。
`home-manager` が見つからない場合は、初回と同じ `nix run github:nix-community/home-manager -- switch --flake nixcfg#<host>` を使用できます。

#### 2回目以降

2回目以降は以下のコマンドを使用してください：

```bash
home-manager switch --flake nixcfg#<host>
```

### zsh をデフォルトシェルにする（Ubuntu/Fedora）

`torohash_ubuntu` と `torohash_fedora` では Home Manager で `zsh` を有効化しています。

#### Nix で可能なこと / 不可能なこと

- 可能: `zsh` の導入。
- 不可能（Fedora/Ubuntu + Home Manager 単体）: `/etc/shells` や `/etc/passwd` を完全に宣言的に固定すること。
- 不可能（この設定）: `home-manager switch` 実行時に `/etc/shells` 登録や `chsh` を自動実行すること。

#### 切り替え手順（1回だけ実施）

`home-manager switch` は `/etc/shells` とログインシェルを変更しないため、
以下を手動で実行してください（そのままコピペ可）。

```bash
ZSH_PATH="$HOME/.nix-profile/bin/zsh"
grep -Fxq "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
chsh -s "$ZSH_PATH"
getent passwd "$USER" | cut -d: -f7 || awk -F: -v u="$USER" '$1==u {print $7}' /etc/passwd
```

`sudo` が必要なのは `/etc/shells` 追記の行だけです。`chsh` は通常 sudo 不要です。
確認結果が `.../zsh` になっていればOKです。反映には再ログインが必要です。

Neovim のアイコン表示には Nerd Font が必要です。

## 基本的な使い方

### パッケージのビルド

packages の一覧と内容は `docs/packages.md` を参照してください。

#### common-store

```bash
nix build nixcfg#common-store
```

### 軽量な開発環境セットアップ（mise）

基本操作:

```bash
mise --version
mise doctor
mise use --global node@22
mise use --global python@3.12
```

プロジェクトごとに `mise.toml` を置いている場合は、そのディレクトリで以下を実行してください。

```bash
mise install
mise ls --current
```

### 開発シェル（nix develop）

devShell は GUI アプリや SDK をまとめて扱いたい場合の補助手段として残しています。一覧と内容は `docs/devShells.md` を参照してください。

```bash
nix develop nixcfg#python
```

または、デフォルトの devShell を使用する場合：

```bash
nix develop nixcfg
```

### devShell の自動適用（必要な場合のみ）

`nix develop` を自動適用したい場合は、リポジトリのルートに `.envrc` を作成し、以下を記載します。

```bash
use flake "nixcfg"
```

特定の devShell を使いたい場合は、名前を指定してください。

```bash
use flake "nixcfg#python"
```

初回のみ許可します。

```bash
direnv allow
```

これで、このディレクトリに移動すると自動的に devShell が有効化されます。

### flake.lock の更新

```bash
nix flake update
```

## AI ツールの追加

AI 開発支援 CLI ツールの導入方針とインストール手順は `docs/ai-cli.md` を参照してください。

## システム対応

packages と devShells は `nixpkgs.lib.systems.flakeExposed` で定義されたシステム向けに生成します。Home Manager 構成は現在 `x86_64-linux` の Ubuntu、Fedora、WSL 向けです。

注: store の profile install は Home Manager と競合するため実施非推奨です。
