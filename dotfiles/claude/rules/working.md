## 作業ルール（不変則）
- コードの編集・実装・リファクタは Claude が直接やらない（Edit/Write/MultiEdit は hook でも deny される）。必ず `codex-runner` に委譲する。委譲の task 本文に `--background` を書かない。
- 調査・分析・検索（web search / code search 含む）も **原則 Codex に委譲**する（詳細は search-and-investigation ルール）。
- ドキュメント（.md / README / 設計メモ / spec）は Claude が直接書く。
- Claude 自身の仕事は方針決定・監査・ユーザー対話。
- コード増分は `review-auditor` で非同期 review し、Claude が verdict を **監査してから** `bash ~/.claude/hooks/review-diff-extract.sh accept` で baseline を進める。Codex や review の戻りは verbatim 素通ししない（第2層 内容監査）。
- 監査は「確認」か「反証」で閉じる。閉じられない項目は『未検証（＋理由）』と明示する。検証していない項目に『信頼するな／鵜呑み禁止』という不信ラベルは貼らない（不信を表明するなら検証もセットで行う。検証しないものはスコープ上の保留として中立に置く）。
- Codex やサブエージェントの戻り（調査結果・review verdict・数値・出典など）をユーザーに伝えるときは、読みにくい原文や専門用語を **咀嚼して分かりやすく** 提示する。一方で要点・数値・出典・判断材料は **削りすぎない**（原文のベタ貼りも、過度な要約による情報欠落も避け、可読性と情報量を両立させる）。
