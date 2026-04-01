# devShells

通常の開発環境セットアップは `mise` を推奨します。導入と基本操作は `docs/mise.md` を参照してください。

このページの devShell は、GUI アプリや SDK をまとめて扱いたい場合、あるいは `nix develop` ベースの一時環境が必要な場合の補助導線です。

## python

- python312: Python 3.12 実行環境。
- uv: 高速な Python パッケージマネージャー。
- ruff: Python の高速な Linter/Formatter。
- basedpyright: Pyright の拡張版 LSP サーバ。

## jupyterlab

- python312: Python 3.12 実行環境。
- uv: 高速な Python パッケージマネージャー。
- ruff: Python の高速な Linter/Formatter。
- basedpyright: Pyright の拡張版 LSP サーバ。
- python312Packages.jupyterlab: JupyterLab 実行環境。

## typescript

- nodejs_22: Node.js 22 実行環境。
- typescript: TypeScript コンパイラ。
- vtsls: TypeScript 用 LSP サーバ。
- typescript-language-server: TypeScript 用 LSP サーバ（代替）。
- bun: 高速な JavaScript ランタイムとパッケージマネージャー。
- biome: JavaScript/TypeScript の Linter/Formatter。

## godot

- godot_4: Godot 4 エディタ本体（GDScript 開発向け最小構成）。
- godot_4-export-templates-bin: Godot 4 のエクスポートテンプレート。
- gdtoolkit_4: GDScript 用の Linter/Formatter（`gdlint`, `gdformat`）。

## flutter

- flutter: Flutter SDK（Dart SDK 同梱）。モバイル・Web・デスクトップアプリ開発環境。

## pencil

- pencil-desktop: Pencil Desktop (AppImage) を起動するための最小構成。
