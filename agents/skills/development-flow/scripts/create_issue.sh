#!/usr/bin/env bash
# Usage: create_issue.sh <title> <body_file>
#
# 指定したタイトルとファイル本文で Issue を作成する.
# 本文はファイル経由で渡すため, バッククォートやコードブロックを含めても
# シェルのエスケープ事故が起きない (--body-file を強制).
#
# 作成された Issue の URL を標準出力に表示する.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: create_issue.sh <title> <body_file>" >&2
    exit 1
fi

TITLE="$1"
BODY_FILE="$2"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

gh issue create \
    --title "$TITLE" \
    --body-file "$BODY_FILE"
