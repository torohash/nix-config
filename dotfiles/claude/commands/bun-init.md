---
description: Bootstrap a bare TypeScript project (mise + bun + Biome + tsc + bun test) fully automatically
---

# /bun-init — TypeScript プロジェクト初期セットアップ

node 系プロジェクトの土台を **全自動** で構築する。Next.js / Vite 等のフレームワークは
本コマンドの対象外（フレームワーク用コマンドは後日別途用意）。TypeScript は必須。

確認は求めず、各ステップを順に実行し、最後にまとめだけ報告する。
（破壊的操作=既存 `package.json` 等が既にある場合のみ、上書き前に一度だけ確認する）

## 実行手順（上から順に Bash で実行）

1. **bun を mise で導入・固定**
   ```bash
   mise use bun@latest
   mise install
   ```

2. **TypeScript プロジェクト初期化**（`package.json` が無い場合のみ）
   ```bash
   bun init -y
   ```

3. **依存追加**（型チェッカ + Biome）
   ```bash
   bun add -d typescript @types/bun @biomejs/biome
   ```

4. **Biome 初期化**（lint + formatter）
   ```bash
   bunx biome init
   ```

5. **`tsconfig.json` を strict + noEmit 前提に調整**（`.json` なので Claude が直接編集可）
   - `"strict": true`, `"noEmit": true`, `"skipLibCheck": true`, `"moduleResolution": "bundler"` を確認/設定。

6. **`package.json` に scripts を追加**（`.json` なので Claude が直接編集可）
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
   - これにより、以降このプロジェクトでは **ターン終了時に Biome + tsc 検証が走り、warning/error が消えるまで修正ループが強制** される（修正は Codex へ委譲）。

9. **初回検証**
   ```bash
   bun run lint && bun run typecheck && bun test
   ```

## 完了報告に含めるもの
- 導入した bun のバージョン（`mise.toml`）
- 生成/更新したファイル一覧
- `lint / typecheck / test` の結果
- 次の一手（フレームワークが必要なら `/setup-next` 等を後日。それまでは素の TS）
