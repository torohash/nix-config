---
name: typescript-conventions
description: TypeScript(.ts/.tsx) を書く・編集する・レビューするときのコーディング規約。欠損/失敗/未取得を暗黙の undefined・null・fallback に格下げせず「取れていない」を第一級の状態として表現し、developer が設定すべき値や必須入力は required・非 Optional の固定型で受け取る。TypeScript のコードを書く/直す/監査するたびに参照する。
---

# TypeScript コーディング規約

## 北極星

コードは現実を正しく表現する。**「落ちないこと」ではなく「嘘をつかないこと」を最優先する。**
未取得・失敗・欠損は、それ自体を第一級の状態として表現・伝播させる。暗黙のデフォルトや Optional への格下げで覆い隠さない。「落ちない」は目的ではなく、正しく状態を表現した結果でしかない。

## 二つの軸（温度差がある）

### 軸1: 設定値・必須入力 → required / 非 Optional（厳格）

developer が設定すべき値、関数・コンポーネントの必須入力は **required な固定型**で受け取る。

- default に逃がさない（設定漏れをデフォルトで隠さない）。
- `?` や `| undefined | null` を付けて「無くても通る」ようにしない。
- 未設定はコンパイル時、遅くとも起動時に落ちるのが正しい。

```ts
// ✗ 設定必須なのにデフォルトへ逃がし、設定漏れが黙って通る
function createClient(opts: { endpoint?: string; timeoutMs?: number }) {
  const endpoint = opts.endpoint ?? "http://localhost";
}

// ✓ required。未設定はそもそも型で通らない
function createClient(opts: { endpoint: string; timeoutMs: number }) { /* ... */ }
```

### 軸2: 実行時の外部データ(API / 外部入力) → 明示的な状態（nuanced）

「取れていない / 失敗した」を fallback や undefined にせず、**判別可能な状態**として表現する。
fallback は「意味的に正しいデフォルト」がある時だけ、**理由をコメントして**使う（優先度は低い手段）。

## 状態を潰さない（最重要）

この4つを同一視した瞬間にバグになる。

| 状態 | よくある悪い実装 |
|---|---|
| 未取得 (loading) | `data ?? []` で空扱い |
| 失敗 (error + 理由) | `catch { return undefined }` |
| 取得済み・空 (0件) | 「取れてない」と同じ表示 |
| 取得済み・値あり | — |

```ts
// ✗ 失敗も未取得も 0件も全部 undefined/空 に潰れる
const users = await fetchUsers().catch(() => undefined);
// users?.length ? render(users) : "なし"  ← 失敗と 0件が同じ「なし」

// ✓ 判別可能 union で区別し、UI でも別々に扱う
type Remote<T> =
  | { status: "loading" }
  | { status: "error"; reason: string }
  | { status: "success"; data: T };
```

## 判断手順（欠損に出くわしたら）

1. その「無い」はドメイン上あり得る**正当な状態**か → 明示的にモデル化（union / 明示的なフィールド）し、UI でも区別して表示する。
2. **契約違反 / エラー**か → 境界で fail loud（throw、または error 値を返す）。undefined を下流に流さない。
3. **意味的に正しいデフォルト**があるか → その時だけ、理由をコメントして default を使う。

## 境界で検証する

API レスポンス・外部入力は型注釈を信じず、境界でパースする（zod 等、無ければ手書き guard）。
必須フィールドの欠損は「undefined のまま通す」のではなく **error 状態**にする。

```ts
// ✗ 型注釈だけ付けて信用（実際は欠損しうる）
const body = (await res.json()) as User;

// ✓ 境界で parse し、失敗は状態として返す
const parsed = UserSchema.safeParse(await res.json());
if (!parsed.success) return { status: "error", reason: "invalid response" };
```

## 弾く anti-pattern

- 反射的な `?.` 連鎖 / `x || default` / `x ?? fallback` で欠損を隠す
- 握りつぶし `try { } catch { }`、`catch (e) { return undefined | null | [] }`
- API / 外部入力を無検証で通す、必須フィールドを optional にして「コンパイルを通す」
- `as any` / 安易な `as T` で型を緩めて通す
- 「取れてない」と「0件 / 空」を同一の型・同一の表示にする
- 設定必須値を `?? default` で逃がす、required にせず nullable にする

## 許容される例外

- 意味的に正しいドメインデフォルト（例: 表示件数の既定 20 件）は可。ただし**理由をコメント**する。
- 本当にドメイン上 optional なフィールドは `?` 可。ただし「面倒だから optional」は不可。

## 監査観点（Claude が Codex の差分をレビューする時）

- 新規の `?.` / `||` / `??` は欠損隠しでないか、各所 justified か
- catch が握りつぶしていないか
- 外部入力の境界に検証があるか
- 「取れてない」を型・表示で区別しているか
- 設定 / 必須入力が required・非 Optional か（default 逃がし・nullable 化がないか）
