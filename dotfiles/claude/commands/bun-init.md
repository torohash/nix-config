---
description: Bootstrap a bare TypeScript project (mise + bun + Biome + tsc + bun test) fully automatically
---

# /bun-init — TypeScript プロジェクト初期セットアップ

node 系プロジェクトの土台を **全自動** で構築する。Next.js / Vite 等のフレームワークは
本コマンドの対象外（フレームワーク用コマンドは後日別途用意）。TypeScript は必須。

確認は求めず、各ステップを順に実行し、最後にまとめだけ報告する。
（破壊的操作=既存 `package.json` 等が既にある場合のみ、上書き前に一度だけ確認する）

> 重要: bun は mise のローカルツール（プロジェクトの `mise.toml` でピン留め）。
> 非対話シェルでは `bun` が PATH に無いため、**必ず `mise exec -- bun ...` / `mise exec -- bunx ...`** で実行する。

## 実行手順（上から順に Bash で実行）

1. **bun を mise で導入・固定**
   ```bash
   mise use bun@latest
   mise install
   ```

2. **TypeScript プロジェクト初期化**（`package.json` が無い場合のみ）
   ```bash
   mise exec -- bun init -y
   ```

3. **依存追加**（型チェッカ + Biome）
   ```bash
   mise exec -- bun add -d typescript @types/bun @biomejs/biome
   ```

4. **Biome 初期化**（lint + formatter）
   ```bash
   mise exec -- bunx biome init
   ```

5. **`tsconfig.json` を strict + noEmit 前提に調整**（`.json` なので Claude が直接編集可）
   - `"strict": true`, `"noEmit": true`, `"skipLibCheck": true`, `"moduleResolution": "bundler"` を確認/設定。
   - `bun init` 既定の tsconfig は概ね満たすので、欠けている項目だけ補う。

6. **`package.json` に scripts を追加**（`.json` なので Claude が直接編集可。`jq` でマージする）
   ```json
   {
     "scripts": {
       "typecheck": "tsc --noEmit",
       "lint": "biome check --error-on-warnings .",
       "format": "biome format --write .",
       "fix": "biome check --write .",
       "test": "bun test"
     }
   }
   ```

7. **サンプルとテストの雛形**（Bash の heredoc で scaffold する。Edit/Write は使わない）
   ```bash
   mkdir -p src
   [ -f src/index.ts ] || cat > src/index.ts <<'EOF'
   export const add = (a: number, b: number): number => a + b
   EOF
   cat > src/index.test.ts <<'EOF'
   import { expect, test } from 'bun:test'
   import { add } from './index'

   test('add', () => {
     expect(add(1, 2)).toBe(3)
   })
   EOF
   ```

8. **強制チェック hook をプロジェクトに紐づけ**
   - `./.claude/settings.json` に Stop hook をマージする（無ければ新規作成、既存なら hooks のみ追記）:
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash /home/torohash/.claude/hooks/verify-biome-tsc.sh"
             }
           ]
         }
       ]
     }
   }
   ```
   - これにより、以降このプロジェクトでは **ターン終了時に Biome + tsc + bun test が走り、warning/error/失敗が消えるまで修正ループが強制** される（修正は Codex へ委譲）。
   - **`.claude/HOOKS.md` に hook の挙動メモを書く**（自動読込されない plain text。agent が hook 挙動に迷ったとき読む用。Bash heredoc）:
   ```bash
   cat > .claude/HOOKS.md <<'EOF'
   # このプロジェクトの Stop hooks（自動読込なし・必要時に読む用メモ）

   - ターン終了時に `.claude/settings.json` の Stop hook が走る。
   - **verify hook（biome / tsc / bun test）は成功時は完全に無音（exit 0、出力なし）。出力・ブロックするのは失敗時だけ。**
     → **無音＝「走って合格」であり「未発火」ではない**。silence を未発火と誤判定しないこと。
   - グローバルの review-audit-gate はコード増分のあるターンで Codex review を実行し、問題があれば block する。
   - hooks はセッション開始時にスナップショットされる。途中で追加した hook は新セッション（`claude` 再起動）か `/hooks` 承認まで無効。`claude -c` 再開時は再スナップショットされ有効。
   EOF
   ```

9. **整形 → 初回検証**（雛形は biome 既定整形と差があるので、先に `fix` で自動整形してから検証する）
   ```bash
   mise exec -- bun run fix
   mise exec -- bun run lint
   mise exec -- bun run typecheck
   mise exec -- bun test
   ```

## 完了報告に含めるもの
- 導入した bun のバージョン（`mise.toml`）
- 生成/更新したファイル一覧
- `lint / typecheck / test` の結果
- **注意（必ず報告）**: ここで設定した強制チェック Stop hook は **このセッションでは効かない**。Claude Code は起動時に hook をスナップショットするため、起動後に追加した hook は取り込まれない。有効化するには、このプロジェクトを **新しいセッションで開く**（または `/hooks` で承認 / 再起動）必要がある。
- 次の一手（フレームワークが必要なら専用コマンドを後日。それまでは素の TS）
