#!/usr/bin/env bash
# Usage: add_progress_comment.sh <issue_number> <body_file>
#
# Issue に進捗コメントを追加投稿する。
# 本文ファイルの末尾に署名 `*This comment was posted by AI Agent.*` を自動付加する。
# 本文はファイル経由で渡すため、バッククォートやコードブロックを含めても
# シェルのエスケープ事故が起きない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 署名を自動追加
SEND_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$BODY_FILE" > "$SEND_FILE"

gh issue comment "$ISSUE_NUMBER" --body-file "$SEND_FILE"
