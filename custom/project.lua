local wezterm = require 'wezterm'
local util = require 'utils'

M = {}

local project_list = {
  wezterm.home_dir,
  wezterm.home_dir .. '/.config/nvim',
  wezterm.home_dir .. '/.config/wezterm',
}

local project_dirs = {
  wezterm.home_dir .. '/projects',
  wezterm.home_dir .. '/projects/godot',
  wezterm.home_dir .. '/projects/nvim-plugins',
  wezterm.home_dir .. '/Documents/Godot',
  wezterm.home_dir .. '/Documents/GitHub',
}

local function get_git_dirs()
  local projects = util.shallow_copy(project_list)
  for _, project_dir in ipairs(project_dirs) do
    for _, dir in ipairs(wezterm.glob(project_dir .. '/*')) do
      -- ... and add them to the projects table.
      table.insert(projects, dir)
    end
  end

  return projects
end

function M.select_project()
  return wezterm.action_callback(function(window, pane)
    local projects = {}
    for _, value in ipairs(get_git_dirs()) do
      table.insert(projects, { id = value, label = value:gsub(wezterm.home_dir, '~') })
    end

    window:perform_action(
      wezterm.action.InputSelector {
        title = 'Choose Project',
        fuzzy = true,
        choices = projects,
        action = wezterm.action_callback(function(child_window, child_pane, id, label)
          -- "label" may be empty if nothing was selected. Don't bother doing anything
          -- when that happens.
          if not id then
            return
          end

          -- The SwitchToWorkspace action will switch us to a workspace if it already exists,
          -- otherwise it will create it for us.
          child_window:perform_action(
            wezterm.action.SwitchToWorkspace {
              -- We'll give our new workspace a nice name, like the last path segment
              -- of the directory we're opening up.
              name = id:match '([^/]+)$',
              -- Here's the meat. We'll spawn a new terminal with the current working
              -- directory set to the directory that was picked.
              spawn = { cwd = id },
            },
            child_pane
          )
          -- Restores session if it exists
          child_window:perform_action(wezterm.action { EmitEvent = 'auto_restore_session' }, child_pane)
        end),
      },
      pane
    )
  end)
end

return M
