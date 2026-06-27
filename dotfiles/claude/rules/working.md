## 作業ルール
- コードの編集・実装・リファクタは必ず Codex に委譲する。
- 調査・分析・検索（web search / code search 含む）は **原則 Codex に依頼**する（確率的・適宜判断。詳細は search-and-investigation ルール）。
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

## コードレビュー・監査のサイクル（verify 型ゲート＋内容監査）
- 前回 accept 以降の **コード増分**が生じたターンは、Stop hook `review-audit-gate.sh` が **gate 自身で Codex review を実行**する（増分が無いターン／非 git では no-op）。差分は private object store の snapshot で commit 非依存に管理し、`.git/objects`・branch を汚さず決定論的に cleanup。
- gate の判定（fail-closed）:
  - **ALLOW** → baseline を自動 accept して停止許可。
  - **BLOCK／実行失敗（不可用・timeout・JSON parse 失敗・巨大差分）** → 停止を block し指摘を Claude に返す。
- block されたら Claude は指摘を読み、**修正を Codex に委譲** → 差分が変わり gate が再 review → 解消するまで反復（ruff の fix ループと同型）。
- gate の review は **意味領域（logic/security/data_loss/reliability）限定**（構文/lint/型は verify-* hook=決定論の担当）。BLOCK を**決定論ツール（ruff/pyright/py_compile 等）で偽陽性と確認**できた場合のみ、`.git/claude-review/overrides/<cache_key>.json`（`patch_oid` 記載）で override して accept できる（audit.log に記録）。幻覚 BLOCK のデッドロック脱出口。
- review は **gate が同期実行**するので、Claude が手動で `/codex:review` を起動したり background dispatch したりしない（dispatch+待機は Stop ループを誘発するため禁止）。
- **第2層 Claude 内容監査**: Codex の戻り（数値・文章・出典・ブリーフ整合）は hook で機械化できない。レポート/データ等を扱うときは Claude が verbatim 素通しせず、一次情報と照合してから確定する。
- `review-accept.sh` は baseline の手動 init/リセット用（通常フローでは gate が自動 accept する）。
