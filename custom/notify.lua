local wezterm = require 'wezterm'

local M = {
  notification = '',
}

function M.notify(message, timeout)
  timeout = timeout or 4000

  M.notification = message
  wezterm.sleep_ms(timeout)
  M.notification = ''
end

return M
