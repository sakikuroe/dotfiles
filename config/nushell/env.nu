# ~/.config/nushell/env.nu
#
# 仕様:
#   1 行目: [HH:MM:SS] <pwd(~置換)> <git-branch(あれば)>
#   2 行目: >>> (入力インジケーター)

# PWD をホーム配下の場合は "~" に置換して返します.
def pretty_pwd [] {
  let home = $nu.home-dir
  let pwd  = $env.PWD
  let shown = if ($pwd | str starts-with $home) { $pwd | str replace $home "~" } else { $pwd }

  if ($shown == "~") {
    "~"
  } else if ($shown | str starts-with "~/") {
    let parts = ($shown | split row "/")
    let n = ($parts | length)
    if $n <= 2 {
      $shown
    } else {
      let head = ($parts | get 0)
      let tail = ($parts | last)
      let middle = ($parts
        | enumerate
        | where {|it| $it.index > 0 and $it.index < ($n - 1)}
        | get item
        | each {|seg|
          let chars = ($seg | split chars)
          if ($seg | str starts-with ".") and (($chars | length) > 1) {
            let c0 = ($chars | get 0)
            let c1 = ($chars | get 1)
            $"($c0)($c1)"
          } else {
            $chars | first
          }
        }
        | str join "/")
      if ($middle | is-empty) { $"($head)/($tail)" } else { $"($head)/($middle)/($tail)" }
    }
  } else {
    $shown
  }
}

# Git 情報を 1 ブロックで返します (repo 外では空文字です).
def git_block [] {
  let r = (^git status --porcelain=2 --branch | complete)
  if $r.exit_code != 0 {
    ""
  } else {
    let lines = ($r.stdout | lines)

    let head_lines = ($lines | where {|l| $l | str starts-with "# branch.head " })
    let branch = if ($head_lines | is-empty) {
      "unknown"
    } else {
      ($head_lines | first | str replace "# branch.head " "")
    }

    let ab_lines = ($lines | where {|l| $l | str starts-with "# branch.ab " })
    let ab_parts = if ($ab_lines | is-empty) {
      []
    } else {
      $ab_lines | first | split row " " | where {|x| not ($x | is-empty) }
    }
    let ahead = if (($ab_parts | length) > 2) { $ab_parts | get 2 | str replace "+" "" | into int } else { 0 }
    let behind = if (($ab_parts | length) > 3) { $ab_parts | get 3 | str replace "-" "" | into int } else { 0 }

    let tracked = ($lines | where {|l| ($l | str starts-with "1 ") or ($l | str starts-with "2 ") })
    let staged = ($tracked | where {|l|
      let cols = ($l | split row " " | where {|x| not ($x | is-empty) })
      let xy = if (($cols | length) > 1) { $cols | get 1 } else { ".." }
      let chars = ($xy | split chars)
      let x = if (($chars | length) > 0) { $chars | get 0 } else { "." }
      $x != "."
    } | length)
    let unstaged = ($tracked | where {|l|
      let cols = ($l | split row " " | where {|x| not ($x | is-empty) })
      let xy = if (($cols | length) > 1) { $cols | get 1 } else { ".." }
      let chars = ($xy | split chars)
      let y = if (($chars | length) > 1) { $chars | get 1 } else { "." }
      $y != "."
    } | length)
    let untracked = ($lines | where {|l| $l | str starts-with "? " } | length)
    let dirty = if ($staged + $unstaged + $untracked) > 0 { "*" } else { "" }
    let up_part = if $ahead == 0 { "" } else { $" | (ansi magenta)↑($ahead)(ansi reset)" }
    let down_part = if $behind == 0 { "" } else { $" | (ansi magenta)↓($behind)(ansi reset)" }
    let staged_part = if $staged == 0 { "" } else { $" | (ansi green)+($staged)(ansi reset)" }
    let unstaged_part = if $unstaged == 0 { "" } else { $" | (ansi red)~($unstaged)(ansi reset)" }
    let untracked_part = if $untracked == 0 { "" } else { $" | (ansi cyan)?($untracked)(ansi reset)" }

    $"[git (ansi yellow)($branch)($dirty)(ansi reset)($up_part)($down_part)($staged_part)($unstaged_part)($untracked_part)]"
  }
}

# プロンプト 1 行目を生成します (2 行目のために末尾へ改行を入れます).
def left_prompt [] {
  let t = (date now | format date "%Y-%m-%d %H:%M:%S%:z")
  let p = (pretty_pwd)
  let g = (git_block)

  let g_part = if ($g | is-empty) { "" } else { $" ($g)" }

  $"[(ansi cyan)($t)(ansi reset)] (ansi blue)($p)(ansi reset)($g_part)\n"
}

# プロンプト本体です (毎回評価されます).
$env.PROMPT_COMMAND = {|| left_prompt }

# 右側プロンプトは表示しません.
$env.PROMPT_COMMAND_RIGHT = {|| "" }

# 入力インジケーターです (2 行目です).
$env.PROMPT_INDICATOR = {|| ">>> " }

# 複数行入力時のインジケーターです.
$env.PROMPT_MULTILINE_INDICATOR = {|| "... " }
