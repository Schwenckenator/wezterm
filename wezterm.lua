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

-- local current_workspace = 'default'
-- wezterm.on('window-focus-changed', function(window, pane)
--   current_workspace = window:active_workspace()
-- end)

-- wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
--   local zoomed = ''
--   if tab.active_pane.is_zoomed then
--     zoomed = '[Z]'
--   end
--   local index = ''
--   if #tabs > 1 then
--     index = string.format('[%d/%d]', tab.tab_index + 1, #tabs)
--   end
--   return current_workspace
--   -- return zoomed .. index .. tab.active_pane.title
-- end)

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

local project_dirs = {
  wezterm.home_dir .. '/projects',
  wezterm.home_dir .. '/Documents/Godot',
  wezterm.home_dir .. '/Documents/GitHub',
}

local function get_git_dirs()
  local projects = { wezterm.home_dir }
  for _, project_dir in ipairs(project_dirs) do
    for _, dir in ipairs(wezterm.glob(project_dir .. '/*')) do
      -- ... and add them to the projects table.
      table.insert(projects, dir)
    end
  end

  return projects
end

local function choose_project()
  local function get_choices()
    local choices = {}
    for _, value in ipairs(get_git_dirs()) do
      table.insert(choices, { label = value })
    end

    return choices
  end

  return wezterm.action.InputSelector {
    title = 'Projects',
    choices = get_choices(),
    fuzzy = true,
    action = wezterm.action_callback(function(child_window, child_pane, id, label)
      -- "label" may be empty if nothing was selected. Don't bother doing anything
      -- when that happens.
      if not label then
        return
      end

      -- The SwitchToWorkspace action will switch us to a workspace if it already exists,
      -- otherwise it will create it for us.
      child_window:perform_action(
        wezterm.action.SwitchToWorkspace {
          -- We'll give our new workspace a nice name, like the last path segment
          -- of the directory we're opening up.
          name = label:match '([^/]+)$',
          -- Here's the meat. We'll spawn a new terminal with the current working
          -- directory set to the directory that was picked.
          spawn = { cwd = label },
        },
        child_pane
      )
    end),
  }
end

table.insert(keymaps.keys, { key = 'n', mods = 'ALT', action = choose_project() })

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
