---
name: bun-init
description: "miseでバージョン固定したBun、Biome、厳格なTypeScript検査、bun:test、project AGENTS.mdの継続検証指示を備えた素のTypeScriptプロジェクトを初期化または標準化する。ユーザーがbun-initまたは$bun-initを明示した場合、フレームワークを使わないBun／TypeScriptプロジェクトの初期化を依頼した場合、または空のリポジトリへこの構成を導入する場合に使用する。明示されない限りNext.js、Viteなどのフレームワークには使用しない。"
compatibility: opencode
---

# Bun TypeScriptプロジェクトを初期化する

バージョン固定したツール、決定的な検査、サンプルテスト、継続検証指示を備えた最小構成を作成する。

## ガードレール

- 変更前に作業ツリーと既存のプロジェクトファイルを確認する。
- 既存の`mise.toml`、`.mise.toml`、`package.json`、`tsconfig.json`、Biome設定、ソース、テスト、`AGENTS.md`を上書きしない。
- 無関係な設定と`AGENTS.md`の既存指示を維持し、必要な設定だけを統合する。
- 既存構成と両立せず置換が必要な場合だけ、一度確認する。それ以外は不要な確認を挟まず進める。
- Bunを`mise.toml`で固定し、`mise exec -- bun`または`mise exec -- bunx`経由で実行する。
- アプリケーションフレームワーク、`.codex` hook、project Pluginを導入しない。

## 手順

1. `mise`が利用可能か確認する。存在しない場合は、作業を止めるエラーとして報告する。
2. 変更前に対象プロジェクトのルートにある`AGENTS.md`を確認する。検証指示のmarkerが両方ない、または正しい順序で一組だけある場合は続行する。片方だけ、同じmarkerが複数、または終了markerが開始markerより前にある場合は、プロジェクトを変更せず異常を報告する。ファイルがなければ続行する。
3. `mise.toml`または`.mise.toml`にBunの固定バージョンがある場合は維持し、次だけを実行する。既存バージョンの更新が必要な場合は実行前に確認する。

   ```bash
   mise install
   ```

   Bunが未設定の場合だけ、最新バージョンを固定してインストールする。

   ```bash
   mise use bun@latest
   mise install
   ```

4. `package.json`が存在しない場合だけ初期化する。

   ```bash
   mise exec -- bun init -y
   ```

5. 開発依存を追加する。

   ```bash
   mise exec -- bun add -d typescript @types/bun @biomejs/biome
   ```

6. `biome.json`と`biome.jsonc`のどちらも存在しない場合だけBiomeを初期化する。

   ```bash
   mise exec -- bunx biome init
   ```

7. 次のコンパイラ設定を`tsconfig.json`へ統合する。

   ```json
   {
     "compilerOptions": {
       "strict": true,
       "noEmit": true,
       "skipLibCheck": true,
       "moduleResolution": "bundler"
     }
   }
   ```

8. 既存のスクリプトを削除せず、次のスクリプトを`package.json`へ統合する。

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

9. 新規または空のプロジェクトでは、未作成の場合だけ`src/index.ts`と`src/index.small.test.ts`を作成する。

   ```ts
   export const add = (a: number, b: number): number => a + b
   ```

   ```ts
   import { expect, test } from "bun:test"
   import { add } from "./index"

   test("add", () => {
     expect(add(1, 2)).toBe(3)
   })
   ```

10. 事前検査済みの`AGENTS.md`へ、次の範囲を一度だけ追加する。ファイルがなければ作成する。markerが両方なければ末尾へ追記し、正しい順序のmarkerが一組だけあれば範囲内だけを更新する。marker外の内容は維持する。

   ```markdown
   <!-- bun-init:verification:start -->
   ## Bun／TypeScriptの継続検証

   Bun／TypeScriptのコード、テスト、`mise.toml`、`.mise.toml`、`package.json`、`bun.lock`、`bun.lockb`、`tsconfig.json`、Biome設定を変更した場合だけ、完了前に次を順番に実行する。

   1. `mise exec -- bun run fix`
   2. `mise exec -- bun run lint`
   3. `mise exec -- bun run typecheck`
   4. `mise exec -- bun test`

   いずれかが失敗した場合は原因を修正し、4つすべてが成功するまで同じ順序で再実行する。対象コードや設定を変更していない場合は実行しない。
   <!-- bun-init:verification:end -->
   ```

11. 整形と検証を実行する。

    ```bash
    mise exec -- bun run fix
    mise exec -- bun run lint
    mise exec -- bun run typecheck
    mise exec -- bun test
    ```

## 完了報告

次を報告する。

- `mise.toml`に固定したBunのバージョン
- 作成または更新したファイル
- `AGENTS.md`へ追加または更新した検証指示
- lint、型検査、テストの結果
