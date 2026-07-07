#!/usr/bin/env bash
# Usage: create_pr.sh <title> <body_file> <head_branch> [base_branch]
#
# PR を draft として作成する。本文ファイルの末尾に署名を自動付加する。
# 実行場所はメインリポジトリーとすること。
#
# 本文はファイル経由で渡すパターンを強制する。
# base_branch を省略した場合は origin の default branch を使う。
# ready への切り替えは set_ready.sh で行う。

set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "Usage: create_pr.sh <title> <body_file> <head_branch> [base_branch]" >&2
    exit 1
fi

TITLE="$1"
BODY_FILE="$2"
HEAD_BRANCH="$3"
BASE_BRANCH="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2
    exit 1
fi

# 署名を自動追加
SEND_FILE=$(mktemp)
trap 'rm -f "$SEND_FILE"' EXIT
bash "${SCRIPT_DIR}/_append_signature.sh" "$BODY_FILE" > "$SEND_FILE"

# base branch が指定されなかった場合は origin の default branch にフォールバックする
if [[ -z "$BASE_BRANCH" ]]; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    BASE_BRANCH="${BASE_BRANCH:-main}"
fi

gh pr create \
    --draft \
    --title "$TITLE" \
    --body-file "$SEND_FILE" \
    --head "$HEAD_BRANCH" \
    --base "$BASE_BRANCH"