---
description: Bootstrap a bare Python project (uv + Ruff + Pyright + pytest) fully automatically
---

# /uv-init — Python プロジェクト初期セットアップ

Python プロジェクトの土台を **全自動** で構築する。ランタイム/依存は **uv をそのまま** 使う
（mise は使わない）。Ruff = linter + formatter、Pyright = 型チェック、pytest = テスト。

確認は求めず、各ステップを順に実行し、最後にまとめだけ報告する。
（破壊的操作=既存 `pyproject.toml` 等が既にある場合のみ、上書き前に一度だけ確認する）

> 前提: `uv` は PATH 上にあり、直接 `uv ...` / `uv run ...` で実行できる。
> 依存とツールは `uv add` で入れ、`uv run <tool>` でプロジェクトの venv 内で実行する。

## 実行手順（上から順に Bash で実行）

1. **uv プロジェクト初期化**（`pyproject.toml` が無い場合のみ）
   ```bash
   uv init
   ```

2. **開発依存の追加**（Ruff + Pyright + pytest）
   ```bash
   uv add --dev ruff pyright pytest
   ```

3. **`pyproject.toml` にツール設定を追記**（`.toml` なので Claude が直接編集可）
   ```toml
   [tool.ruff]
   line-length = 100

   [tool.pyright]
   typeCheckingMode = "standard"

   [tool.pytest.ini_options]
   pythonpath = ["."]
   testpaths = ["tests"]
   ```

4. **サンプルとテストの雛形**（Bash の heredoc で scaffold する。Edit/Write は使わない）
   ```bash
   mkdir -p tests
   [ -f example.py ] || cat > example.py <<'EOF'
   def add(a: int, b: int) -> int:
       return a + b
   EOF
   cat > tests/test_example.py <<'EOF'
   from example import add


   def test_add() -> None:
       assert add(1, 2) == 3
   EOF
   ```

5. **強制チェック hook をプロジェクトに紐づけ**
   - `./.claude/settings.json` に Stop hook をマージする（無ければ新規作成、既存なら hooks のみ追記）:
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash /home/torohash/.claude/hooks/verify-ruff-pyright.sh"
             }
           ]
         }
       ]
     }
   }
   ```
   - これにより、以降このプロジェクトでは **ターン終了時に Ruff(lint+format) + Pyright + pytest が走り、warning/error/失敗が消えるまで修正ループが強制** される（修正は Codex へ委譲）。
   - **`.claude/HOOKS.md` に hook の挙動メモを書く**（自動読込されない plain text。agent が hook 挙動に迷ったとき読む用。Bash heredoc）:
   ```bash
   cat > .claude/HOOKS.md <<'EOF'
   # このプロジェクトの Stop hooks（自動読込なし・必要時に読む用メモ）

   - ターン終了時に `.claude/settings.json` の Stop hook が走る。
   - **verify hook（ruff / pyright / pytest）は成功時は完全に無音（exit 0、出力なし）。出力・ブロックするのは失敗時だけ。**
     → **無音＝「走って合格」であり「未発火」ではない**。silence を未発火と誤判定しないこと。
   - コード増分 review は Stop hook ではなく、グローバル rules の notify-driven async `review-auditor` で行う。verify hook の出力と混同しないこと。
   - hooks はセッション開始時にスナップショットされる。途中で追加した hook は新セッション（`claude` 再起動）か `/hooks` 承認まで無効。`claude -c` 再開時は再スナップショットされ有効。
   EOF
   ```

6. **整形 → 初回検証**（雛形は Ruff 既定整形と差があるので、先に format/fix してから検証する）
   ```bash
   uv run ruff format .
   uv run ruff check --fix .
   uv run ruff check .
   uv run pyright
   uv run pytest
   ```

## 完了報告に含めるもの
- 採用した Python のバージョン（`.python-version` / `pyproject.toml`）
- 生成/更新したファイル一覧
- `ruff / pyright / pytest` の結果
- **注意（必ず報告）**: ここで設定した強制チェック Stop hook は **このセッションでは効かない**。Claude Code は起動時に hook をスナップショットするため、起動後に追加した hook は取り込まれない。有効化するには、このプロジェクトを **新しいセッションで開く**（または `/hooks` で承認 / 再起動）必要がある。
- 次の一手（フレームワークが必要なら専用コマンドを後日。それまでは素の Python）
