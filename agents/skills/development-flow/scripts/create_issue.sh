#!/usr/bin/env bash
# Usage: create_issue.sh <title> <body_file> [--label <label> ...]
#
# 指定したタイトルとファイル本文で Issue を作成する.
# 本文はファイル経由で渡すため, バッククォートやコードブロックを含めても
# シェルのエスケープ事故が起きない (--body-file を強制).
#
# ラベルを複数指定する場合は --label を複数回指定する.
#
# 作成された Issue の URL を標準出力に表示する.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: create_issue.sh <title> <body_file> [--label <label> ...]" >&2
    exit 1
fi

TITLE="$1"
BODY_FILE="$2"
shift 2

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

# 追加引数を gh に渡すための配列. ラベルが無くても空配列を許容するため,
# 後段の呼び出しでは "${GH_ARGS[@]+"${GH_ARGS[@]}"}" で空対策する.
GH_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --label)
            if [[ $# -lt 2 ]]; then
                echo "Error: --label requires a value" >&2
                exit 1
            fi
            GH_ARGS+=(--label "$2")
            shift 2
            ;;
        *)
            echo "Error: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

gh issue create \
    --title "$TITLE" \
    --body-file "$BODY_FILE" \
    ${GH_ARGS[@]+"${GH_ARGS[@]}"}
