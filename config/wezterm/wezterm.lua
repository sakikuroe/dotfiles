-- WezTerm の設定オブジェクトを初期化する.
local wezterm = require 'wezterm'
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- 起動するシェルの候補と表示名を定義する.
local shell_definitions = {
  nu = { label = 'nu (login shell)', args = { 'nu', '-l' } },
  bash = { label = 'bash (login shell)', args = { 'bash', '-l' } },
}
-- シェル候補の表示順を固定する.
local shell_order = { 'nu', 'bash' }
-- シェル選択ランチャーのタイトルを統一する.
local shell_selector_title = 'Select shell'

-- 新規タブや新規ペインで起動する既定のプログラムを設定する.
-- ここでは Nushell を既定にし, `exec nu -l` のようなコマンド文字列が画面に残る実装を避けます.
config.default_prog = shell_definitions.nu.args

-- ペイン作成時に表示するシェル選択肢を返す.
local function pane_shell_choices()
  local choices = {}
  for _, shell_id in ipairs(shell_order) do
    local definition = shell_definitions[shell_id]
    table.insert(choices, { id = shell_id, label = definition.label })
  end
  return choices
end

-- 選択したシェル ID から起動引数を返す.
local function pane_shell_args(shell_id)
  local definition = shell_definitions[shell_id]
  return definition and definition.args or nil
end

-- 新規タブ作成時のシェル候補を `shell_order` に従って生成します.
local function launch_menu_items()
  local items = {}
  for _, shell_id in ipairs(shell_order) do
    local definition = shell_definitions[shell_id]
    table.insert(items, { label = definition.label, args = definition.args })
  end
  return items
end

-- `InputSelector` によるシェル選択アクションを生成する.
local function shell_selector_action(on_selected)
  return wezterm.action.InputSelector {
    title = shell_selector_title,
    choices = pane_shell_choices(),
    action = wezterm.action_callback(function(window, pane, id, label)
      if not id then
        return
      end

      local args = pane_shell_args(id)
      if not args then
        return
      end

      on_selected(window, pane, args, id, label)
    end),
  }
end

-- ペイン分割時にシェルを選択するランチャーアクションを返す.
local function split_pane_with_shell_selector(direction)
  return shell_selector_action(function(_, pane, args)
    pane:split {
      direction = direction,
      args = args,
    }
  end)
end

-- GUI 起動時に最初のウィンドウを作成し, 初期ペインのシェルを選択させる.
-- 初期タブは `config.default_prog` (Nushell) で起動し, Bash を選択した場合は Bash タブを作成して入れ替えます.
wezterm.on('gui-startup', function(cmd)
  -- `wezterm start --cwd .` のように起動すると, `cmd` には `cwd` などの情報だけが入り, `args` が空のことがあります.
  -- その状態で `spawn_window(cmd)` すると, 起動するシェルが環境依存になり, Bash で起動したあとに
  -- `exec nu -l` で切り替えたような表示が残るケースがあります.
  -- ここでは, `args` が空のときは `default_prog` と同じ `nu -l` を明示し, 起動時の挙動を固定します.
  local spawn_cmd = cmd or {}
  if not spawn_cmd.args or #spawn_cmd.args == 0 then
    spawn_cmd.args = shell_definitions.nu.args
  end

  local _, pane, window = wezterm.mux.spawn_window(spawn_cmd)
  window:gui_window():perform_action(
    shell_selector_action(function(active_window, active_pane, args, id)
      if id == 'nu' then
        return
      end

      active_window:perform_action(
        wezterm.action.SpawnCommandInNewTab { args = args },
        active_pane
      )
      active_window:perform_action(
        wezterm.action.CloseCurrentTab { confirm = false },
        active_pane
      )
    end),
    pane
  )
end)

-- ウィンドウ外観を設定する.
-- タイトルバーとリサイズ枠を含むウィンドウ装飾を設定する.
config.window_decorations = 'RESIZE'
-- ウィンドウ背景の透過率を設定する.
-- 0.0 で完全に透過し, 1.0 で不透明になります.
config.window_background_opacity = 0.9
-- テキスト背景の透過率を設定する.
-- 0.0 で完全に透過し, 1.0 で不透明になります.
config.text_background_opacity = 0.9
-- ターミナルで使用するフォントを設定する.
config.font = wezterm.font 'Rounded Mgen+ 1m'
-- 端末表示領域の余白を設定する.
config.window_padding = { left = 8, right = 0, top = 0, bottom = 1 }
-- ペインの視認性を設定する.
-- ペイン境界線 (分割線) の色を設定する.
-- 色は `#RRGGBB` 形式で指定し, ここでは白 (#ffffff) にします.
config.colors = config.colors or {}
config.colors.split = '#ffffff'
-- 非アクティブなペインの見た目を調整し, アクティブなペインを判別しやすくします.
-- `inactive_pane_hsb` は, 非アクティブなペインにだけ適用される色補正 (HSB) です.
-- `saturation` は色の鮮やかさの倍率で, 1.0 は変化なし, 0.0 に近いほど灰色に寄ります.
-- `brightness` は明るさの倍率で, 1.0 は変化なし, 0.0 に近いほど暗くなります.
config.inactive_pane_hsb = { saturation = 0.5, brightness = 0.80 }

-- タブバーの表示と操作を設定する.
-- 装飾付きタブバーの有効 / 無効を設定する.
-- false の場合は, 余計な装飾を減らしたシンプルな表示になります.
config.use_fancy_tab_bar = false
-- タブ 1 つあたりの最大表示幅を設定する.
-- 単位は文字セルで, タブ名が長い場合はこの幅で省略されます.
config.tab_max_width = 100
-- マウスホイールによるタブ切り替えの有効 / 無効を設定する.
-- true の場合はタブ切り替えが優先され, false の場合はスクロールが優先されます.
config.mouse_wheel_scrolls_tabs = false

-- 通知の表示を設定する.
-- `notification_handling` は, 端末アプリケーションが通知 (デスクトップ通知など) を要求した場合の扱いを設定します.
-- ここでは通知を表示しないことで, 意図しないポップアップを防ぎます.
config.notification_handling = 'NeverShow'

-- 新規タブ作成時に選択できるシェル候補を設定する.
config.launch_menu = launch_menu_items()

-- キー操作を設定する.
config.keys = {
  -- Shift + LeftArrow で左のタブへ移動する操作を設定する.
  {
    key = 'LeftArrow',
    mods = 'SHIFT',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  -- Shift + RightArrow で右のタブへ移動する操作を設定する.
  {
    key = 'RightArrow',
    mods = 'SHIFT',
    action = wezterm.action.ActivateTabRelative(1),
  },
  -- Shift + Space で新規タブ作成用のシェル選択ランチャーを表示する操作を設定する.
  {
    key = 'Space',
    mods = 'SHIFT',
    action = wezterm.action.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS' },
  },
  -- Shift + Delete で現在のタブを閉じる操作を設定する.
  -- `confirm = true` の場合でも, タブ内プロセスが "bash" や "nu" など既定の
  -- `skip_close_confirmation_for_processes_named` に該当すると, 確認表示が省略される場合があります.
  {
    key = 'phys:Delete',
    mods = 'SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
}

-- Ctrl + Shift + Arrow でペイン分割ランチャーを表示する操作を設定する.
local split_pane_bindings = {
  { key = 'RightArrow', direction = 'Right' },
  { key = 'LeftArrow', direction = 'Left' },
  { key = 'UpArrow', direction = 'Top' },
  { key = 'DownArrow', direction = 'Bottom' },
}
for _, binding in ipairs(split_pane_bindings) do
  table.insert(config.keys, {
    key = binding.key,
    mods = 'CTRL|SHIFT',
    action = split_pane_with_shell_selector(binding.direction),
  })
end

-- Ctrl + S を無効化し, 誤操作による端末出力停止 (XOFF) を防ぐ操作を設定する.
-- この設定により, 端末内アプリケーションへ Ctrl + S が送られなくなります.
table.insert(config.keys, {
  key = 's',
  mods = 'CTRL',
  action = wezterm.action_callback(function(_, _)
    -- 意図的に何もしません.
  end),
})

-- Alt + Ctrl + Arrow でペインサイズを調整する操作を設定する.
local adjust_pane_size_bindings = {
  { key = 'LeftArrow', direction = 'Left' },
  { key = 'RightArrow', direction = 'Right' },
  { key = 'UpArrow', direction = 'Up' },
  { key = 'DownArrow', direction = 'Down' },
}
for _, binding in ipairs(adjust_pane_size_bindings) do
  table.insert(config.keys, {
    key = binding.key,
    mods = 'CTRL|ALT',
    action = wezterm.action.AdjustPaneSize { binding.direction, 1 },
  })
end

-- Ctrl + q で現在のペインを閉じる操作を設定する.
-- `confirm = true` の場合でも, ペイン内プロセスが "bash" や "nu" など既定の
-- `skip_close_confirmation_for_processes_named` に該当すると, 確認表示が省略される場合があります.
table.insert(config.keys, {
  key = 'q',
  mods = 'CTRL',
  action = wezterm.action.CloseCurrentPane { confirm = true },
})

-- ctrl + f で現在のペインのズーム表示を切り替える操作を設定する.
table.insert(config.keys, {
  key = 'f',
  mods = 'CTRL',
  action = wezterm.action.TogglePaneZoomState,
})

-- Ctrl + j でペイン選択のオーバーレイを表示する操作を設定する.
table.insert(config.keys, {
  key = 'j',
  mods = 'CTRL',
  -- ペイン上にラベルを表示し, 入力したラベルのペインへフォーカスを移動します. キャンセルは Esc です.
  action = wezterm.action.PaneSelect {
    alphabet = 'uijknm',
  },
})

-- スクロール周りを設定する.
-- スクロールバック履歴の保持行数を設定する.
-- 値を増やすと履歴が増えますが, メモリー使用量も増えます.
config.scrollback_lines = 10000
-- スクロールバー表示の有効 / 無効を設定する.
-- true の場合は, 右端にスクロールバーを表示します.
config.enable_scroll_bar = true

-- フォント描画の見た目を設定する.
-- HarfBuzz の字形置換 (合字, 文脈依存の置換) を無効化する.
-- `liga` は標準合字 (例: "fi" など), `clig` は文脈依存合字, `calt` は文脈依存の字形置換を表します.
-- これらを無効化することで, 記号の見た目が勝手に変わる状況を避け, 等幅表示の予測可能性を優先します.
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

return config
