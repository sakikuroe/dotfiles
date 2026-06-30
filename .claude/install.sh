#!/bin/bash
# GitHubリポジトリ内の任意のディレクトリ・ファイルを、ローカルの同じパスに取得するスクリプト
set -euo pipefail
# set -e          : コマンドが失敗したらスクリプト全体を即座に終了する
# set -u          : 未定義の変数を使おうとしたらエラーにする
# set -o pipefail : パイプ(|)の途中でエラーが起きても検知する

# --- 0. 取得元リポジトリを引数で受け取る(必須・既定値なし)---
[ $# -ge 1 ] || {
  echo "error: 取得元リポジトリのURLを引数で指定すること" >&2
  echo "  例: curl -fsSL <script-url> | bash -s -- https://github.com/user/repo.git" >&2
  exit 1
}
# $#         : スクリプトに渡された引数の個数
# -ge 1      : 1個以上か確認。0個なら使い方を表示して異常終了する
REPO_URL="$1"
# 第1引数を取得元リポジトリとして使う

# --- 1. 開発リポジトリのルートで実行されているか確認 ---
[ -d .git ] || { echo "error: .git not found(リポジトリのルートで実行すること)" >&2; exit 1; }
# [ -d .git ] : カレントディレクトリに .git があるか確認
# なければエラーを出して異常終了する

# --- 2. リポジトリの「構造」だけを取得する(ファイル本体はまだ落とさない)---
TMP_DIR=$(mktemp -d)
# 作業用の一時ディレクトリを作る

trap 'rm -rf "$TMP_DIR"' EXIT
# スクリプト終了時(正常・異常問わず)に一時ディレクトリを必ず削除する

git clone --depth=1 --filter=blob:none --no-checkout "$REPO_URL" "$TMP_DIR" -q
# --depth=1          : 最新コミットだけ取得(履歴は不要)
# --filter=blob:none : ファイルの中身(blob)はまだ取得しない=軽い
# --no-checkout      : チェックアウトを行わない(ルート直下のファイルも含め、この時点では実体を取得しない)
# -q                 : 進捗ログを抑制する
# この時点では「どこにどんなディレクトリ・ファイルがあるか」の情報だけが手に入る(APIは使わない)

# --- 3. ユーザーに取得するディレクトリ・ファイルを選択させる ---
if command -v fzf > /dev/null 2>&1; then
  # fzf があれば、リポジトリ内の全ディレクトリ・ファイルを一覧から選択できる
  ENTRIES=$(git -C "$TMP_DIR" ls-tree -r --name-only HEAD \
    | while IFS= read -r path; do
        echo "$path"
        dir="$path"
        # ファイルのパスを親へ1階層ずつたどり、全階層のディレクトリ名も出力する
        while [[ "$dir" == */* ]]; do
          dir="${dir%/*}"
          echo "$dir"
        done
      done \
    | sort -u)
  # ls-tree -r : ファイルのパスを再帰的に全部出す
  # ${dir%/*}  : dirname 相当の処理を外部プロセスなしで行う(大規模リポジトリでも速い)
  # sort -u    : 重複を除いて並べる

  SELECTED=$(printf '%s\n' "$ENTRIES" \
    | fzf --header "取得するディレクトリ・ファイルを選択(矢印で移動 / Enter で決定)") || SELECTED=""
  # fzf はリストをパイプから受け取り、UI操作は内部で /dev/tty を使う
  # ここで < /dev/tty を付けるとパイプ入力が上書きされ、リストが渡らなくなる
  # Esc 等でキャンセルすると fzf は非ゼロ終了するので || で空文字にして握りつぶす
else
  # fzf が無い場合は、リポジトリ全体の一覧を出さず、GitHub 上で開いたページの URL を貼ってもらう
  # (大規模リポジトリでは全件一覧が膨大になり、列挙にも選択にも実用的でないため)
  echo "fzf が見つからない。インストールすると一覧から選択できる:" >&2
  echo "  https://github.com/junegunn/fzf" >&2
  echo "" >&2
  echo "取得したいディレクトリ・ファイルを GitHub 上で開き、そのページの URL を貼り付けること。" >&2
  printf "URL (空入力でキャンセル): "
  read -r url < /dev/tty
  # 端末から URL を読む

  if [ -z "$url" ]; then
    SELECTED=""
  else
    BRANCH=$(git -C "$TMP_DIR" branch --show-current)
    # クローンした既定ブランチ名(URL の /tree/<branch>/ や /blob/<branch>/ と一致させるために使う)
    case "$url" in
      */tree/"$BRANCH"/*) SELECTED="${url#*/tree/"$BRANCH"/}" ;;
      */blob/"$BRANCH"/*) SELECTED="${url#*/blob/"$BRANCH"/}" ;;
      # https://github.com/<owner>/<repo>/(tree|blob)/<branch>/<path> から <path> を取り出す
      # tree はディレクトリ、blob はファイルのページ URL
      *) echo "error: URL からパスを取り出せなかった(branch: $BRANCH)" >&2; exit 1 ;;
    esac
    SELECTED="${SELECTED%/}"
    # 末尾の / を除去する

    TYPE=$(git -C "$TMP_DIR" cat-file -t "HEAD:$SELECTED" 2>/dev/null) \
      || { echo "error: リポジトリ内に見つからない: $SELECTED" >&2; exit 1; }
    case "$TYPE" in
      tree|blob) ;;
      *) echo "error: 取得できない種類のパスである: $SELECTED ($TYPE)" >&2; exit 1 ;;
    esac
    # 取り出したパスがリポジトリ内のディレクトリ・ファイルとして実在するか確認する
  fi
fi

[ -n "$SELECTED" ] || { echo "キャンセルした" >&2; exit 0; }
# 何も選ばれなかったら正常終了する

# --- 4. すでにローカルに存在するなら何もしない ---
# リポジトリ内のパス = ローカルでの取得先パス(構造をそのまま鏡写しにする)
if [ -e "$SELECTED" ]; then
  echo "$SELECTED はすでに存在する"
  exit 0
fi

# --- 5. 取得してよいか最終確認する ---
printf "%s を取得するか? [y/N]: " "$SELECTED"
read -r answer < /dev/tty
case "$answer" in
  [yY]) ;;                            # y か Y なら続行
  *) echo "中止した"; exit 0 ;;    # それ以外は中止
esac

# --- 6. 選択したパスの「実体」だけを取得する ---
git -C "$TMP_DIR" sparse-checkout set --no-cone "/$SELECTED"
# --no-cone : ディレクトリ・ファイルどちらも指定できるパターンとして扱う
# 先頭の / : リポジトリルートからの完全一致に固定する(同名パスへの誤マッチを防ぐ)

git -C "$TMP_DIR" checkout -q
# --no-checkout で省略していたチェックアウトをここで行う
# ここで初めて、対象のファイル本体がダウンロードされる

# --- 7. ローカルの同じパスへコピーする ---
mkdir -p "$(dirname "$SELECTED")"
# コピー先の親ディレクトリを用意する(cp は中間ディレクトリを自動では作らないため)
cp -r "$TMP_DIR/$SELECTED" "$SELECTED"
# 一時ディレクトリからローカルへコピー

# --- 8. git の管理対象外にする ---
echo "$SELECTED" >> .git/info/exclude
# .git/info/exclude に追記する
# .gitignore と同じ効果だが、このファイル自体は git 管理されない
# → リポジトリを汚さずにローカルだけで無視できる

echo "$SELECTED を取得した"
