# nix-config

この flake は、共通ツール用のパッケージと Python 向けの開発シェルを提供します。

## 概要

このリポジトリは packages と devShells を提供します。

## ドキュメント

- `docs/packages.md`: packages の内容と各ツールの説明。
- `docs/devShells.md`: devShells の内容と各ツールの説明。

## 前提条件

- Nix（2.4+ かつ `experimental-features = nix-command flakes` を有効化）をインストールすること: https://nixos.org/download/
- direnv をインストールすること: https://direnv.net/
- nix-direnv をインストールすること: https://github.com/nix-community/nix-direnv

### experimental-features の有効化

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### インストール例（Nix）

```bash
nix profile install nixpkgs#direnv nixpkgs#nix-direnv
```

### direnv の有効化

使用しているシェルにフックを追加してください。

```bash
eval "$(direnv hook bash)"
```

```bash
eval "$(direnv hook zsh)"
```

### nix-direnv の有効化

`~/.config/direnv/direnvrc`（または `~/.direnvrc`）に以下を追加してください。

```bash
source "$HOME/.nix-profile/share/nix-direnv/direnvrc"
```

### devShell の自動適用（direnv）

リポジトリのルートに `.envrc` を作成し、以下を記載します。

```bash
use flake
```

初回のみ許可します。

```bash
direnv allow
```

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
