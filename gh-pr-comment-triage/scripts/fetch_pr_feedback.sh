#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <pr-number>" >&2
  exit 1
fi

PR_NUMBER="$1"

if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "PR number must be a positive integer." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required but was not found in PATH." >&2
  exit 1
fi

REMOTE_URL="$(git config --get remote.origin.url)"

if [[ "$REMOTE_URL" =~ github.com[:/](.+)/(.+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]%.git}"
else
  echo "Could not determine owner/repo from remote.origin.url"
  exit 1
fi

payload=$(
  gh api graphql -f query="
{
  repository(owner: \"$OWNER\", name: \"$REPO\") {
    pullRequest(number: $PR_NUMBER) {
      comments(first: 100) {
        nodes {
            id
            body
            author { login }
            createdAt
        }
      }
      reviews(first: 100) {
        nodes {
            id
            state
            body
            author { login }
            comments(first: 100) {
            nodes {
                id
                body
                path
                position
                originalPosition
                outdated
            }
          }
        }
      }
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          comments(first: 100) {
            nodes {
              id
              body
              path
              outdated
              replyTo { id }
            }
          }
        }
      }
    }
  }
}
"
)

printf "PR #%s feedback payload:\n%s\n\n" "$PR_NUMBER" "$payload"
printf "%s\n" "tell me whether the item was already fixed OR should be fixed OR you dont think it should be fixed"
