#!/usr/bin/env bash
# Usage: add_progress_comment.sh <issue_number> <body_file>
#
# Issue に進捗コメントを追加投稿する.
# 本文はファイル経由で渡すため, バッククォートやコードブロックを含めても
# シェルのエスケープ事故が起きない.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: add_progress_comment.sh <issue_number> <body_file>" >&2
    exit 1
fi

ISSUE_NUMBER="$1"
BODY_FILE="$2"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

gh issue comment "$ISSUE_NUMBER" --body-file "$BODY_FILE"
