local wezterm = require 'wezterm'

wezterm.on('update-status', function(window, pane)
  local active_workspace = window:active_workspace()
  if active_workspace == 'default' then
    -- Don't show if default
    window:set_left_status ''
    return
  end
  window:set_left_status(' ' .. active_workspace .. ': ')
end)
