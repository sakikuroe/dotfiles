#!/usr/bin/env bash
# Usage: commit_with_signature.sh <message>
#        commit_with_signature.sh --amend
#
# メッセージ末尾に Co-authored-by: AI Agent を追加して git commit する.
# 1行の要約 (Subject) を維持し, trailer は空行を挟んで末尾に追加する.
#
# 例:
#   commit_with_signature.sh "Fix: メモリリークを修正した"
#   commit_with_signature.sh --amend

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: commit_with_signature.sh <message>" >&2
    echo "       commit_with_signature.sh --amend" >&2
    exit 1
fi

MSG_FILE=$(mktemp)
trap 'rm -f "$MSG_FILE"' EXIT

TRAILER="Co-authored-by: AI Agent"

if [[ "$1" == "--amend" ]]; then
    git log -1 --pretty=%B > "$MSG_FILE"
else
    echo "$1" > "$MSG_FILE"
fi

# trailer が既に存在しなければ追加
if ! grep -qF "$TRAILER" "$MSG_FILE"; then
    echo "" >> "$MSG_FILE"
    echo "$TRAILER" >> "$MSG_FILE"
fi

if [[ "$1" == "--amend" ]]; then
    git commit --amend -F "$MSG_FILE" --no-edit
else
    git commit -F "$MSG_FILE"
fi
