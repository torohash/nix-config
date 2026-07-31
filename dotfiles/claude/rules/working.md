## 作業ルール（不変則）
- コードの編集・実装・リファクタは Claude が直接やらない（Edit/Write/MultiEdit は hook でも deny される）。必ず `codex-runner` に委譲する。委譲の task 本文に `--background` を書かない。
- **実装委譲の例外**: プロジェクト直下に `.claude/claude-edits-code` が存在する場合、そのプロジェクトに限り上記の実装委譲ルールを適用せず、**Claude が直接コードを編集する**（`route-code-to-codex.sh` hook も同じマーカーを見て deny を解除する）。例外の対象は「実装」のみで、下の調査委譲ルールは解除されない。プロジェクト側 CLAUDE.md に例外の趣旨・範囲が書かれている場合はそれに従う。
- 調査・分析・検索（web search / code search 含む）も **原則 Codex に委譲**する（詳細は search-and-investigation ルール）。上の実装例外プロジェクトでもこのルールは維持する。
- ドキュメント（.md / README / 設計メモ / spec）は Claude が直接書く。
- Claude 自身の仕事は方針決定・監査・ユーザー対話。
- コード増分は `review-auditor` で非同期 review し、Claude が verdict を **監査してから** `bash ~/.claude/hooks/review-diff-extract.sh accept` で baseline を進める。Codex や review の戻りは verbatim 素通ししない（第2層 内容監査）。
- 監査は「確認」か「反証」で閉じる。閉じられない項目は『未検証（＋理由）』と明示する。検証していない項目に『信頼するな／鵜呑み禁止』という不信ラベルは貼らない（不信を表明するなら検証もセットで行う。検証しないものはスコープ上の保留として中立に置く）。
- Codex やサブエージェントの戻り（調査結果・review verdict・数値・出典など）をユーザーに伝えるときは、読みにくい原文や専門用語を **咀嚼して分かりやすく** 提示する。一方で要点・数値・出典・判断材料は **削りすぎない**（原文のベタ貼りも、過度な要約による情報欠落も避け、可読性と情報量を両立させる）。
