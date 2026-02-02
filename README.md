# nix-config

この flake は、共通ツール用のパッケージと Python 向けの開発シェルを提供します。

## 概要

このリポジトリは packages と devShells を提供します。

## ドキュメント

- `docs/packages.md`: packages の内容と各ツールの説明。
- `docs/devShells.md`: devShells の内容と各ツールの説明。
- `docs/home-manager-versioning.md`: Home Manager のバージョン更新と `home.stateVersion` の扱い。
- `docs/home-manager-structure.md`: Home Manager のディレクトリ構成方針。
- `docs/ai-cli.md`: AI 開発支援 CLI ツールの導入方針とインストール。
- `docs/aws-cli.md`: AWS CLI と SSM Session Manager の利用方法。
- `docs/iam-identity-center-sso.md`: IAM Identity Center（SSO）ユーザー発行手順。
- `docs/neovim.md`: Neovim のキーマップとカスタム操作。
- `docs/yazi.md`: Yazi のキー操作。
- `docs/dotfiles.md`: Bash aliases と tmux キーバインド。

## セットアップ

以下の手順を上から順に実行してください。

### 1. Nix のインストール

Nix（2.4+）をインストールします。

詳細: https://nixos.org/download/

インストールコマンド例:

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
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

システムタイプは `flake.nix` の `homeSystem` で指定します。

`nix/home/common/git.nix` の Git 設定も環境に合わせて変更してください：

- `programs.git.settings.user.name`: Git のユーザー名
- `programs.git.settings.user.email`: Git のメールアドレス

### 6. Home Manager の適用

初回と2回目以降で実行するコマンドが異なります。

このリポジトリには Home Manager 設定が含まれています。Home Manager は以下を管理します：

- `.bashrc`（bash と direnv/nix-direnv 用の設定を含む）
- direnv / nix-direnv の設定と有効化
- Git 設定（プロンプトのブランチ表示と userName/userEmail）

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

`<host>` には `torohash_ubuntu` または `torohash_wsl` を指定してください。

初回の適用が完了すると、`programs.home-manager.enable = true` の設定により
`home-manager` コマンドが使用可能になります。

必要に応じて新しいシェルを開くか、`source ~/.profile` を実行してください。
`home-manager` が見つからない場合は、初回と同じ `nix run github:nix-community/home-manager -- switch --flake nixcfg#<host>` を使用できます。

#### 2回目以降

2回目以降は以下のコマンドを使用してください：

```bash
home-manager switch --flake nixcfg#<host>
```

Neovim のアイコン表示には Nerd Font が必要です。

## 基本的な使い方

### パッケージのビルド

packages の一覧と内容は `docs/packages.md` を参照してください。

#### common-store

```bash
nix build nixcfg#common-store
```

### 開発シェル（nix develop）

Python 向けの開発シェルを提供しています。

devShells の一覧と内容は `docs/devShells.md` を参照してください。

```bash
nix develop nixcfg#python
```

または、デフォルトの devShell を使用する場合：

```bash
nix develop nixcfg
```

### devShell の自動適用

リポジトリのルートに `.envrc` を作成し、以下を記載します。

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

この flake は `nixpkgs.lib.systems.flakeExposed` で定義されたシステムをサポートしています。

注: store の profile install は Home Manager と競合するため実施非推奨です。
