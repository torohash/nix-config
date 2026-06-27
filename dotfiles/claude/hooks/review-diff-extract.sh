#!/usr/bin/env bash
# Extract and accept Claude review snapshots without running any review model.

set -euo pipefail

code_exts=(py js jsx ts tsx go rs java c h cc cpp rb php swift sql sh nix)
pathspecs=()
for ext in "${code_exts[@]}"; do
  pathspecs+=("*.${ext}")
done

PATHSPEC_VERSION="code-exts-v2-nix"
PROMPT_VERSION="verify-review-v2"
CHECK_POLICY_VERSION="semantic-domains-v1"
MODEL="${REVIEW_GATE_MODEL:-${CODEX_MODEL:-codex-companion-default}}"

run_tmp_dir=""

cleanup_tmp() {
  set +e
  if [[ -n "${run_tmp_dir:-}" ]]; then
    rm -rf -- "$run_tmp_dir"
  fi
}

die() {
  local message="$1"

  printf 'review-diff-extract: %s\n' "$message" >&2
  exit 1
}

print_empty() {
  printf '{"empty":true}\n'
}

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required"
}

trap cleanup_tmp EXIT

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  die "usage: review-diff-extract.sh extract|accept [current_oid]"
fi
shift || true

if [[ "$cmd" == "extract" ]] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  print_empty
  exit 0
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git worktree"
require_jq

main_objects="$(git rev-parse --git-path objects)"
main_objects="$(cd "$main_objects" && pwd -P)"
review_dir="$(git rev-parse --git-path claude-review)"
mkdir -p "$review_dir"
review_dir="$(cd "$review_dir" && pwd -P)"
stores_dir="$review_dir/stores"
tmp_root="$review_dir/tmp"
patches_dir="$tmp_root/patches"
state_file="$review_dir/state.json"
lock_file="$review_dir/lock"
mkdir -p "$stores_dir" "$patches_dir"

exec 9>"$lock_file"
flock 9

state_get() {
  local query="$1"

  if [[ -f "$state_file" ]]; then
    jq -r "$query // empty" "$state_file"
  fi
  return 0
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
  local keep_cache_keys=()
  local path oid keep keep_oid cache_key keep_cache_key

  if [[ -f "$state_file" ]]; then
    mapfile -t keep_oids < <(jq -r '[.accepted.oid?, .failed.oid?, .candidate.oid?] | .[]? // empty' "$state_file")
    mapfile -t keep_cache_keys < <(jq -r '[.candidate.cache_key?] | .[]? // empty' "$state_file")
  fi

  shopt -s nullglob

  for path in "$tmp_root"/*; do
    [[ "$path" == "$patches_dir" ]] && continue
    if [[ -n "${run_tmp_dir:-}" && "$path" == "$run_tmp_dir" ]]; then
      continue
    fi
    rm -rf -- "$path"
  done

  for path in "$patches_dir"/*.patch; do
    cache_key="$(basename "$path" .patch)"
    keep=0
    for keep_cache_key in "${keep_cache_keys[@]}"; do
      if [[ "$cache_key" == "$keep_cache_key" ]]; then
        keep=1
        break
      fi
    done
    if [[ "$keep" -eq 0 ]]; then
      rm -f -- "$path"
    fi
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
  local candidate_patch_oid="${7:-}"
  local candidate_cache_key="${8:-}"
  local candidate_patch_file="${9:-}"
  local candidate_base_oid="${10:-}"
  local tmp_state="$run_tmp_dir/state.json"

  jq -n \
    --arg accepted_oid "$accepted_oid" \
    --arg accepted_store "$accepted_store" \
    --arg failed_oid "$failed_oid" \
    --arg failed_store "$failed_store" \
    --arg candidate_oid "$candidate_oid" \
    --arg candidate_store "$candidate_store" \
    --arg candidate_patch_oid "$candidate_patch_oid" \
    --arg candidate_cache_key "$candidate_cache_key" \
    --arg candidate_patch_file "$candidate_patch_file" \
    --arg candidate_base_oid "$candidate_base_oid" \
    '{
      accepted: (
        if $accepted_oid == "" then
          null
        else
          {oid:$accepted_oid, store:$accepted_store}
        end
      ),
      failed: (
        if $failed_oid == "" then
          null
        else
          {oid:$failed_oid, store:$failed_store}
        end
      ),
      candidate: (
        if $candidate_oid == "" then
          null
        else
          {
            oid:$candidate_oid,
            store:$candidate_store,
            patch_oid:$candidate_patch_oid,
            cache_key:$candidate_cache_key,
            patch_file:$candidate_patch_file,
            base_oid:$candidate_base_oid
          }
        end
      )
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

cache_key_for_patch() {
  local patch_file="$1"

  {
    printf '%s\n%s\n' "$base_oid" "$current_oid"
    cat "$patch_file"
    printf '\n%s\n%s\n%s\n%s\n' "$PATHSPEC_VERSION" "$PROMPT_VERSION" "$CHECK_POLICY_VERSION" "$MODEL"
  } | sha256sum | awk '{print $1}'
}

patch_oid_for_file() {
  local patch_file="$1"

  sha256sum "$patch_file" | awk '{print $1}'
}

accepted_state_store_out() {
  local accepted_oid_value="$1"

  if [[ -n "$accepted_oid_value" ]]; then
    store_rel_for_oid "$accepted_oid_value"
  fi
  return 0
}

load_base_tree() {
  accepted_oid="$(state_get '.accepted.oid')"
  accepted_store="$(state_get '.accepted.store')"
  failed_oid="$(state_get '.failed.oid')"
  candidate_oid="$(state_get '.candidate.oid')"

  base_oid=""
  base_store=""
  if [[ -n "$accepted_oid" || -n "$accepted_store" ]]; then
    if [[ -z "$accepted_oid" || -z "$accepted_store" ]]; then
      die "state file has an incomplete accepted baseline"
    fi
    base_store="$(store_abs_from_state "$accepted_store")"
    validate_tree_store "$accepted_oid" "$base_store"
    base_oid="$accepted_oid"
  elif git rev-parse --verify --quiet HEAD >/dev/null; then
    base_oid="$(git rev-parse HEAD^{tree})"
  else
    base_oid="$(git hash-object -t tree /dev/null)"
  fi
}

extract_diff() {
  local snapshot snapshot_rest current_store current_created alternates
  local patch_tmp changed_tmp changed_json patch_oid cache_key patch_file patch_tmp_final
  local accepted_store_out

  if [[ "$#" -ne 0 ]]; then
    die "extract does not accept arguments"
  fi

  cleanup_orphans
  run_tmp_dir="$(mktemp -d "$tmp_root/run.XXXXXX")"

  if [[ -n "$(git ls-files -u)" ]]; then
    die "merge conflicts remain; resolve them before extracting a review diff"
  fi

  load_base_tree

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
      accepted_store_out="$(accepted_state_store_out "$accepted_oid")"
      write_state "$accepted_oid" "$accepted_store_out" "" "" "" ""
      cleanup_orphans
    fi

    print_empty
    return 0
  fi

  patch_tmp="$run_tmp_dir/delta.patch"
  changed_tmp="$run_tmp_dir/changed-files.z"
  changed_json="$run_tmp_dir/changed-files.json"

  GIT_ALTERNATE_OBJECT_DIRECTORIES="$alternates" \
    git diff --no-ext-diff --binary "$base_oid" "$current_oid" -- "${pathspecs[@]}" >"$patch_tmp"
  GIT_ALTERNATE_OBJECT_DIRECTORIES="$alternates" \
    git diff --name-only -z "$base_oid" "$current_oid" -- "${pathspecs[@]}" >"$changed_tmp"

  jq -Rs 'split("\u0000") | map(select(length > 0))' <"$changed_tmp" >"$changed_json"

  patch_oid="$(patch_oid_for_file "$patch_tmp")"
  cache_key="$(cache_key_for_patch "$patch_tmp")"
  patch_file="$patches_dir/$cache_key.patch"
  patch_tmp_final="$patches_dir/.${cache_key}.patch.$$"
  cp "$patch_tmp" "$patch_tmp_final"
  mv "$patch_tmp_final" "$patch_file"

  accepted_store_out="$(accepted_state_store_out "$accepted_oid")"
  write_state \
    "$accepted_oid" "$accepted_store_out" \
    "" "" \
    "$current_oid" "$(store_rel_for_oid "$current_oid")" \
    "$patch_oid" "$cache_key" "$patch_file" "$base_oid"
  cleanup_orphans

  jq -n \
    --arg patch_file "$patch_file" \
    --arg patch_oid "$patch_oid" \
    --arg base_oid "$base_oid" \
    --arg current_oid "$current_oid" \
    --arg cache_key "$cache_key" \
    --slurpfile changed_files "$changed_json" \
    '{
      patch_file: $patch_file,
      patch_oid: $patch_oid,
      base_oid: $base_oid,
      current_oid: $current_oid,
      cache_key: $cache_key,
      changed_files: $changed_files[0]
    }'
}

accept_snapshot() {
  local requested_oid="${1:-}"
  local extra_arg="${2:-}"
  local snapshot snapshot_rest target_oid target_store target_created

  if [[ -n "$extra_arg" ]]; then
    die "accept accepts at most one current_oid"
  fi

  cleanup_orphans
  run_tmp_dir="$(mktemp -d "$tmp_root/run.XXXXXX")"

  if [[ -n "$(git ls-files -u)" ]]; then
    die "merge conflicts remain; resolve them before accepting a review baseline"
  fi

  if [[ -n "$requested_oid" && ! "$requested_oid" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]]; then
    die "current_oid must be a full SHA-1 or SHA-256 object id"
  fi

  snapshot="$(create_snapshot)"
  target_oid="${snapshot%%$'\t'*}"
  snapshot_rest="${snapshot#*$'\t'}"
  target_store="${snapshot_rest%%$'\t'*}"
  target_created="${snapshot_rest##*$'\t'}"
  : "$target_created"

  if [[ -n "$requested_oid" && "$requested_oid" != "$target_oid" ]]; then
    if [[ "$target_created" -eq 1 ]]; then
      rm -rf -- "$stores_dir/$target_oid"
    fi
    die "current worktree snapshot $target_oid does not match requested oid $requested_oid"
  fi

  write_state "$target_oid" "$(store_rel_for_oid "$target_oid")" "" "" "" ""
  cleanup_orphans

  printf 'review baseline accepted %s\n' "$target_oid"
}

case "$cmd" in
  extract)
    extract_diff "$@"
    ;;
  accept)
    accept_snapshot "$@"
    ;;
  *)
    die "usage: review-diff-extract.sh extract|accept [current_oid]"
    ;;
esac
