# ~/.config/nushell/config.nu
#
# もし "自動 ls" が Nushell の hooks.pre_prompt に入っている場合は, ここを確認します.
# hooks.pre_prompt は "プロンプト表示直前" に実行されるため, ここに ls があると毎回 ls されます.
#
# 例: 次のような設定がある場合です.
#   $env.config = ($env.config | upsert hooks.pre_prompt [ {|| ls } ])
#
# ls を停止するには, pre_prompt から ls の hook のみを除去します.
let pre_prompt_hooks = ($env.config.hooks.pre_prompt? | default [])
let filtered_hooks = ($pre_prompt_hooks | where {|hook|
  let hook_text = ($hook | to nuon --serialize | str trim | str replace '"' "")
  not ($hook_text =~ '^\{\|\|\s*ls(\s+[^}]*)?\s*\}$')
})
$env.config = ($env.config | upsert hooks.pre_prompt $filtered_hooks)
