---
name: bun-init
description: "miseでバージョン固定したBun、Biome、厳格なTypeScript検査、bun:test、CodexのStop検証Hookを備えた素のTypeScriptプロジェクトを初期化または標準化する。ユーザーが$bun-initを明示した場合、フレームワークを使わないBun／TypeScriptプロジェクトの初期化を依頼した場合、または空のリポジトリへこの構成を導入する場合に使用する。明示されない限りNext.js、Viteなどのフレームワークには使用しない。"
---

# Bun TypeScriptプロジェクトを初期化する

バージョン固定したツール、決定的な検査、サンプルテスト、プロジェクト固有のCodex検証Hookを備えた最小構成を作成する。

## ガードレール

- 変更前に作業ツリーと既存のプロジェクトファイルを確認する。
- 既存の`package.json`、`tsconfig.json`、Biome設定、ソース、テスト、`.codex/hooks.json`を上書きしない。
- 無関係な設定を維持しながら、必要な設定だけを既存ファイルへ統合する。
- 既存構成と両立せず置換が必要な場合だけ、一度確認する。それ以外は不要な確認を挟まず進める。
- Bunを`mise.toml`で固定し、`mise exec -- bun`または`mise exec -- bunx`経由で実行する。
- アプリケーションフレームワークを導入しない。

## 手順

1. `mise`が利用可能か確認する。存在しない場合は、作業を止めるエラーとして報告する。
2. Bunを固定してインストールする。

   ```bash
   mise use bun@latest
   mise install
   ```

3. `package.json`が存在しない場合だけ初期化する。

   ```bash
   mise exec -- bun init -y
   ```

4. 開発依存を追加する。

   ```bash
   mise exec -- bun add -d typescript @types/bun @biomejs/biome
   ```

5. `biome.json`と`biome.jsonc`のどちらも存在しない場合だけBiomeを初期化する。

   ```bash
   mise exec -- bunx biome init
   ```

6. 次のコンパイラ設定を`tsconfig.json`へ統合する。

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

7. 既存のスクリプトを削除せず、次のスクリプトを`package.json`へ統合する。

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

8. 新規または空のプロジェクトでは、未作成の場合だけ`src/index.ts`と`src/index.test.ts`を作成する。

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

9. `.codex/hooks.json`を作成または統合する。既存Hookをすべて維持し、次の`Stop`ハンドラーを一度だけ追加する。

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash \"$HOME/.agents/skills/bun-init/scripts/verify.sh\"",
               "timeout": 600,
               "statusMessage": "Bunプロジェクトを検証しています"
             }
           ]
         }
       ]
     }
   }
   ```

10. 整形と検証を実行する。

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
- lint、型検査、テストの結果
- 新しいプロジェクトHookは`/hooks`で内容を確認して信頼する必要があり、有効化に新しいCodexセッションが必要な場合があること
