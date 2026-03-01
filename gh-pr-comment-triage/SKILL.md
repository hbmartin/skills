---
name: gh-pr-comment-triage
description: Fetch GitHub pull request feedback for a PR number and triage each comment/review item as already fixed, should be fixed, or should not be fixed. Use when the user asks to evaluate GitHub PR feedback status from `gh pr view`.
---

# Gh Pr Comment Triage

## Execute Workflow

1. Extract the PR number from the request.
2. Run `scripts/fetch_pr_feedback.sh <pr-number>`. (in the home skills directory)
3. Read the emitted payload and classify each feedback item.
4. Build a JSON array where each item has:
   - `comment_id`
   - `author_name`
   - `decision`
   - `minimal_comment_summary`
5. Persist the JSON array in SQLite by piping it to:
   - `scripts/store_triage_decisions.py --pr-number <pr-number>`
6. Return a triage list that uses only these statuses:
   - `already fixed`
   - `should be fixed`
   - `should not be fixed`

Use the returned JSON as the source of truth.

## Response Requirements

After reading the data, tell the caller:

`tell me whether the item was already fixed OR should be fixed OR you dont think it should be fixed`

For each item, include:
- One status from the allowed list
- A one-sentence rationale

Also include the exact JSON array you persisted so the storage step is auditable.
