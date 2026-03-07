---
name: oracle-review
description: Use the Oracle agent to review the current code changes, fix issues, and repeat until the review is clean.
compatibility: opencode
metadata:
  audience: maintainers
  purpose: review
---

# Oracle Review

Use this skill whenever code was created or modified and an independent review pass is required.

## Goal

- Review the current change set with the `oracle` agent.
- Fix any issues that matter.
- Re-run the review until there are no actionable findings or only intentional trade-offs remain.

## Review Scope

Default to the current uncommitted workspace changes:

```bash
git diff HEAD --
git ls-files --others --exclude-standard | xargs -r -I{} git diff --no-index /dev/null "{}"
```

If the user explicitly asks for another scope, adapt the diff source:

- branch review: `git diff <base>...HEAD`
- commit review: `git show --stat --patch <sha>`
- file review: include the exact file paths and read those files directly

## Required Workflow

1. Collect the review scope and changed file paths.
2. Launch `oracle` as a background task with a read-only review prompt.
3. Keep working on any non-blocked validation while Oracle runs.
4. Retrieve the Oracle result before answering the user.
5. If Oracle finds issues worth fixing, apply the fixes.
6. Re-run validation.
7. Run Oracle review again on the updated diff.
8. Stop only when the review is clean or only intentional, documented trade-offs remain.

## Oracle Prompt Template

Use a prompt in this shape:

```text
1. TASK: Review the current change set in read-only mode.
2. EXPECTED OUTCOME: List only real issues with severity, file path, rationale, and concrete fix guidance.
3. REQUIRED TOOLS: read, grep, bash
4. MUST DO: Focus on correctness, regressions, type safety, missing tests, maintainability, and configuration mistakes. State clearly when no actionable issues are found.
5. MUST NOT DO: Do not modify files. Do not invent issues without evidence from the diff or referenced files.
6. CONTEXT: Include the diff, changed files, validation results, and any known constraints.
```

## Reporting Rules

- Summarize Oracle findings in Japanese.
- Separate actionable issues from "no issue" confirmation.
- If you fixed something because of the review, say what changed and where.
- If you intentionally keep a trade-off, explain why it is acceptable.

## Guardrails

- Never skip collecting Oracle output before the final response.
- Never treat a review as complete without checking untracked files when they are part of the change.
- Never use Oracle review as a substitute for local verification; still run diagnostics, tests, and builds that match the change.
- Never commit automatically.
