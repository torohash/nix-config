---
name: codex-review
description: Interactive code review using OpenAI Codex CLI. Use this skill when the user asks for a code review with Codex, wants a second AI opinion on their code, or mentions "codex review". This skill orchestrates Codex CLI as an external reviewer, enabling multi-turn conversations where the user can ask follow-up questions about review findings. Trigger this skill whenever the user mentions codex code review, wants cross-model review, or asks to review code with codex/openai.
---

# Interactive Code Review with Codex CLI

This skill uses OpenAI's Codex CLI to perform code reviews and enables interactive follow-up conversations using Codex's session resume feature. Claude Code orchestrates the entire flow — the user never leaves the Claude Code interface.

## Quick start

```bash
codex review --uncommitted                     # Review all uncommitted changes
codex review --base main                       # Review branch changes vs main
codex review --commit HEAD                     # Review latest commit
codex exec resume --last "explain finding #3"  # Follow up on the review
```

## Prerequisites

- `codex` CLI installed and authenticated (verify with `codex --version`)
- `OPENAI_API_KEY` environment variable set, or authenticated via `codex login`
- Git repository (required for diff-based reviews)

## Workflow Overview

```
User request → Determine scope → codex review (initial review)
                                       ↓
                   Show results ← Codex output (stderr)
                                       ↓
     User wants custom focus? → codex exec resume --last "focus on X"
                                       ↓
                   Show results ← Codex output
                                       ↓
                               (repeat as needed)
```

## Step 1: Determine Review Scope

Ask the user what they want reviewed, if not already clear from context. Two modes:

### Mode A: Git Diff Review (primary)

Use the built-in `codex review` command, which handles diff collection automatically:

| Scenario | Command |
|----------|---------|
| Uncommitted changes (staged + unstaged + untracked) | `codex review --uncommitted` |
| Branch diff against base | `codex review --base main` |
| Specific commit | `codex review --commit <sha>` |
| With title annotation | `codex review --base main --title "Add auth feature"` |

**Limitation**: `--uncommitted`, `--base`, `--commit` and `[PROMPT]` are mutually exclusive. You cannot pass custom review instructions alongside a scope flag. To customize the review focus (e.g., "focus on security"), run the default review first, then use `codex exec resume --last "focus specifically on security vulnerabilities"` as an immediate follow-up.

If there are no changes (clean working tree), let the user know and offer file-based review instead.

### Mode B: File/Directory Review (fallback)

For reviewing specific files or directories that aren't captured by a diff — use the generic `codex exec` command with a read-only sandbox. This mode accepts a free-form prompt, so custom instructions can be included directly:

```bash
codex exec -s read-only "Review the files in src/auth/ for security issues and code quality."
```

Codex runs in the current working directory by default and can read all files in the repository. Use `-C <dir>` if you need to point Codex at a different directory.

## Step 2: Run the Codex Review

### For diff-based review (recommended):

```bash
# Review uncommitted changes — Codex applies its default review criteria
codex review --uncommitted

# PR review: compare current branch against main
codex review --base main

# Review a specific commit with title
codex review --commit abc1234 --title "Refactor database layer"
```

If the user has specific review focus areas (security, performance, etc.), run the review first, then immediately follow up:

```bash
codex review --uncommitted
# Then:
codex exec resume --last "Focus your review specifically on security vulnerabilities: injection, auth bypass, credential exposure, and XSS. List each finding with severity and a concrete fix."
```

### For file-based review:

```bash
codex exec -s read-only "You are a senior code reviewer. Review the following files:
- src/auth/login.ts
- src/auth/middleware.ts

Focus on security vulnerabilities, bugs, performance issues, and code quality.
Report severity (CRITICAL/HIGH/MEDIUM/LOW), location, problem description, and fix suggestion for each issue.
Provide a summary table at the end."
```

### Output handling

Codex writes progress and the final review to **stderr**. The Claude Code Bash tool captures this automatically. To extract only the final review message programmatically:

```bash
# JSONL output on stdout — filter for the agent's final message
codex exec review --uncommitted --json 2>/dev/null \
  | grep '"type":"agent_message"' \
  | tail -1 \
  | python3 -c "import sys,json; print(json.loads(sys.stdin.readline())['item']['text'])"
```

For most use cases, just run the command and read the Bash output directly — the final message is clearly identifiable at the end.

### Useful flags reference:

| Flag | Applies to | Purpose |
|------|-----------|---------|
| `--uncommitted` | `codex review` | Review staged, unstaged, and untracked changes |
| `--base <branch>` | `codex review` | Review changes against a base branch |
| `--commit <sha>` | `codex review` | Review changes introduced by a commit |
| `--title <title>` | `codex review` | Annotate the review with a commit/PR title |
| `-s read-only` | `codex exec` | Prevent Codex from modifying files |
| `-C <dir>` | `codex exec` | Set working directory |
| `-m <model>` | both | Override the model (default depends on user config) |
| `--json` | `codex exec review` | Output events as JSONL on stdout |

## Step 3: Present Results

Show the Codex review output to the user in full. Preserve the original formatting — Codex's natural language output is the deliverable. After presenting results, let the user know they can ask follow-up questions:

```
[Codex review output here]

---
Codex retains the full review context. You can ask follow-up questions:
e.g., "Explain finding #3 in detail", "Show a fix for the auth issue", etc.
```

## Step 4: Interactive Follow-up with Resume

When the user asks a follow-up question, use `codex exec resume --last` to continue the conversation. Codex retains the full context from the review session, so follow-ups build on everything discussed so far.

```bash
codex exec resume --last "<user's follow-up question>"
```

### Example follow-up patterns:

- "Explain finding #3 in more detail"
- "Is the SQL injection risk in auth.ts actually exploitable given our ORM usage?"
- "Show me a concrete fix for the N+1 query issue"
- "Are there any additional issues in the utils/ directory?"
- "Summarize all CRITICAL and HIGH findings as a checklist"
- "Compare this implementation with the patterns used in other files"

Each `resume --last` call continues the same Codex session — context accumulates naturally across multiple rounds.

### Important notes on resume:

- `codex exec resume` does NOT accept `-s`/`--sandbox`. The sandbox setting from the original session carries over automatically.
- If a resume fails (e.g., no prior session found), fall back to a fresh `codex review` or `codex exec` with the original context.
- Use `-m <model>` with resume to switch models mid-conversation.

## Step 5: Wrap Up

When the user is satisfied, summarize key takeaways if the conversation spanned many rounds. No cleanup is needed — Codex sessions are saved locally and can be resumed later via `codex exec resume --last` or `codex resume` (interactive picker).

## Error Handling

| Error | Recovery |
|-------|----------|
| `codex: command not found` | Tell the user to install: `npm install -g @openai/codex` |
| Authentication error | Tell the user to run `codex login` or set `OPENAI_API_KEY` |
| Empty diff | Inform the user there are no changes. Offer file-based review instead. |
| Timeout / network error | Retry once. If it fails again, report the error. |
| Resume fails (no session) | Fall back to a fresh `codex review` with the original context. |

## Tips

- `codex review` handles diff collection internally — no need to pipe `git diff` manually
- For file-based reviews, always use `-s read-only` to prevent accidental modifications
- For PR reviews, `codex review --base main` captures all branch changes automatically
- Codex reads files in the working directory, so it understands imports and dependencies beyond the diff
- Multiple follow-up rounds help surface issues that single-pass reviews miss
- The two-step pattern (review + resume for focus) works around the prompt/flag mutual exclusivity
