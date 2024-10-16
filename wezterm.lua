local wezterm = require 'wezterm'
local act = wezterm.action

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  local colon = string.find(tab_info.active_pane.title, ':')

  return string.sub(tab_info.active_pane.title, colon + 2) -- .. ' '
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab_title(tab)
  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

local keymaps = require 'keys'

return {
  font = wezterm.font {
    family = 'Fira Code',
    harfbuzz_features = { 'ss03' },
  },
  color_scheme = 'Catppuccin Mocha',
  window_background_opacity = 0.85,
  -- Tabs
  tab_bar_at_bottom = true,
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = false,
  tab_max_width = 32,
  -- Key bindings
  keys = keymaps.keys,
  key_tables = keymaps.key_tables,
}
