#!/usr/bin/env bash

# Best-effort SessionStart hook. Never block Claude Code startup.
workspace_cwd=${PWD:-}
hook_input=

if [ ! -t 0 ]; then
  hook_input=$(cat 2>/dev/null || true)
fi

if command -v jq >/dev/null 2>&1 && [ -n "$hook_input" ]; then
  parsed_cwd=$(printf '%s' "$hook_input" | jq -r '.cwd // empty' 2>/dev/null || true)
  if [ -n "$parsed_cwd" ]; then
    workspace_cwd=$parsed_cwd
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  exit 0
fi

companion=$(
  ls -d "$HOME"/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs 2>/dev/null |
    sort -V |
    tail -1
)

if [ -z "$companion" ]; then
  exit 0
fi

cd "$workspace_cwd" 2>/dev/null || exit 0

node "$companion" setup --enable-review-gate >/dev/null 2>&1 || true

exit 0
