#!/usr/bin/env bash
# Block once per new code diff state to force review and audit before stopping.

set -euo pipefail

hook_input="$(cat)"
project_dir="$(jq -r --arg pwd "$PWD" '.cwd // $pwd' <<<"$hook_input")"

cd "$project_dir"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

code_exts=(py js jsx ts tsx go rs java c h cc cpp rb php swift sh sql)
pathspecs=()
for ext in "${code_exts[@]}"; do
  pathspecs+=("*.${ext}")
done

if git rev-parse --verify --quiet HEAD >/dev/null; then
  base="HEAD"
else
  base="$(git hash-object -t tree /dev/null)"
fi

tracked_diff="$(git diff "$base" -- "${pathspecs[@]}")"
untracked_payload="$(
  git ls-files --others --exclude-standard -z -- "${pathspecs[@]}" |
    while IFS= read -r -d '' file; do
      printf -- '--- untracked file: %s ---\n' "$file"
      cat -- "$file"
      printf '\n'
    done
)"
raw="${tracked_diff}${untracked_payload}"

if [[ -z "$raw" ]]; then
  exit 0
fi

signature="$(printf '%s' "$raw" | sha256sum | awk '{print $1}')"
marker_file="$(git rev-parse --git-dir)/codex-review-marker"
marker_value=""

if [[ -f "$marker_file" ]]; then
  marker_value="$(<"$marker_file")"
fi

if [[ "$signature" == "$marker_value" ]]; then
  exit 0
fi

printf '%s\n' "$signature" >"$marker_file"

reason='新しいコード変更が検出されました。`/codex:review` を実行してレビューし、さらに Codex の戻り（差分・数値・文章・出典）を verbatim で素通しせず、ブリーフ・一次情報・事実と照合して監査してから終了してください。'
jq -n --arg reason "$reason" '{decision:"block", reason:$reason}'

exit 0
