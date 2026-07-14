#!/usr/bin/env bash
# Codexのターン終了時にPythonプロジェクトの品質検査を実行する。

set -euo pipefail

hook_input="$(cat)"
project_dir="$(jq -r --arg pwd "$PWD" '.cwd // $pwd' <<<"$hook_input")"

cd "$project_dir"

if ! uv_bin="$(command -v uv 2>/dev/null)"; then
  uv_bin="$HOME/.local/bin/uv"
  if [[ ! -x "$uv_bin" ]]; then
    exit 0
  fi
fi

if [[ ! -f pyproject.toml || ! -f uv.lock ]]; then
  exit 0
fi

set +e
lint_output="$("$uv_bin" run ruff check . 2>&1)"
lint_status=$?
format_output="$("$uv_bin" run ruff format --check . 2>&1)"
format_status=$?
type_output="$("$uv_bin" run pyright 2>&1)"
type_status=$?
test_output="$("$uv_bin" run pytest 2>&1)"
test_status=$?
set -e

test_failed=0
if [[ "$test_status" -ne 0 && "$test_status" -ne 5 ]]; then
  test_failed=1
fi

if [[ "$lint_status" -eq 0 && "$format_status" -eq 0 && "$type_status" -eq 0 && "$test_failed" -eq 0 ]]; then
  exit 0
fi

instruction="Ruff、Pyright、pytestの検査に失敗しました。問題を修正してから再検証してください。"
details="$(
  printf 'Ruff lint終了コード: %s\n%s\n\nRuff format終了コード: %s\n%s\n\nPyright終了コード: %s\n%s\n\npytest終了コード: %s\n%s' \
    "$lint_status" "$lint_output" "$format_status" "$format_output" "$type_status" "$type_output" "$test_status" "$test_output"
)"

limit=4000
truncated_details="${details:0:$limit}"
if (( ${#details} > limit )); then
  truncated_details="${truncated_details}"$'\n'"...(出力を切り詰めました)"
fi

reason="${instruction}"$'\n\n'"${truncated_details}"
jq -n --arg reason "$reason" '{continue:false, stopReason:$reason, systemMessage:$reason}'
