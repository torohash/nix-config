## 作業ルール
- コードの編集・実装・リファクタは必ず Codex に委譲する。
- 調査・分析も必ず Codex に委譲する。
- ドキュメント（.md / README / 設計メモ / spec）作成は Claude が直接行う。
- Claude 自身が行う作業としてはドキュメント作成やユーザーとの対話、全体の方針決定。
- Claude 自身が Edit/Write/MultiEdit でソースを直接書き換えてはならない。
- 委譲は codex-plugin-cc の `/codex:rescue` で行う。
  - `--background` は **並列で複数の作業を進めたいとき、または単一でも5分以上かかりそうなとき**（設計相談・大きめの実装・調査など）に使う。前景の Bash は5分でタイムアウトするため。すぐ終わる単一作業のみ前景でよい。

## 並列実行の方針
- 効率のため、独立した作業は逐次ではなく **並列に進められるよう計画** する。
- 着手前に作業を分解し、依存関係の無いタスクを洗い出す。
- 依存の無いタスクは複数の Codex タスクを `--background` で同時に投げ、結果を待ち受けてから次へ進む。
- 依存のあるタスクは順序を維持する（前段の結果が必要なものは直列）。

## コードレビュー・監査のサイクル（二重監査）
- 前回 accept 以降の **コード増分** が生じたターンは、edit-only な Stop hook（`review-audit-gate.sh`）が block する（増分が無いターン／非 git では no-op）。差分は private object store の snapshot で **commit 非依存** に管理（`.git/objects`・branch を汚さない／決定論的に cleanup）。
- block されたら、**第1層 Codex review と 第2層 Claude 監査を並列**で実施する:
  - **第1層 Codex review**: Claude が `/codex:review` を実行し、**出力全文を直接読む**（ALLOW・指摘の有無に関わらず必ず読む）。
  - **第2層 Claude 監査**: Codex の戻り（差分・数値・文章・出典）を **verbatim で素通ししない**。ブリーフ・一次情報・事実と照合する。確定の責任は Claude。
- 指摘や食い違いがあれば Codex に修正委譲 → 差分が変わり gate が再 block → 再レビュー。解消するまで反復。
- 両方 pass したら **`bash ~/.claude/hooks/review-accept.sh` を実行して baseline を更新**（以降は新しい増分だけが対象）。
