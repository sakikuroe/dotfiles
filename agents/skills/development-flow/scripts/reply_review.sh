#!/usr/bin/env bash
# Usage: reply_review.sh <pr_number> <review_node_id> <reply_body> [--with-commit]
#
# Posts a quote reply to a PR review.
# With --with-commit, appends the latest local commit URL automatically.

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: reply_review.sh <pr_number> <review_node_id> <reply_body> [--with-commit]" >&2
    exit 1
fi

PR_NUMBER="$1"
REVIEW_NODE_ID="$2"
REPLY_BODY="$3"
WITH_COMMIT=false
[[ "${4:-}" == "--with-commit" ]] && WITH_COMMIT=true

# Get review body
REVIEW_BODY=$(gh pr view "$PR_NUMBER" --json reviews \
    --jq ".reviews[] | select(.id == \"$REVIEW_NODE_ID\") | .body")

if [[ -z "$REVIEW_BODY" ]]; then
    echo "Error: review not found (id: $REVIEW_NODE_ID)" >&2
    exit 1
fi

# Format as quote block
QUOTED=$(echo "$REVIEW_BODY" | sed 's/^/> /')

# Build commit line if requested
COMMIT_LINE=""
if [[ "$WITH_COMMIT" == true ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
    COMMIT_SHA=$(git rev-parse HEAD)
    COMMIT_SHORT=$(git rev-parse --short HEAD)
    COMMIT_LINE="

反映コミット: [\`${COMMIT_SHORT}\`](https://github.com/${REPO}/commit/${COMMIT_SHA})"
fi

gh pr comment "$PR_NUMBER" --body "${QUOTED}

${REPLY_BODY}${COMMIT_LINE}"
