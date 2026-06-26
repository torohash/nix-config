#!/usr/bin/env bash
# Accept the current worktree snapshot as the reviewed baseline.

set -euo pipefail

run_tmp_dir=""

cleanup_tmp() {
  set +e
  if [[ -n "${run_tmp_dir:-}" ]]; then
    rm -rf -- "$run_tmp_dir"
  fi
}

fail_closed() {
  cleanup_tmp
  printf '%s\n' "review baseline の更新に失敗しました。状態を確認してから再実行してください。" >&2
  exit 1
}

trap cleanup_tmp EXIT
trap fail_closed ERR

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' "git リポジトリではありません。" >&2
  exit 1
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
  local tmp_state="$run_tmp_dir/state.json"

  jq -n \
    --arg accepted_oid "$accepted_oid" \
    --arg accepted_store "$accepted_store" \
    '{
      accepted: {oid:$accepted_oid, store:$accepted_store},
      failed: null,
      candidate: null
    }' >"$tmp_state"

  mv "$tmp_state" "$state_file"
}

create_snapshot() {
  local snapshot_dir="$run_tmp_dir/snapshot"
  local object_store="$snapshot_dir/objects"
  local index_file="$snapshot_dir/index"
  local oid final_dir final_store

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

  if [[ -d "$final_store" ]]; then
    validate_tree_store "$oid" "$final_store"
    rm -rf -- "$snapshot_dir"
  else
    rm -f -- "$index_file"
    mv "$snapshot_dir" "$final_dir"
  fi

  printf '%s\t%s\n' "$oid" "$final_store"
}

cleanup_orphans
run_tmp_dir="$(mktemp -d "$tmp_root/run.XXXXXX")"

if [[ -n "$(git ls-files -u)" ]]; then
  printf '%s\n' "マージコンフリクトが残っています。解消してから review baseline を更新してください。" >&2
  exit 1
fi

old_accepted_oid="$(state_get '.accepted.oid')"
old_failed_oid="$(state_get '.failed.oid')"
old_candidate_oid="$(state_get '.candidate.oid')"

snapshot="$(create_snapshot)"
current_oid="${snapshot%%$'\t'*}"
current_store="${snapshot#*$'\t'}"
: "$current_store"

write_state "$current_oid" "$(store_rel_for_oid "$current_oid")"
cleanup_orphans

for old_oid in "$old_accepted_oid" "$old_failed_oid" "$old_candidate_oid"; do
  if [[ -n "$old_oid" && "$old_oid" != "$current_oid" ]]; then
    rm -rf -- "$stores_dir/$old_oid"
  fi
done

printf 'review baseline を更新しました %s\n' "$current_oid"
