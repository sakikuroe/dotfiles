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
    echo "skip (missing source): $src"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "already linked: $dst -> $src"
    return 0
  fi

  backup "$dst"
  ln -s "$src" "$dst"
  echo "linked: $dst -> $src"
}

link "$DOT/config/nushell/config.nu" "$HOME/.config/nushell/config.nu"
link "$DOT/config/nushell/env.nu" "$HOME/.config/nushell/env.nu"

echo "done."
