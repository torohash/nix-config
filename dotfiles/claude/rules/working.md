## 作業ルール（不変則）
- コードの編集・実装・リファクタは Claude が直接やらない（Edit/Write/MultiEdit は hook でも deny される）。必ず `codex-runner` に委譲する。委譲の task 本文に `--background` を書かない。
- 調査・分析・検索（web search / code search 含む）も **原則 Codex に委譲**する（詳細は search-and-investigation ルール）。
- ドキュメント（.md / README / 設計メモ / spec）は Claude が直接書く。
- Claude 自身の仕事は方針決定・監査・ユーザー対話。
- コード増分は `review-auditor` で非同期 review し、Claude が verdict を **監査してから** `bash ~/.claude/hooks/review-diff-extract.sh accept` で baseline を進める。Codex や review の戻りは verbatim 素通ししない（第2層 内容監査）。
