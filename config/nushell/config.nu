# ~/.config/nushell/config.nu
#
# もし "自動 ls" が Nushell の hooks.pre_prompt に入っている場合は, ここを確認します.
# hooks.pre_prompt は "プロンプト表示直前" に実行されるため, ここに ls があると毎回 ls されます.
#
# 例: 次のような設定がある場合です.
#   $env.config = ($env.config | upsert hooks.pre_prompt [ {|| ls } ])
#
# ls を停止するには pre_prompt を空にします (他にも入れている場合は ls のみ除去します).
$env.config = ($env.config | upsert hooks.pre_prompt [])
