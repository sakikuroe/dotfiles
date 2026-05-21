#!/usr/bin/env bash
# Usage: set_ready.sh <pr_number>
# Converts a draft PR to ready for review.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: set_ready.sh <pr_number>" >&2
    exit 1
fi

PR_NUMBER="$1"
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

gh api "repos/${REPO}/pulls/${PR_NUMBER}" \
    --method PATCH -F draft=false --jq '.draft | if . then "still draft" else "ready" end'
