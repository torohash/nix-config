# mise

このリポジトリでは、日常的な言語ランタイムやプロジェクト単位のツールチェーン管理に `mise` を優先します。

devShell は GUI アプリや SDK をまとめて扱いたい場合、あるいは `nix develop` ベースの一時環境が必要な場合の補助導線として使います。

## 基本方針

- Node.js や Python など、プロジェクトごとにバージョンを切り替えるランタイムは `mise` で管理する。
- Nix の packages/devShells は、共通ツールの配布や Nix でまとめて扱いたい環境に限定する。
- プロジェクトごとの設定は、各プロジェクトの `mise.toml` を優先する。

## 初期確認

`common-store` または Home Manager で `mise` を導入したあと、以下を確認します。

```bash
mise --version
mise doctor
```

## グローバルランタイムの例

よく使うランタイムは必要に応じてグローバルに設定します。

```bash
mise use --global node@22
mise use --global python@3.12
```

## プロジェクト単位の利用

プロジェクトに `mise.toml` がある場合は、そのディレクトリでインストールと確認を行います。

```bash
mise install
mise ls --current
```

新しいプロジェクトでランタイムを固定する場合は、対象ディレクトリで `mise use` を実行して `mise.toml` を作成します。

```bash
mise use node@22
mise use python@3.12
```

## devShell との使い分け

- 通常のアプリケーション開発: `mise`
- GUI アプリや SDK を含む一時環境: `nix develop nixcfg#<devShell>`
- 共通 CLI ツールのまとめ配布: `nix build nixcfg#common-store`

利用可能な devShell の一覧は `docs/devShells.md` を参照してください。
