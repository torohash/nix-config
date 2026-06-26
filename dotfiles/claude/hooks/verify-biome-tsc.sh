#!/usr/bin/env bash
# Enforce a clean Biome and TypeScript check before Claude Code stops.

set -euo pipefail

hook_input="$(cat)"
project_dir="$(jq -r --arg pwd "$PWD" '.cwd // $pwd' <<<"$hook_input")"
stop_hook_active="$(jq -r '.stop_hook_active // false' <<<"$hook_input")"
: "$stop_hook_active"

cd "$project_dir"

if [[ ! -f package.json || ! -f tsconfig.json ]]; then
  exit 0
fi

if [[ ! -f biome.json && ! -f biome.jsonc ]]; then
  exit 0
fi

set +e
biome_output="$(bunx biome check --error-on-warnings . 2>&1)"
biome_status=$?
tsc_output="$(bunx tsc --noEmit 2>&1)"
tsc_status=$?
set -e

if [[ "$biome_status" -eq 0 && "$tsc_status" -eq 0 ]]; then
  exit 0
fi

instruction="Biome/tsc に warning/error が残っています。Codex に修正を委譲し、全て解消するまで再検証してください。"
details="$(
  printf 'Biome 終了コード: %s\n%s\n\nTypeScript 終了コード: %s\n%s' \
    "$biome_status" "$biome_output" "$tsc_status" "$tsc_output"
)"

limit=4000
truncated_details="${details:0:$limit}"
if (( ${#details} > limit )); then
  truncated_details="${truncated_details}"$'\n'"...(出力を切り詰めました)"
fi

reason="${instruction}"$'\n\n'"${truncated_details}"
jq -n --arg reason "$reason" '{decision:"block", reason:$reason}'

exit 0
