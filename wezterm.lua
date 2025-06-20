local wezterm = require 'wezterm'

local keymaps = require 'keys'

local project = require 'custom.project'

-- This is here because calling *glob in a 'require'd file causes bugs for some reason
table.insert(keymaps.keys, { key = 'n', mods = 'SHIFT|CTRL', action = project.choose_project() })

require 'event.format-tab-title'
require 'event.update-status'
require 'event.session'

return {
  font = wezterm.font_with_fallback {
    { family = 'Fira Code', harfbuzz_features = { 'ss03' } },
    { family = 'Noto Sans Mono CJK JP' },
    { family = 'YuGothic' },
  },
  font_size = 16,
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
