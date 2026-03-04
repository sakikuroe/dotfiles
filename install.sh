#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%F_%H%M%S)"
ROUNDED_MGENPLUS_URL="https://ftp.iij.ad.jp/pub/osdn.jp/users/8/8598/rounded-mgenplus-20150602.7z"
ROUNDED_MGENPLUS_ARCHIVE_NAME="rounded-mgenplus-20150602.7z"
ROUNDED_MGENPLUS_TTF_NAME="rounded-mgenplus-1m-regular.ttf"

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

download_file() {
  local url="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 1 "$url" -o "$dst"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$dst" "$url"
    return 0
  fi

  echo "error (missing command): curl or wget is required" >&2
  return 1
}

extract_7z_archive() {
  local archive="$1"
  local out_dir="$2"

  mkdir -p "$out_dir"

  if command -v 7z >/dev/null 2>&1; then
    7z x -y "$archive" -o"$out_dir" >/dev/null
    return 0
  fi

  if command -v 7zz >/dev/null 2>&1; then
    7zz x -y "$archive" -o"$out_dir" >/dev/null
    return 0
  fi

  if command -v 7zr >/dev/null 2>&1; then
    7zr x -y "$archive" -o"$out_dir" >/dev/null
    return 0
  fi

  if command -v unar >/dev/null 2>&1; then
    unar -quiet -output-directory "$out_dir" "$archive" >/dev/null
    return 0
  fi

  echo "error (missing command): 7z, 7zz, 7zr, or unar is required to extract .7z" >&2
  return 1
}

ensure_rounded_mgenplus_font() {
  local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/rounded-mgenplus"
  local font_dst="$font_dir/$ROUNDED_MGENPLUS_TTF_NAME"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fonts"
  local archive_path="$cache_dir/$ROUNDED_MGENPLUS_ARCHIVE_NAME"
  local tmp_dir
  local extracted_font

  if [ -f "$font_dst" ]; then
    echo "already installed font: $font_dst"
    return 0
  fi

  echo "download font archive: $ROUNDED_MGENPLUS_URL"
  download_file "$ROUNDED_MGENPLUS_URL" "$archive_path"

  tmp_dir="$(mktemp -d)"
  extract_7z_archive "$archive_path" "$tmp_dir"

  extracted_font="$(find "$tmp_dir" -type f -name "$ROUNDED_MGENPLUS_TTF_NAME" | head -n1 || true)"
  if [ -z "$extracted_font" ]; then
    rm -rf "$tmp_dir"
    echo "error (missing font file): $ROUNDED_MGENPLUS_TTF_NAME" >&2
    return 1
  fi

  mkdir -p "$font_dir"
  cp "$extracted_font" "$font_dst"
  rm -rf "$tmp_dir"
  echo "installed font: $font_dst"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null
    echo "updated font cache: $font_dir"
  else
    echo "skip font cache update: fc-cache is not available"
  fi
}

ensure_gitconfig() {
  local dst="$HOME/.gitconfig"
  local changed=0

  if [ -L "$dst" ]; then
    backup "$dst"
  elif [ -d "$dst" ]; then
    echo "error (not a file): $dst" >&2
    return 1
  fi

  if [ ! -e "$dst" ]; then
    : > "$dst"
  fi

  if ! git config --file "$dst" --get-all include.path | grep -Fxq "~/.config/git/config"; then
    git config --file "$dst" --add include.path "~/.config/git/config"
    changed=1
  fi

  if ! git config --file "$dst" --get-all include.path | grep -Fxq "~/.gitconfig.local"; then
    git config --file "$dst" --add include.path "~/.gitconfig.local"
    changed=1
  fi

  if [ "$changed" -eq 1 ]; then
    echo "updated: $dst"
  else
    echo "already configured: $dst"
  fi
}

link "$DOT/config/nushell/config.nu" "$HOME/.config/nushell/config.nu"
link "$DOT/config/nushell/env.nu" "$HOME/.config/nushell/env.nu"
link "$DOT/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
link "$DOT/config/git/config" "$HOME/.config/git/config"
link "$DOT/config/git/ignore" "$HOME/.config/git/ignore"
ensure_rounded_mgenplus_font
ensure_gitconfig

echo "done."
