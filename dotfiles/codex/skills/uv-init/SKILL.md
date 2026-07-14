---
name: uv-init
description: "uv、Ruff、Pyright、pytest、CodexのStop検証Hookを備えた素のPythonプロジェクトを初期化または標準化する。ユーザーが$uv-initを明示した場合、フレームワークを使わないPythonプロジェクトの初期化を依頼した場合、または空のリポジトリへこの構成を導入する場合に使用する。両立可能な既存設定は上書きせず維持する。"
---

# uv Pythonプロジェクトを初期化する

uvで管理した依存、決定的な検査、サンプルテスト、プロジェクト固有のCodex検証Hookを備えた最小構成を作成する。

## ガードレール

- 変更前に作業ツリーと既存のプロジェクトファイルを確認する。
- 既存の`pyproject.toml`、`.python-version`、ソース、テスト、`.codex/hooks.json`を上書きしない。
- 無関係な設定を維持しながら、必要な設定だけを既存ファイルへ統合する。
- 既存構成と両立せず置換が必要な場合だけ、一度確認する。それ以外は不要な確認を挟まず進める。
- `uv`を直接使用し、プロジェクトのツールを`uv run`経由で実行する。
- アプリケーションフレームワークを導入しない。

## 手順

1. `uv`が利用可能か確認する。存在しない場合は、作業を止めるエラーとして報告する。
2. `pyproject.toml`が存在しない場合だけ初期化する。

   ```bash
   uv init
   ```

3. 開発依存を追加する。

   ```bash
   uv add --dev ruff pyright pytest
   ```

4. 次の設定を`pyproject.toml`へ統合する。

   ```toml
   [tool.ruff]
   line-length = 100

   [tool.pyright]
   typeCheckingMode = "standard"

   [tool.pytest.ini_options]
   pythonpath = ["."]
   testpaths = ["tests"]
   ```

5. 新規または空のプロジェクトでは、未作成の場合だけ`example.py`と`tests/test_example.py`を作成する。

   ```python
   def add(a: int, b: int) -> int:
       return a + b
   ```

   ```python
   from example import add


   def test_add() -> None:
       assert add(1, 2) == 3
   ```

6. `.codex/hooks.json`を作成または統合する。既存Hookをすべて維持し、次の`Stop`ハンドラーを一度だけ追加する。

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash \"$HOME/.agents/skills/uv-init/scripts/verify.sh\"",
               "timeout": 600,
               "statusMessage": "Pythonプロジェクトを検証しています"
             }
           ]
         }
       ]
     }
   }
   ```

7. 整形と検証を実行する。

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
- Ruff、Pyright、pytestの結果
- 新しいプロジェクトHookは`/hooks`で内容を確認して信頼する必要があり、有効化に新しいCodexセッションが必要な場合があること
