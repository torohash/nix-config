#!/usr/bin/env bash
# Block when the worktree contains unaccepted code changes.

set -euo pipefail

code_exts=(py js jsx ts tsx go rs java c h cc cpp rb php swift sql sh)
pathspecs=()
for ext in "${code_exts[@]}"; do
  pathspecs+=("*.${ext}")
done

run_tmp_dir=""
in_fail_closed=0

cleanup_tmp() {
  set +e
  if [[ -n "${run_tmp_dir:-}" ]]; then
    rm -rf -- "$run_tmp_dir"
  fi
}

emit_block() {
  local reason="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -n --arg reason "$reason" '{decision:"block", reason:$reason}'
  else
    printf '{"decision":"block","reason":"%s"}\n' "$reason"
  fi
}

fail_closed() {
  local reason="${1:-review gate の内部エラーが発生しました。安全のため停止をブロックします。}"

  if [[ "$in_fail_closed" -eq 1 ]]; then
    exit 0
  fi

  in_fail_closed=1
  cleanup_tmp
  emit_block "$reason"
  exit 0
}

trap cleanup_tmp EXIT
trap 'fail_closed "review gate の内部エラーが発生しました。安全のため停止をブロックします。"' ERR

hook_input="$(cat)"
project_dir="$(jq -r --arg pwd "$PWD" '.cwd // $pwd' <<<"$hook_input")"

cd "$project_dir"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

main_objects="$(git rev-parse --git-path objects)"
main_objects="$(cd "$main_objects" && pwd -P)"
review_dir="$(git rev-parse --git-path claude-review)"
mkdir -p "$review_dir"
review_dir="$(cd "$review_dir" && pwd -P)"
stores_dir="$review_dir/stores"
tmp_root="$review_dir/tmp"
state_file="$review_dir/state.json"
lock_file="$review_dir/lock"
mkdir -p "$stores_dir" "$tmp_root"

exec 9>"$lock_file"
flock 9

state_get() {
  local query="$1"

  if [[ -f "$state_file" ]]; then
    jq -r "$query // empty" "$state_file"
  fi
}

store_rel_for_oid() {
  local oid="$1"

  printf 'stores/%s/objects\n' "$oid"
}

store_abs_from_state() {
  local store="$1"
  local path

  if [[ "$store" == /* ]]; then
    path="$store"
  else
    path="$review_dir/$store"
  fi

  if [[ "$(basename "$path")" != "objects" ]]; then
    path="$path/objects"
  fi

  printf '%s\n' "$path"
}

validate_tree_store() {
  local oid="$1"
  local object_store="$2"

  [[ -n "$oid" && -d "$object_store" ]]
  GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES= \
    git fsck --connectivity-only --no-dangling "$oid" >/dev/null
}

cleanup_orphans() {
  local keep_oids=()
  local path oid keep keep_oid

  if [[ -f "$state_file" ]]; then
    mapfile -t keep_oids < <(jq -r '[.accepted.oid?, .failed.oid?, .candidate.oid?] | .[]? // empty' "$state_file")
  fi

  shopt -s nullglob

  for path in "$tmp_root"/*; do
    if [[ -n "${run_tmp_dir:-}" && "$path" == "$run_tmp_dir" ]]; then
      continue
    fi
    rm -rf -- "$path"
  done

  for path in "$stores_dir"/*; do
    [[ -d "$path" ]] || continue
    oid="$(basename "$path")"
    keep=0
    for keep_oid in "${keep_oids[@]}"; do
      if [[ "$oid" == "$keep_oid" ]]; then
        keep=1
        break
      fi
    done
    if [[ "$keep" -eq 0 ]]; then
      rm -rf -- "$path"
    fi
  done

  shopt -u nullglob
}

write_state() {
  local accepted_oid="$1"
  local accepted_store="$2"
  local failed_oid="$3"
  local failed_store="$4"
  local candidate_oid="$5"
  local candidate_store="$6"
  local tmp_state="$run_tmp_dir/state.json"

  jq -n \
    --arg accepted_oid "$accepted_oid" \
    --arg accepted_store "$accepted_store" \
    --arg failed_oid "$failed_oid" \
    --arg failed_store "$failed_store" \
    --arg candidate_oid "$candidate_oid" \
    --arg candidate_store "$candidate_store" \
    '{
      accepted: (if $accepted_oid == "" then null else {oid:$accepted_oid, store:$accepted_store} end),
      failed: (if $failed_oid == "" then null else {oid:$failed_oid, store:$failed_store} end),
      candidate: (if $candidate_oid == "" then null else {oid:$candidate_oid, store:$candidate_store} end)
    }' >"$tmp_state"

  mv "$tmp_state" "$state_file"
}

create_snapshot() {
  local snapshot_dir="$run_tmp_dir/snapshot"
  local object_store="$snapshot_dir/objects"
  local index_file="$snapshot_dir/index"
  local oid final_dir final_store created

  mkdir -p "$object_store/pack"

  if git rev-parse --verify --quiet HEAD >/dev/null; then
    GIT_INDEX_FILE="$index_file" GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES="$main_objects" \
      git read-tree HEAD
  else
    GIT_INDEX_FILE="$index_file" GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES="$main_objects" \
      git read-tree --empty
  fi

  GIT_INDEX_FILE="$index_file" GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES="$main_objects" \
    git add -A -- ':/'

  oid="$(
    GIT_INDEX_FILE="$index_file" GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES="$main_objects" \
      git write-tree
  )"

  printf '%s\n' "$oid" |
    GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES="$main_objects" \
      git pack-objects --revs --quiet "$object_store/pack/snapshot" >/dev/null

  GIT_OBJECT_DIRECTORY="$object_store" GIT_ALTERNATE_OBJECT_DIRECTORIES= \
    git fsck --connectivity-only --no-dangling "$oid" >/dev/null

  final_dir="$stores_dir/$oid"
  final_store="$final_dir/objects"
  created=1

  if [[ -d "$final_store" ]]; then
    validate_tree_store "$oid" "$final_store"
    rm -rf -- "$snapshot_dir"
    created=0
  else
    rm -f -- "$index_file"
    mv "$snapshot_dir" "$final_dir"
  fi

  printf '%s\t%s\t%s\n' "$oid" "$final_store" "$created"
}

diff_alternates() {
  local base_store="$1"
  local current_store="$2"
  local alternates=()
  local IFS=:

  if [[ -n "$base_store" ]]; then
    alternates+=("$base_store")
  fi
  alternates+=("$current_store")

  printf '%s\n' "${alternates[*]}"
}

cleanup_orphans
run_tmp_dir="$(mktemp -d "$tmp_root/run.XXXXXX")"

if [[ -n "$(git ls-files -u)" ]]; then
  emit_block "マージコンフリクトが残っています。解消してから Codex review と PM(Claude)監査を実施してください。"
  exit 0
fi

accepted_oid="$(state_get '.accepted.oid')"
accepted_store="$(state_get '.accepted.store')"
failed_oid="$(state_get '.failed.oid')"
candidate_oid="$(state_get '.candidate.oid')"

base_oid=""
base_store=""
if [[ -n "$accepted_oid" || -n "$accepted_store" ]]; then
  if [[ -z "$accepted_oid" || -z "$accepted_store" ]]; then
    fail_closed "review baseline の状態ファイルが壊れています。安全のため停止をブロックします。"
  fi
  base_store="$(store_abs_from_state "$accepted_store")"
  validate_tree_store "$accepted_oid" "$base_store"
  base_oid="$accepted_oid"
elif git rev-parse --verify --quiet HEAD >/dev/null; then
  base_oid="$(git rev-parse HEAD^{tree})"
else
  base_oid="$(git hash-object -t tree /dev/null)"
fi

snapshot="$(create_snapshot)"
current_oid="${snapshot%%$'\t'*}"
snapshot_rest="${snapshot#*$'\t'}"
current_store="${snapshot_rest%%$'\t'*}"
current_created="${snapshot_rest##*$'\t'}"

alternates="$(diff_alternates "$base_store" "$current_store")"
if GIT_ALTERNATE_OBJECT_DIRECTORIES="$alternates" \
  git diff --quiet "$base_oid" "$current_oid" -- "${pathspecs[@]}"; then
  if [[ "$current_created" -eq 1 ]]; then
    rm -rf -- "$stores_dir/$current_oid"
  fi

  if [[ -n "$candidate_oid" || -n "$failed_oid" ]]; then
    accepted_store_out=""
    if [[ -n "$accepted_oid" ]]; then
      accepted_store_out="$(store_rel_for_oid "$accepted_oid")"
    fi
    write_state "$accepted_oid" "$accepted_store_out" "" "" "" ""
    cleanup_orphans
  fi

  exit 0
fi

accepted_store_out=""
if [[ -n "$accepted_oid" ]]; then
  accepted_store_out="$(store_rel_for_oid "$accepted_oid")"
fi

write_state \
  "$accepted_oid" "$accepted_store_out" \
  "" "" \
  "$current_oid" "$(store_rel_for_oid "$current_oid")"
cleanup_orphans

emit_block "新しいコード変更がある。Codex review と PM(Claude)監査を並列で実施し、問題なければ review-accept.sh で承認を記録せよ"
exit 0
