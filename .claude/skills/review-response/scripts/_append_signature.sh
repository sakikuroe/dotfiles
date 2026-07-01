#!/usr/bin/env bash
# Usage: _append_signature.sh [file]
#
# ファイルまたは標準入力の末尾に署名を追加する。
# 既に署名が含まれていればそのまま出力する。
# 結果を標準出力に書き出す。
#
# このスクリプトは他のスクリプトから呼び出される内部ヘルパーである。

set -euo pipefail

SIGNATURE='*This comment was posted by AI Agent.*'
input_file="${1:--}"

if grep -qF "$SIGNATURE" "$input_file"; then
    cat "$input_file"
    exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# 末尾の空行を削除して一時ファイルに書き出す
cat "$input_file" | sed -e :a -e '/^\n*$/{$d;N;ba}' > "$tmp"

# 末尾に空行 + 署名を追加
printf '\n%s\n' "$SIGNATURE" >> "$tmp"

cat "$tmp"
