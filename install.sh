#!/usr/bin/env bash

# Dotfiles を $HOME 配下へ反映するインストールスクリプトです.
# 設定ファイルは symlink で配置し, 既存ファイルは退避してから置き換えます.
# 追加で必要な外部リソース (フォントなど) もここで導入します.

# 失敗を早期に検出するため, strict mode を有効化します.
# - `-e`: コマンド失敗時に即終了します.
# - `-u`: 未定義変数の参照をエラーにします.
# - `-o pipefail`: パイプの途中で失敗した場合も失敗扱いにします.
set -euo pipefail

# このスクリプトが置かれているディレクトリー (dotfiles ルート) を解決します.
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 退避ファイル名に付与するタイムスタンプです.
TS="$(date +%F_%H%M%S)"
# フォント導入で使用する外部リソースの情報です.
ROUNDED_MGENPLUS_URL="https://ftp.iij.ad.jp/pub/osdn.jp/users/8/8598/rounded-mgenplus-20150602.7z"
ROUNDED_MGENPLUS_ARCHIVE_NAME="rounded-mgenplus-20150602.7z"
ROUNDED_MGENPLUS_TTF_NAME="rounded-mgenplus-1m-regular.ttf"

# 既存ファイル (または symlink) を退避します.
# 退避先は `<path>.bak.<timestamp>` です.
backup() {
  local dst="$1"
  # ファイルと symlink の両方を退避対象にします.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "${dst}.bak.${TS}"
  fi
}

# `src` を `dst` へ symlink として反映します.
# すでに同一の symlink が張られている場合は何もせずスキップします.
link() {
  local src="$1"
  local dst="$2"

  # 反映元が存在しない場合は, 以降の操作が必ず失敗するため即座に中断します.
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    echo "error (missing source): $src" >&2
    return 1
  fi

  # 反映先の親ディレクトリーを作成します.
  mkdir -p "$(dirname "$dst")"

  # 反映先が symlink の場合は, 解決後パスが一致するかを確認します.
  # 一致する場合はすでに目的の状態なので, 余計な退避や作り直しを避けます.
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

  # 既存の反映先は必ず退避してから symlink を作成します.
  backup "$dst"
  ln -s "$src" "$dst"
  echo "linked: $dst -> $src"
}

# URL からファイルをダウンロードします.
# 環境によって `curl` または `wget` を使用します.
download_file() {
  local url="$1"
  local dst="$2"

  # ダウンロード先の親ディレクトリーは事前に作成します.
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

# `.7z` アーカイブを展開します.
# 環境によって利用できるコマンドが異なるため, 複数候補を順に試します.
extract_7z_archive() {
  local archive="$1"
  local out_dir="$2"

  # 展開先のディレクトリーは事前に作成します.
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

# フォント "Rounded Mgen+ 1m" を導入します.
# すでにフォントが存在する場合は何もせず終了します.
ensure_rounded_mgenplus_font() {
  # XDG 環境変数があればそちらを優先し, なければ従来の既定パスへフォールバックします.
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

  # アーカイブをキャッシュへダウンロードします.
  echo "download font archive: $ROUNDED_MGENPLUS_URL"
  download_file "$ROUNDED_MGENPLUS_URL" "$archive_path"

  # 一時ディレクトリーへ展開し, 必要なファイルだけを取り出します.
  tmp_dir="$(mktemp -d)"
  extract_7z_archive "$archive_path" "$tmp_dir"

  # 目的の TTF を探索し, 見つからない場合はエラーで終了します.
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

  # `fc-cache` がある場合のみ, フォントキャッシュ更新まで自動で実施します.
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null
    echo "updated font cache: $font_dir"
  else
    echo "skip font cache update: fc-cache is not available"
  fi
}

# `~/.gitconfig` を "ローカルファイル + include 構成" で整える.
# dotfiles 側の共有設定と, PC 固有の個人情報を分離する目的です.
ensure_gitconfig() {
  # `git config` が書き込む対象のファイルです.
  local dst="$HOME/.gitconfig"
  # include の追加が発生したかどうかのフラグです.
  local changed=0
  # 必須の include パスです.
  local include_paths=(
    "~/.config/git/config"
    "~/.gitconfig.local"
  )
  local existing_include_paths

  # `.gitconfig` が symlink の場合は, 共有状態が崩れるため退避して通常ファイルへ戻します.
  if [ -L "$dst" ]; then
    backup "$dst"
  elif [ -d "$dst" ]; then
    echo "error (not a file): $dst" >&2
    return 1
  fi

  # `git config --file` のために, ファイルが存在しない場合は空ファイルを作成します.
  if [ ! -e "$dst" ]; then
    : > "$dst"
  fi

  # 既存の include.path を収集し, 不足しているものだけを追加します.
  existing_include_paths="$(git config --file "$dst" --get-all include.path 2>/dev/null || true)"
  for include_path in "${include_paths[@]}"; do
    if ! printf '%s\n' "$existing_include_paths" | grep -Fxq "$include_path"; then
      git config --file "$dst" --add include.path "$include_path"
      existing_include_paths="$(printf '%s\n%s\n' "$existing_include_paths" "$include_path")"
      changed=1
    fi
  done

  if [ "$changed" -eq 1 ]; then
    echo "updated: $dst"
  else
    echo "already configured: $dst"
  fi
}

# symlink 反映対象を定義します.
# 同一ディレクトリー配下の設定を 1 箇所にまとめ, 追加や順序変更をしやすくします.
link_pairs=(
  "$DOT/config/nushell/config.nu" "$HOME/.config/nushell/config.nu"
  "$DOT/config/nushell/env.nu" "$HOME/.config/nushell/env.nu"
  "$DOT/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
  "$DOT/config/git/config" "$HOME/.config/git/config"
  "$DOT/config/git/ignore" "$HOME/.config/git/ignore"
)

# 定義したペアを順に反映します.
for ((i = 0; i < ${#link_pairs[@]}; i += 2)); do
  link "${link_pairs[i]}" "${link_pairs[i + 1]}"
done
# フォントを導入します (すでにある場合はスキップします).
ensure_rounded_mgenplus_font
# `.gitconfig` の include 設定を整えます.
ensure_gitconfig

echo "done."
