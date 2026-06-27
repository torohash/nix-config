## 作業ルール
- コードの編集・実装・リファクタは必ず Codex に委譲する。
- 調査・分析・検索（web search / code search 含む）は **原則 Codex に依頼**する（確率的・適宜判断。詳細は search-and-investigation ルール）。
- ドキュメント（.md / README / 設計メモ / spec）作成は Claude が直接行う。
- Claude 自身が行う作業としてはドキュメント作成やユーザーとの対話、全体の方針決定。
- Claude 自身が Edit/Write/MultiEdit でソースを直接書き換えてはならない。
- 委譲は **`codex-runner` サブエージェント**で行う（Agent tool で `subagent_type: codex-runner` を起動。起動自体が background で、完了時に harness が **実結果つき** `task-notification` を返す）。
  - **`codex-runner` を使う理由**: plugin の `codex:codex-rescue` は thin forwarder で、自身の判断で companion `task --background`（poll 型ジョブ＝task ID を即 return）に化けることがあり、しかも status/result のポーリングが禁止されているため、長時間タスクで完了結果が返らない。`codex-runner` は短いタスクを foreground、長いタスクを background＋低頻度ポーリングで完了まで見届け、Codex の実結果を返す。
  - **短い/長いの指定**: 明確に短く閉じたタスクだけ task 本文に `--quick` を付ける（foreground）。それ以外は付けない（既定で background＋ポーリング）。`--quick` を誤って長いタスクに付けると foreground の Bash timeout で結果ごと失われるため、迷ったら付けない。
  - **ルーティングフラグ**: 読み取り専用調査は `--read-only`（既定は write 可）。同一タスクの明確な follow-up のみ `--resume`（既定は `--fresh`＝独立スレッド）。`--background` は **書かない**（モード選択は `codex-runner` が `--quick` の有無で行う）。
  - **待ち・監視はサブエージェント内に閉じ込める（Claude 本体はポーリングしない）。** `codex-runner` が内部で `status --wait`（8 分窓・30 秒間隔の低頻度ポーリング）を回して完了まで見届ける。Claude 本体は `/codex:status` を自前ポーリングしない。完了は harness の `task-notification`（結果つき）で受け取り、それを監査して確定する。
    - 理由: サブエージェントは harness が追跡するので、完了時に**結果つきの通知が自動で届く**。待ち/ポーリングの cost は**使い捨ての別 context** に閉じるので、本体の context が監視ノイズで膨らまない。本体は投げっぱなしにでき（他作業と並列）。
  - Codex スレッドは **原則タスクごとに独立**させる。継続（resume）は「同一タスクの明確な follow-up」のときだけ。判断に迷えば独立を既定とする。タスクごとに context を分離することで、各タスクの精度（performance）を上げるため。

## 並列実行の方針
- 効率のため、独立した作業は逐次ではなく **並列に進められるよう計画** する。
- 着手前に作業を分解し、依存関係の無いタスクを洗い出す。
- 依存の無いタスクは `codex-runner` を複数 background 起動して同時に投げ（task 本文に `--background` は書かない。長いタスクは `codex-runner` が内部でポーリングする）、各 `task-notification` を待ち受けてから次へ進む。
- 依存のあるタスクは順序を維持する（前段の結果が必要なものは直列）。

## コードレビュー・監査のサイクル（notify-driven async review＋内容監査）
- 前回 accept 以降の **コード増分**は、Stop hook ではなく `review-auditor` サブエージェントで非同期 review する。差分抽出は `review-diff-extract.sh extract` が担当し、private object store の snapshot で commit 非依存に管理する（`.git/objects`・branch・index を汚さない）。
- コード編集を伴うターンでは、Claude 本体は実装/修正を `codex-runner` サブエージェント（Agent tool で background 起動。短ければ `--quick`=foreground、長ければ background＋ポーリング）に委譲し、`task-notification` の実結果を監査する。同時に、独立して `review-auditor` を background Agent として **1 つだけ** dispatch する。`review-auditor` は内部で 3 種の review を **並行**に回す:
  - 意味領域（logic/security/data_loss/reliability）
  - テストの質（浅い/弱いテストの検出。テストファイルの変更があるときだけ）
  - 機密情報（鍵・トークン・認証情報・秘密 URL）の混入
  - → main は 1 回 dispatch して 1 つの統合 verdict を監査するだけでよい（PM 側の負担を増やさない）。
- `review-auditor`（orchestrator）は差分を1回だけ抽出し、`review-semantic`・`review-test-quality`・`review-secret` の 3 子を並行 dispatch して集約する。各子が内部で Codex companion `task` を **read-only foreground** で呼び、raw findings を決定論ツール（bash -n / shellcheck / ruff / pyright / py_compile 等）とパッチ照合で偽陽性フィルタし、distilled verdict を返す。`review-auditor` はそれらを統合し、Claude 本体へは統合 distilled JSON verdict のみ返す。
- `review-auditor` の完了通知を受けたら、Claude 本体が統合 verdict を監査する:
  - `clean` → その間に新しいコード増分が無いことを確認し、`bash ~/.claude/hooks/review-diff-extract.sh accept` で baseline を進める。
  - `issues` → issue 内容（logic/security/data_loss/reliability/test_quality/secret_leak）を監査し、修正を `codex-runner` に委譲して、extract/review/accept のサイクルを繰り返す。未解決の issue が残る間は accept しない。
- Codex companion の `--background` review job は使わない。完了通知は Claude Code harness が追跡する Agent/Bash background unit から受け取り、`/codex:status` の自前ポーリングはしない。
- **第2層 Claude 内容監査**: Codex の戻り（数値・文章・出典・ブリーフ整合）や `review-auditor` の distilled verdict は hook で機械化できない。Claude が verbatim 素通しせず、一次情報・差分・ツール結果と照合してから確定する。
- baseline の手動 init/リセットは `bash ~/.claude/hooks/review-diff-extract.sh accept` で行う。
