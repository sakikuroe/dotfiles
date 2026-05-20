#!/usr/bin/env bash
# Usage: add_reviewer.sh <pr_number> <username[,username2,...]>

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: add_reviewer.sh <pr_number> <username[,username2,...]>" >&2
    exit 1
fi

PR_NUMBER="$1"
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

IFS=',' read -ra REVIEWERS <<< "$2"
FIELDS=()
for r in "${REVIEWERS[@]}"; do
    FIELDS+=(-f "reviewers[]=${r// /}")
done

gh api "repos/${REPO}/pulls/${PR_NUMBER}/requested_reviewers" \
    --method POST "${FIELDS[@]}" --jq '.requested_reviewers[].login'
