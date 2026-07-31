#!/usr/bin/env bash
# Route code-file edits to Codex.
# PreToolUse hook for Edit/Write/MultiEdit: deny edits to source-code files so
# the change is delegated to Codex (/codex:rescue) and reviewed via diff.
# Projects can opt out by creating .claude/claude-edits-code at their root.
input=$(cat); file=$(echo "$input" | jq -r '.tool_input.file_path // empty')
project_root=${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.cwd // empty')}
if [ -n "$project_root" ] && [ -f "$project_root/.claude/claude-edits-code" ]; then
  exit 0
fi
if echo "$file" | grep -qiE '\.(py|js|jsx|ts|tsx|go|rs|java|c|h|cc|cpp|rb|php|swift|sh|sql)$'; then
  jq -n --arg f "$file" '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny",
    permissionDecisionReason:("コードはCodexへ委譲する規約。/codex:rescue に依頼し diff をレビューせよ。対象: "+$f)}}'
fi
