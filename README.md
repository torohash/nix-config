# nix-config

この flake は、共通ツール用のパッケージと Python 向けの開発シェルを提供します。

## 概要

このリポジトリは packages と devShells を提供します。

## ドキュメント

- `docs/packages.md`: packages の内容と各ツールの説明。
- `docs/devShells.md`: devShells の内容と各ツールの説明。
- `docs/home-manager-versioning.md`: Home Manager のバージョン更新と `home.stateVersion` の扱い。

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

#### Home Manager のインストールと適用

Home Manager の案内: https://nix-community.github.io/home-manager/

Home Manager のインストールコマンド例:

```bash
nix profile install nixpkgs#home-manager
home-manager switch --flake .#<username>
```

`<username>` は `nix/home/config.nix` の `username` に合わせてください。

### devShell の自動適用

リポジトリのルートに `.envrc` を作成し、以下を記載します。

```bash
use flake
```

初回のみ許可します。

```bash
direnv allow
```

これで、このディレクトリに移動すると自動的に devShell が有効化されます。

## 基本的な使い方

### パッケージのビルド

#### common-store

```bash
nix build .#common-store
```

### プロファイルへのインストール

ユーザープロファイルにインストールしてコマンドを永続的に利用するには:

#### common-store

```bash
nix profile install .#common-store
```

インストール後はシェルを再起動してください。反映されない場合は `~/.nix-profile/bin` が PATH に含まれているか確認してください。

### 開発シェル（nix develop）

Python 向けの開発シェルを提供しています。

```bash
nix develop .#python
```

```bash
nix develop
```

### flake.lock の更新

```bash
nix flake update
```

## システム対応

この flake は `nixpkgs.lib.systems.flakeExposed` で定義されたシステムをサポートしています。
