---
name: test-sizes
description: テストコードを書く・実装に伴ってテストを用意する・テストをレビューするときの汎用規約。Google の small/medium/large サイズ分類（使用リソースで分類）に沿ってテストを常に用意し、hermetic で速い small を主体（およそ 80/15/5）にする。言語非依存。実装・テスト作成・テストレビューのたびに参照する。
---

# テストサイズ規約（small / medium / large）

Google（Testing Blog / "Software Engineering at Google"）のテストサイズ分類に沿った汎用規約。

## 原則

- **production コードには必ずテストを伴わせる。** 実装だけ書いてテストを省かない。
- テストは **size（使用リソースによる分類）** でラベル付けし、**hermetic で速い small を主体**にする。
- **size ≠ scope**: size は「テストが使うリソース・隔離度」で決まる軸。「どれだけのコードを検証するか（unit / integration / e2e）」という scope とは別軸（相関はするが同じではない）。**small = unit と短絡しない**。

## 分類（リソース制約が定義）

### Small（主体・目安 ~80%）

- 単一プロセス、多くは単一スレッド。
- **禁止**: network アクセス、disk I/O（ファイルシステム）、sleep / blocking call、複数スレッド、外部システム。
- 依存はすべて in-memory / fake / mock。
- 必ず**決定的**で速い（ms〜1s 未満）。flaky を許さない。→ 毎コミットで回せる。

### Medium（目安 ~15%）

- 単一マシン。複数プロセス・スレッド可。
- network は **localhost のみ**（localhost の DB / server は可）。local disk 可。
- テストを動かすマシン以外の外部システムには**アクセスしない**。
- small より遅く（数秒オーダー）、多少 flaky になりうる。コンポーネント間結合や実 DB との結合検証など。

### Large（最小限・目安 ~5%）

- マシンをまたいでよい。remote / 外部システムへアクセス可。full e2e / acceptance テスト。
- 最も遅く（分オーダー）、最も flaky。**使いどころを絞る**。

## 判断手順（テストを書くとき）

1. まず **small で書けないか**考える（依存を fake / mock、in-memory 化）。書けるなら small。
2. 本物の localhost リソース（実 DB 等）や複数プロセスが必要 → medium。
3. remote / 複数マシン / 実環境 e2e が必要 → large。

上位 size に逃げる前に「fake で small にできないか」を必ず一度問う。

## size をコード上で明示する

テストには size が一目で分かるラベルを付ける（フレームワークの流儀で）:

- Bazel: `size = "small" | "medium" | "large"`
- pytest: marker（`@pytest.mark.small` / `pytestmark`）やディレクトリ分け
- JUnit: `@Tag("small")` / Category、または `*SmallTest` 命名
- Jest / Vitest 等: project 分けやファイル分割（`*.small.test.ts`）、describe 名

命名・配置のどれでもよいが、**どの size か一目で分かる**ことが必須。

## 弾く anti-pattern

- 実装だけ書いてテスト無し
- small で書けるのに安易に medium / large にする（fake 化を検討していない）
- small とラベルしているのに network / disk / sleep を使っている（＝実質 medium。誤ラベル）
- flaky なテストを small として放置
- large ばかりで pyramid が逆三角（遅く不安定な suite）
- 何を検証しているか不明な「ただ通すだけ」のテスト

## 許容される例外

- 一時的な spike / 使い捨てスクリプトはテスト省略可。ただし production 化する時点で必須。
- 比率（80/15/5）は目安。ドメインにより多少前後してよいが、**small を最優先に検討する**姿勢は保つ。

## 監査観点（Claude が Codex の差分を見る時）

- production コード追加にテストが伴っているか
- 各テストに size ラベル / 区別があるか
- small とラベルされたテストが本当に hermetic か（network / disk / sleep を使っていないか）
- 不必要に medium / large へ逃げていないか
- テストが決定的か（flaky 要因がないか）
