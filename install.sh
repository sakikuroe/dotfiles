#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%F_%H%M%S)"

backup() {
  local dst="$1"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "${dst}.bak.${TS}"
  fi
}

link() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    echo "error (missing source): $src" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    local src_real=""
    local dst_real=""
    src_real="$(readlink -f "$src" 2>/dev/null || true)"
    dst_real="$(readlink -f "$dst" 2>/dev/null || true)"
    if [ -n "$src_real" ] && [ -n "$dst_real" ] && [ "$src_real" = "$dst_real" ]; then
      echo "already linked: $dst -> $src"
      return 0
    fi
  fi

  backup "$dst"
  ln -s "$src" "$dst"
  echo "linked: $dst -> $src"
}

link "$DOT/config/nushell/config.nu" "$HOME/.config/nushell/config.nu"
link "$DOT/config/nushell/env.nu" "$HOME/.config/nushell/env.nu"

echo "done."
