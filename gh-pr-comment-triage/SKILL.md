---
name: gh-pr-comment-triage
description: Fetch GitHub pull request feedback for a PR number and triage each comment/review item as already fixed, high-level, should be fixed, or should not be fixed. Use when the user asks to evaluate GitHub PR feedback status from `gh pr view`.
---

# Gh Pr Comment Triage

## Execute Workflow

1. Extract the PR number from the request.
2. If you are generating a title for this thread be sure to include the PR number
3. Run `scripts/fetch_pr_feedback.sh <pr-number>`. (in the home skills directory)
4. Capture the emitted file path, then read that file for the PR feedback payload. The script saves the payload to `reviews_triage/` in the current working directory and returns only the saved filename/path.
5. Build a JSON array where each item has:
   - `comment_id`
   - `author_name`
   - `decision`
   - `minimal_comment_summary`
   - `severity` (integer 0-3)
   - `category` (one lowercase word)
   - `reviewing_agent` (the current agent's own name, for example `codex`)
6. Persist the JSON array in SQLite by piping it to:
   - `scripts/store_triage_decisions.py --pr-number <pr-number> <repo_path>/triage_decisions.db`
7. Classify each item with exactly one of these statuses:
   - `already fixed`
   - `high-level`
   - `should be fixed`
   - `should not be fixed`

Use the JSON loaded from the saved file as the source of truth.

Always set `reviewing_agent` to your own agent name for every triage record so the database shows who performed the review.

## Response Requirements

Use these category examples when labeling feedback:
- `types`
- `react`
- `database`
- `api`
- `tests`
- `security`
- `performance`
- `ci`
- `deploy`
- `docs`
- `accessibility`
- `styling`
- `state`

Severity guidance:
- `0` = trivial/nit
- `1` = low impact
- `2` = medium impact
- `3` = critical risk

Mark an item as `high-level` when it is broad direction, non-actionable guidance, or a deploy/status note rather than a concrete fix request.

Final user-facing response rules:
- Do not return raw JSON.
- Do not dump a complete item-by-item bug list.
- Return a de-duplicated summary of feedback themes grouped by classification
- Include justification for items that  `should not be fixed`
- Include a concrete plan for items that `should be fixed`, prioritized by severity.
- The concrete plan should inspect high severity issues and offer suggestions for depcruise and/or semgrep rules to prevent those issues fro re-occuring
- Mention `already fixed` and `high-level` as concise rollups (counts and short rationale), not exhaustive listings.
- Tell the user they can type 'y' to implement the suggested fixes. And if they respond with 'y', implement the fixes automatically.
