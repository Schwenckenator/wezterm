local wezterm = require 'wezterm'
local act = wezterm.action

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
--- comment
--- @param tab_info {tab_id: unknown, tab_index: number, is_active: boolean, active_pane: any, window_id: unknown, window_title: string, tab_title: string}
--- @return string
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  local colon = string.find(tab_info.active_pane.title, ':')

  if colon == nil then
    return tab_info.active_pane.title
  end

  return string.sub(tab_info.active_pane.title, colon + 2) -- .. ' '
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab_title(tab)
  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

wezterm.on('update-status', function(window, pane)
  local active_workspace = window:active_workspace()
  if active_workspace == 'default' then
    -- Don't show if default
    window:set_left_status ''
    return
  end
  window:set_left_status(' ' .. active_workspace .. ': ')
end)

local keymaps = require 'keys'

local project = require 'custom.project'

table.insert(keymaps.keys, { key = 'n', mods = 'ALT', action = project.choose_project() })

return {
  font = wezterm.font_with_fallback {
    { family = 'Fira Code', harfbuzz_features = { 'ss03' } },
    { family = 'Noto Sans Mono CJK JP' },
    { family = 'YuGothic' },
  },
  color_scheme = 'Catppuccin Mocha',
  window_background_opacity = 0.85,
  -- Tabs
  tab_bar_at_bottom = true,
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = false,
  tab_max_width = 32,
  -- Key bindings
  leader = keymaps.leader,
  keys = keymaps.keys,
  key_tables = keymaps.key_tables,
}
