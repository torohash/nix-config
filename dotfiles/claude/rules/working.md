## 作業ルール
- コードの編集・実装・リファクタは必ず Codex に委譲する。
- 調査・分析・検索（web search / code search 含む）は **原則 Codex に依頼**する（確率的・適宜判断。詳細は search-and-investigation ルール）。
- ドキュメント（.md / README / 設計メモ / spec）作成は Claude が直接行う。
- Claude 自身が行う作業としてはドキュメント作成やユーザーとの対話、全体の方針決定。
- Claude 自身が Edit/Write/MultiEdit でソースを直接書き換えてはならない。
- 委譲は codex-plugin-cc の `codex:codex-rescue` サブエージェントで行う（Agent tool で `subagent_type: codex:codex-rescue` を起動。起動自体が background で、完了時に harness が **実結果つき** `task-notification` を返す）。
  - **task 本文に `--background` を書かない（重要）。** rescue の自然言語タスク文に `--background` を含めると forwarder が companion `task --background`（poll 型ジョブ＝task ID を即 return）に化け、完了通知が来ず `/codex:status` の自前ポーリングが必要になる。companion の `--background` 系は一切使わない。Agent 起動自体が background なので、本文には委譲内容と `--fresh`／`--resume` だけを書けば、`task` が foreground 実行され実結果が notify される。
  - **待ち・監視はサブエージェント内に閉じ込める（Claude 本体はポーリングしない）。** Codex 委譲は async のサブエージェント越しに投げ、「Codex の完了まで待つ／`/codex:status` を見張る」処理は **そのサブエージェントの中だけ**で行わせる。Claude 本体は `/codex:status` を自前ポーリングしない。完了は harness の `task-notification`（結果つき）で受け取り、それを監査して確定する。
    - 理由: サブエージェントは harness が追跡するので、完了時に**結果つきの通知が自動で届く**。待ち/ポーリングの cost は**使い捨ての別 context** に閉じるので、本体の context が監視ノイズで膨らまない。本体は投げっぱなしにでき（他作業と並列）、かつ自前ポーリング不要。
    - 長時間タスクでもサブエージェントは Bash を複数回叩けるため、前景 Bash の5分制限を実質回避できる（5分以上かかりそうなら必ずこの形にする）。
  - Codex スレッドは **原則タスクごとに独立**させる。継続（resume）は「同一タスクの明確な follow-up」のときだけ。判断に迷えば独立を既定とする。タスクごとに context を分離することで、各タスクの精度（performance）を上げるため。

## 並列実行の方針
- 効率のため、独立した作業は逐次ではなく **並列に進められるよう計画** する。
- 着手前に作業を分解し、依存関係の無いタスクを洗い出す。
- 依存の無いタスクは `codex:codex-rescue` を複数 background 起動して同時に投げ（task 本文に `--background` は書かない）、各 `task-notification` を待ち受けてから次へ進む。
- 依存のあるタスクは順序を維持する（前段の結果が必要なものは直列）。

## コードレビュー・監査のサイクル（notify-driven async review＋内容監査）
- 前回 accept 以降の **コード増分**は、Stop hook ではなく `review-auditor` サブエージェントで非同期 review する。差分抽出は `review-diff-extract.sh extract` が担当し、private object store の snapshot で commit 非依存に管理する（`.git/objects`・branch・index を汚さない）。
- コード編集を伴うターンでは、Claude 本体は実装/修正を `codex:codex-rescue` サブエージェント（Agent tool で background 起動・`task` は foreground）に委譲し、`task-notification` の実結果を監査する。同時に、独立して `review-auditor` を background Agent として dispatch し、意味領域（logic/security/data_loss/reliability）の review を走らせる。
- `review-auditor` は内部で Codex companion `task` を **read-only foreground** で呼び、raw findings を決定論ツール（bash -n / shellcheck / ruff / pyright / py_compile 等）とパッチ照合で偽陽性フィルタする。Claude 本体へ返すのは distilled JSON verdict のみ。
- サブエージェント完了通知を受けたら、Claude 本体が verdict を監査する:
  - `clean` → その間に新しいコード増分が無いことを確認し、`bash ~/.claude/hooks/review-diff-extract.sh accept` で baseline を進める。
  - `issues` → issue 内容を監査し、修正を `codex:codex-rescue` に委譲して、extract/review/accept のサイクルを繰り返す。
- Codex companion の `--background` review job は使わない。完了通知は Claude Code harness が追跡する Agent/Bash background unit から受け取り、`/codex:status` の自前ポーリングはしない。
- **第2層 Claude 内容監査**: Codex の戻り（数値・文章・出典・ブリーフ整合）や `review-auditor` の distilled verdict は hook で機械化できない。Claude が verbatim 素通しせず、一次情報・差分・ツール結果と照合してから確定する。
- baseline の手動 init/リセットは `bash ~/.claude/hooks/review-diff-extract.sh accept` で行う。
