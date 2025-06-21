local wezterm = require 'wezterm'
local u = require 'utils'

local M = {}

function M.kill(workspace)
  local success, stdout = wezterm.run_child_process { 'wezterm', 'cli', 'list', '--format=json' }

  if success then
    local json = wezterm.json_parse(stdout)
    if not json then
      return
    end

    local workspace_panes = u.filter(json, function(p)
      return p.workspace == workspace
    end)

    for _, p in ipairs(workspace_panes) do
      wezterm.run_child_process {
        'wezterm',
        'cli',
        'kill-pane',
        '--pane-id=' .. p.pane_id,
      }
    end
  end
end

return M
