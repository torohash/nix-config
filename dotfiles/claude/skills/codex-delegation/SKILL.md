---
name: codex-delegation
description: コードの実装・修正・リファクタや重い調査を Codex に委譲するとき、コード増分のレビュー監査サイクルを回すとき、独立タスクを並列委譲するときの詳細手順。コード編集を伴うタスク・実装タスク・コード調査・レビューのたびに従う。
---

# codex-delegation

Claude は直接 coding しない（不変則は rules 側）。実装・修正・リファクタ・重い調査は Codex に委譲し、
Claude は方針決定・監査・対話に集中する。本 skill はその **詳細手順**。

## 委譲: codex-runner
- 委譲は `codex-runner` サブエージェント（Agent tool で `subagent_type: codex-runner`）で行う。起動自体が
  background で、完了時に harness が **実結果つき** `task-notification` を返す。
- **短い/長いの指定**: 明確に短く閉じたタスクだけ task 本文に `--quick`（foreground）。それ以外は付けない
  （既定で background＋低頻度ポーリングで完了まで見届ける）。`--quick` を誤って長いタスクに付けると
  foreground の Bash timeout で結果ごと失われるため、迷ったら付けない。
- **ルーティングフラグ**: 読み取り専用調査は `--read-only`（既定は write 可）。同一タスクの明確な
  follow-up のみ `--resume`（既定は `--fresh`＝独立スレッド）。`--background` は **書かない**
  （モード選択は codex-runner が `--quick` の有無で行う）。
- 待ち・監視は codex-runner 内に閉じる。Claude 本体は `/codex:status` を自前ポーリングしない。完了は
  `task-notification`（結果つき）で受け取り、監査して確定する。
- Codex スレッドは **原則タスクごとに独立**（`--fresh`）。継続は同一タスクの明確な follow-up のときだけ。

## 並列委譲
- 独立した作業は逐次でなく並列に計画する。着手前に分解し、依存の無いタスクを洗い出す。
- 依存の無いタスクは codex-runner を複数 background 起動して同時に投げ、各 `task-notification` を待ち受けて
  から次へ進む。依存のあるタスクは順序を維持（前段の結果が必要なものは直列）。

## レビュー・監査サイクル（notify-driven async review）
- 前回 accept 以降の **コード増分**を `review-auditor` で非同期 review する。差分抽出は
  `review-diff-extract.sh extract`（private object store の snapshot、commit 非依存）。
- コード編集を伴うターンでは: 実装/修正を `codex-runner` に委譲して実結果を監査する。同時に、独立して
  `review-auditor` を background Agent として **1 つだけ** dispatch する。
- `review-auditor` は orchestrator: 差分を1回 extract → `review-semantic`（logic/security/data_loss/
  reliability）・`review-test-quality`（テストの質）・`review-secret`（機密情報）の **3 子を並行 dispatch**
  → 統合 distilled verdict を 1 つ返す。各子が内部で Codex companion `task` を read-only foreground で呼び、
  raw findings を決定論ツール（bash -n / shellcheck / ruff / pyright / py_compile 等）とパッチ照合で
  偽陽性フィルタする。
- `review-auditor` の完了通知を受けたら、Claude 本体が統合 verdict を監査する:
  - `clean` → その間に新しいコード増分が無いことを確認し、`bash ~/.claude/hooks/review-diff-extract.sh accept`
    で baseline を進める。
  - `issues`（logic/security/data_loss/reliability/test_quality/secret_leak）→ issue 内容を監査し、修正を
    `codex-runner` に委譲して extract/review/accept のサイクルを繰り返す。未解決の issue が残る間は accept しない。
- baseline の手動 init/リセットも `bash ~/.claude/hooks/review-diff-extract.sh accept`。
- Codex companion の `--background` review job は使わない。完了通知は harness が追跡する Agent/Bash
  background unit から受け取り、`/codex:status` の自前ポーリングはしない。

## 第2層 Claude 内容監査
- Codex の戻り（数値・文章・出典・ブリーフ整合）や `review-auditor` の distilled verdict は hook で
  機械化できない。Claude が **verbatim 素通しせず**、一次情報・差分・ツール結果と照合してから確定する。
