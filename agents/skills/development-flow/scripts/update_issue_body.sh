#!/usr/bin/env bash
# Usage: update_issue_body.sh <issue_number> <body_file>
#
# 指定した Issue 番号の本文をファイル内容で置き換える.
# 進捗フィールドの更新を頻繁に行うため, ファイル経由で渡すパターンを強制する
# wrapper として用意した.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: update_issue_body.sh <issue_number> <body_file>" >&2
    exit 1
fi

ISSUE_NUMBER="$1"
BODY_FILE="$2"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

gh issue edit "$ISSUE_NUMBER" --body-file "$BODY_FILE"
