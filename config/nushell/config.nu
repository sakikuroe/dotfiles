# ~/.config/nushell/config.nu
#
# もし "自動 ls" が Nushell の hooks.pre_prompt に入っている場合は, ここを確認します.
# hooks.pre_prompt は "プロンプト表示直前" に実行されるため, ここに ls があると毎回 ls されます.
#
# 例: 次のような設定がある場合です.
#   $env.config = ($env.config | upsert hooks.pre_prompt [ {|| ls } ])
#
# ログイン時の Welcome バナーを表示しないようにします.
$env.config = ($env.config | upsert show_banner false)

# 補完メニューを `columnar` レイアウトへ明示的に切り替えます.
# 既定の `completion_menu` を上書きし, 今後の見た目調整もしやすくします.
# 既定の `completion_menu` と同名の設定を除外し, この後で差し込む定義だけを有効にします.
let configured_menus = ($env.config.menus? | default [] | where {|menu| $menu.name != "completion_menu" })
$env.config = ($env.config | upsert menus (
  $configured_menus ++ [{
    # 既定の補完メニューと同名にすることで, `Tab` 補完の見た目だけを差し替えます.
    name: completion_menu
    # 入力中のバッファー差分だけに絞らず, 候補一覧全体を表示します.
    only_buffer_difference: false
    # 選択中の候補を示す先頭マーカーです.
    marker: "| "
    type: {
      # 候補を複数列で並べる `columnar` 表示を採用します.
      layout: columnar
      # 一覧の列数と列幅を固定し, 候補数が増えても形が崩れにくいようにします.
      columns: 4
      col_width: 20
      col_padding: 2
    }
    style: {
      # 通常候補, 選択候補, 説明文の色を分けて視認性を確保します.
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
  }]
))

# `fish` が利用できる環境では, 外部コマンド補完を `fish` に委譲します.
# `fish` がない環境では, 既存の補完設定をそのまま使います.
if not ((which fish) | is-empty) {
  let fish_completer = {|spans|
    let escaped_spans = ($spans | str replace --all "'" "\\'" | str join " ")
    let fish_command = $"complete '--do-complete=($escaped_spans)'"

    fish --command $fish_command
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      let value = $row.value
      let needs_quote = (
        [' ' '[' ']' '(' ')' "'" '"' '`']
        | any {|char| $value | str contains $char }
      )

      if ($needs_quote and ($value | path exists)) {
        let expanded_path = if ($value | str starts-with "~") {
          $value | path expand --no-symlink
        } else {
          $value
        }
        $'"($expanded_path | str replace --all "\"" "\\\"")"'
      } else {
        $value
      }
    }
  }

  let external_completions = (
    $env.config.completions.external
    | upsert enable true
    | merge { completer: $fish_completer }
  )

  $env.config = ($env.config | upsert completions.external $external_completions)
}
#
# ls を停止するには, pre_prompt から ls の hook のみを除去します.
let pre_prompt_hooks = ($env.config.hooks.pre_prompt? | default [])
let filtered_hooks = ($pre_prompt_hooks | where {|hook|
  let hook_text = ($hook | to nuon --serialize | str trim | str replace '"' "")
  not ($hook_text =~ '^\{\|\|\s*ls(\s+[^}]*)?\s*\}$')
})
$env.config = ($env.config | upsert hooks.pre_prompt $filtered_hooks)
