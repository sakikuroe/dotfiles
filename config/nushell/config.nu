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
