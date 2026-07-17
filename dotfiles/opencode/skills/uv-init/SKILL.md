---
name: uv-init
description: "uv、Ruff、Pyright、pytest、project AGENTS.mdの継続検証指示を備えた素のPythonプロジェクトを初期化または標準化する。ユーザーがuv-initまたは$uv-initを明示した場合、フレームワークを使わないPythonプロジェクトの初期化を依頼した場合、または空のリポジトリへこの構成を導入する場合に使用する。両立可能な既存設定は上書きせず維持する。"
compatibility: opencode
---

# uv Pythonプロジェクトを初期化する

uvで管理した依存、決定的な検査、サンプルテスト、継続検証指示を備えた最小構成を作成する。

## ガードレール

- 変更前に作業ツリーと既存のプロジェクトファイルを確認する。
- 既存の`pyproject.toml`、`.python-version`、ソース、テスト、`AGENTS.md`を上書きしない。
- 無関係な設定と`AGENTS.md`の既存指示を維持し、必要な設定だけを統合する。
- 既存構成と両立せず置換が必要な場合だけ、一度確認する。それ以外は不要な確認を挟まず進める。
- `uv`を直接使用し、プロジェクトのツールを`uv run`経由で実行する。
- アプリケーションフレームワーク、`.codex` hook、project Pluginを導入しない。

## 手順

1. `uv`が利用可能か確認する。存在しない場合は、作業を止めるエラーとして報告する。
2. 変更前に対象プロジェクトのルートにある`AGENTS.md`を確認する。検証指示のmarkerが両方ない、または正しい順序で一組だけある場合は続行する。片方だけ、同じmarkerが複数、または終了markerが開始markerより前にある場合は、プロジェクトを変更せず異常を報告する。ファイルがなければ続行する。
3. `pyproject.toml`が存在しない場合だけ初期化する。

   ```bash
   uv init
   ```

4. 開発依存を追加する。

   ```bash
   uv add --dev ruff pyright pytest
   ```

5. 次の設定を`pyproject.toml`へ統合する。

   ```toml
   [tool.ruff]
   line-length = 100

   [tool.pyright]
   typeCheckingMode = "standard"

   [tool.pytest.ini_options]
   pythonpath = ["."]
   testpaths = ["tests"]
   markers = ["small: 単一プロセスで完結する高速なテスト"]
   ```

6. 新規または空のプロジェクトでは、未作成の場合だけ`example.py`と`tests/test_example.py`を作成する。

   ```python
   def add(a: int, b: int) -> int:
       return a + b
   ```

   ```python
   import pytest

   from example import add

   pytestmark = pytest.mark.small


   def test_add() -> None:
       assert add(1, 2) == 3
   ```

7. 事前検査済みの`AGENTS.md`へ、次の範囲を一度だけ追加する。ファイルがなければ作成する。markerが両方なければ末尾へ追記し、正しい順序のmarkerが一組だけあれば範囲内だけを更新する。marker外の内容は維持する。

   ```markdown
   <!-- uv-init:verification:start -->
   ## uv／Pythonの継続検証

   Pythonのコード、テスト、`.python-version`、`pyproject.toml`、`uv.lock`、Ruff、Pyright、pytestの設定を変更した場合だけ、完了前に次を順番に実行する。

   1. `uv run ruff format .`
   2. `uv run ruff check --fix .`
   3. `uv run ruff check .`
   4. `uv run pyright`
   5. `uv run pytest`

   いずれかが失敗した場合は原因を修正し、5つすべてが成功するまで同じ順序で再実行する。対象コードや設定を変更していない場合は実行しない。
   <!-- uv-init:verification:end -->
   ```

8. 整形と検証を実行する。

   ```bash
   uv run ruff format .
   uv run ruff check --fix .
   uv run ruff check .
   uv run pyright
   uv run pytest
   ```

## 完了報告

次を報告する。

- `.python-version`または`pyproject.toml`に記録したPythonのバージョン
- 作成または更新したファイル
- `AGENTS.md`へ追加または更新した検証指示
- Ruff、Pyright、pytestの結果
