# Home Manager 構成方針（multi-host）

## 目的

- ホストごとの差分を明確に分離する
- `common` と `platforms/<platform>` を同じ構成で並べる
- `hosts` は合成だけのエントリポイントにする

## ディレクトリ構成（例）

```
nix/home/
  common/
    modules.nix
    shell/
      bash.nix
    editor/
      neovim.nix
    git.nix
    dotfiles.nix

  platforms/
    ubuntu/
      modules.nix
      shell/
        bash.nix
      editor/
        neovim.nix
      dotfiles.nix
    fedora/
      modules.nix
      shell/
        bash.nix
      editor/
        neovim.nix
      dotfiles.nix
    wsl/
      modules.nix
      shell/
        bash.nix
      editor/
        neovim.nix
      dotfiles.nix

  users/
    torohash.nix

  hosts/
    torohash_ubuntu.nix
    torohash_fedora.nix
    torohash_wsl.nix
```

## 役割

- `common/`: 全ホスト共通の設定
- `platforms/<platform>/`: プラットフォーム固有の差分のみ
- `users/`: ユーザー固定の設定（username, homeDirectory など）
- `hosts/`: `common + platform + user` を合成するエントリポイント

## modules.nix の役割

`modules.nix` はそのディレクトリ配下のモジュールを集約する明示的な入口。
`default.nix` は使わず、必ず `modules.nix` を指定する。

```nix
# nix/home/common/modules.nix
{ ... }:
{
  imports = [
    ./shell/bash.nix
    ./editor/neovim.nix
    ./git.nix
    ./dotfiles.nix
  ];
}
```

```nix
# nix/home/platforms/ubuntu/modules.nix
{ ... }:
{
  imports = [
    ./shell/bash.nix
    ./editor/neovim.nix
    ./dotfiles.nix
  ];
}
```

## hosts のエントリポイント例

```nix
# nix/home/hosts/torohash_ubuntu.nix
{ ... }:
{
  imports = [
    ../users/torohash.nix
    ../common/modules.nix
    ../platforms/ubuntu/modules.nix
  ];
}
```

## 運用ルール

- OSに依存しないものは `common/` に置く
- プラットフォーム固有の差分だけを `platforms/<platform>/` に置く
- 差分がない機能は `platforms/<platform>/` にファイルを作らず、`modules.nix` にも追加しない

## 追加方法

### 新しいプラットフォームの追加

- `platforms/<platform>/modules.nix` を作成
- 差分が必要なモジュールだけ追加

### 新しいホストの追加

- `hosts/torohash_<host>.nix` を作成
- `common + platform + user` を import

## 実行コマンドの形式例

```bash
# 初回
nix run github:nix-community/home-manager -- switch --flake nixcfg#torohash_ubuntu

# 2回目以降
home-manager switch --flake nixcfg#torohash_ubuntu
```
