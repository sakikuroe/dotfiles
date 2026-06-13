#!/bin/bash
# GitHubリポジトリ内の任意のディレクトリを、ローカルの同じパスに取得するスクリプト
set -euo pipefail
# set -e          : コマンドが失敗したらスクリプト全体を即座に終了する
# set -u          : 未定義の変数を使おうとしたらエラーにする
# set -o pipefail : パイプ(|)の途中でエラーが起きても検知する

# --- 0. 取得元リポジトリを引数で受け取る(必須・既定値なし)---
[ $# -ge 1 ] || {
  echo "error: 取得元リポジトリのURLを引数で指定してください" >&2
  echo "  例: curl -fsSL <script-url> | bash -s -- https://github.com/user/repo.git" >&2
  exit 1
}
# $#         : スクリプトに渡された引数の個数
# -ge 1      : 1個以上か確認。0個なら使い方を表示して異常終了する
REPO_URL="$1"
# 第1引数を取得元リポジトリとして使う

# --- 1. 開発リポジトリのルートで実行されているか確認 ---
[ -d .git ] || { echo "error: .git not found(リポジトリのルートで実行してください)" >&2; exit 1; }
# [ -d .git ] : カレントディレクトリに .git があるか確認
# なければエラーを出して異常終了する

# --- 2. リポジトリの「構造」だけを取得する(ファイル本体はまだ落とさない)---
TMP_DIR=$(mktemp -d)
# 作業用の一時ディレクトリを作る

trap 'rm -rf "$TMP_DIR"' EXIT
# スクリプト終了時(正常・異常問わず)に一時ディレクトリを必ず削除する

git clone --depth=1 --filter=blob:none --sparse "$REPO_URL" "$TMP_DIR" -q
# --depth=1          : 最新コミットだけ取得(履歴は不要)
# --filter=blob:none : ファイルの中身(blob)はまだ取得しない=軽い
# --sparse           : sparse-checkout モードで取得する
# -q                 : 進捗ログを抑制する
# この時点では「どこにどんなディレクトリがあるか」の情報だけが手に入る(APIは使わない)

# --- 3. リポジトリ内の全ディレクトリを列挙する(中間ディレクトリも含む)---
DIRS=$(git -C "$TMP_DIR" ls-tree -r --name-only HEAD \
  | while IFS= read -r path; do
      dir=$(dirname "$path")
      # ファイルのパスを親へ1階層ずつたどり、全階層のディレクトリ名を出力する
      while [ "$dir" != "." ]; do
        echo "$dir"
        dir=$(dirname "$dir")
      done
    done \
  | sort -u)
# ls-tree -r : ファイルのパスを再帰的に全部出す(これだけだと末端しか出ない)
# dirname の繰り返しで .claude や .claude/skills のような中間ディレクトリも補う
# sort -u    : 重複を除いて並べる

# --- 4. ユーザーにディレクトリを選択させる ---
if command -v fzf > /dev/null 2>&1; then
  # fzf があればそれで選択(矢印で移動 / Enter で決定 / Esc でキャンセル)
  SELECTED=$(printf '%s\n' "$DIRS" \
    | fzf --header "取得するディレクトリを選択(矢印で移動 / Enter で決定)" \
          < /dev/tty) || SELECTED=""
  # < /dev/tty : curl|bash では stdin がスクリプト本体なので、入力は端末から直接読む
  # Esc 等でキャンセルすると fzf は非ゼロ終了するので || で空文字にして握りつぶす
else
  # fzf が無い場合は番号入力のフォールバック(動くが使いづらいので fzf 推奨)
  echo "fzf が見つかりません。インストールすると快適に選択できます:" >&2
  echo "  https://github.com/junegunn/fzf" >&2
  echo "" >&2
  echo "--- 取得可能なディレクトリ一覧 ---" >&2
  mapfile -t DIR_ARRAY <<< "$DIRS"
  # 改行区切りの一覧を配列に変換する
  for i in "${!DIR_ARRAY[@]}"; do
    printf "%3d) %s\n" "$((i+1))" "${DIR_ARRAY[$i]}" >&2
    # 番号付きで一覧表示(リストは stderr に出して、戻り値の stdout と混ざらないようにする)
  done
  printf "番号を入力: " >&2
  read -r num < /dev/tty
  # 端末から番号を読む
  [[ "$num" =~ ^[0-9]+$ ]] || { echo "番号が不正です" >&2; exit 1; }
  # 数字以外が入力されたらエラーにする
  SELECTED="${DIR_ARRAY[$((num-1))]:-}"
  # 入力番号に対応するパスを取り出す(範囲外なら空になる)
fi

[ -n "$SELECTED" ] || { echo "キャンセルしました" >&2; exit 0; }
# 何も選ばれなかったら正常終了する

# --- 5. すでにローカルに存在するなら何もしない ---
# リポジトリ内のパス = ローカルでの取得先パス(構造をそのまま鏡写しにする)
if [ -e "$SELECTED" ]; then
  echo "$SELECTED はすでに存在します"
  exit 0
fi

# --- 6. 取得してよいか最終確認する ---
printf "%s を取得しますか? [y/N]: " "$SELECTED"
read -r answer < /dev/tty
case "$answer" in
  [yY]) ;;                            # y か Y なら続行
  *) echo "中止しました"; exit 0 ;;    # それ以外は中止
esac

# --- 7. 選択したディレクトリの「実体」だけを取得する ---
git -C "$TMP_DIR" sparse-checkout set "$SELECTED"
# ここで初めて、対象ディレクトリのファイル本体がダウンロードされる

# --- 8. ローカルの同じパスへコピーする ---
mkdir -p "$(dirname "$SELECTED")"
# コピー先の親ディレクトリを用意する(cp は中間ディレクトリを自動では作らないため)
cp -r "$TMP_DIR/$SELECTED" "$SELECTED"
# 一時ディレクトリからローカルへコピー

# --- 9. git の管理対象外にする ---
echo "$SELECTED" >> .git/info/exclude
# .git/info/exclude に追記する
# .gitignore と同じ効果だが、このファイル自体は git 管理されない
# → リポジトリを汚さずにローカルだけで無視できる

echo "$SELECTED を取得しました"
