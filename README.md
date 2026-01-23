# nix-config

この flake は、共通ツール用のパッケージと Python 向けの開発シェルを提供します。

## 概要

このリポジトリは packages と devShells を提供します。

## ドキュメント

- `docs/packages.md`: packages の内容と各ツールの説明。
- `docs/devShells.md`: devShells の内容と各ツールの説明。
- `docs/home-manager-versioning.md`: Home Manager のバージョン更新と `home.stateVersion` の扱い。
- `docs/ai-cli.md`: AI 開発支援 CLI ツールの導入方針とインストール。

## セットアップ

### 前提条件

Nix（2.4+）をインストールし、flakes を有効化してください。

#### Nix のインストール

https://nixos.org/download/ に従って Nix をインストールします。

インストールコマンド例:

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
```

#### flakes の有効化

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

※ 複数回実行すると設定が重複するため、ファイルの内容を確認してください。

### Home Manager の設定

このリポジトリには Home Manager 設定が含まれています。Home Manager は以下を管理します：

- `.bashrc`（bash と direnv/nix-direnv 用の設定を含む）
- direnv / nix-direnv の設定と有効化
- Git 設定（プロンプトのブランチ表示と userName/userEmail）

#### 設定ファイルの編集

`nix/home/config.nix` を環境に合わせて変更してください：

- `username`: ユーザー名（初期値: `torohash`）
- `homeDirectory`: ホームディレクトリ（初期値: `/home/torohash`）
- `system`: システムタイプ（WSL の場合は `x86_64-linux`）

`nix/home/common.nix` の Git 設定も環境に合わせて変更してください：

- `programs.git.userName`: Git のユーザー名
- `programs.git.userEmail`: Git のメールアドレス

#### Home Manager の適用

Home Manager の案内: https://nix-community.github.io/home-manager/

このリポジトリでは `nix profile install nixpkgs#home-manager` は使わず、
`nix run` で Home Manager を実行する方法を推奨します（プロファイル衝突の回避）。

根拠:
- https://nix-community.github.io/home-manager/#ch-nix-flakes
- https://github.com/nix-community/home-manager/issues/2848
- https://stackoverflow.com/questions/78047885/nix-profile-install-always-results-in-conflict-with-home-manager

```bash
nix run github:nix-community/home-manager -- switch --flake .#<username>
```

`<username>` は `nix/home/config.nix` の `username` に合わせてください。

## 基本的な使い方

### パッケージのビルド

packages の一覧と内容は `docs/packages.md` を参照してください。

#### common-store

```bash
nix build .#common-store
```

### 開発シェル（nix develop）

Python 向けの開発シェルを提供しています。

devShells の一覧と内容は `docs/devShells.md` を参照してください。

```bash
nix develop .#python
```

```bash
nix develop
```

### devShell の自動適用

リポジトリのルートに `.envrc` を作成し、以下を記載します。

```bash
use flake
```

特定の devShell を使いたい場合は、名前を指定してください。

```bash
use flake .#python
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
