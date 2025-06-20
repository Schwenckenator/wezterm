-- [[
-- Session Saver
--
-- This module saves workspace tabs, panes, tab titles and cwds
-- It won't save running programs, I prefer to start those up manually
-- ]]

local wezterm = require 'wezterm' -- [[@as Wezterm]]
local os = wezterm.target_triple
local M = {}

local function get_state_file_path(name)
  return wezterm.config_dir .. '/.session_data/state_' .. name .. '.json'
end

local function display_notification(window, message)
  wezterm.log_info(message)

  -- Gui can be added here?
  -- window:toast_notification('Session Saver', message, nil, 4000)
end

local function retrieve_workspace_data(window)
  local workspace_name = window:active_workspace()
  local workspace_data = {
    name = workspace_name,
    active_tab = 1,
    tabs = {},
  }

  -- Iterate over tabs
  for _, tab in ipairs(window:mux_window():tabs()) do
    local tab_data = {
      tab_id = tostring(tab:tab_id()),
      tab_title = tostring(tab:get_title()),
      panes = {},
    }
    -- > Iterate over panes in tab
    for _, pane_info in ipairs(tab:panes_with_info()) do
      -- Collect pane details, including layout and process information
      table.insert(tab_data.panes, {
        pane_id = tostring(pane_info.pane:pane_id()),
        index = pane_info.index,
        is_active = pane_info.is_active,
        is_zoomed = pane_info.is_zoomed,
        left = pane_info.left,
        top = pane_info.top,
        width = pane_info.width,
        height = pane_info.height,
        pixel_width = pane_info.pixel_width,
        pixel_height = pane_info.pixel_height,
        cwd = tostring(pane_info.pane:get_current_working_dir()),
        tty = tostring(pane_info.pane:get_foreground_process_name()),
      })
    end

    table.insert(workspace_data.tabs, tab_data)
  end

  return workspace_data
end

local function save_to_json_file(data, file_path)
  if not data then
    wezterm.log_info 'No workspace data to save'
    return false
  end

  local file = io.open(file_path, 'w')
  if file then
    file:write(wezterm.json_encode(data))
    file:close()
    return true
  else
    return false
  end
end

---Recreates the workspace based on the provided data
---@param workspace_data table
local function recreate_workspace(window, workspace_data)
  -- Transforms general file paths into workable paths?
  local function extract_path_from_dir(working_directory)
    if os == 'x86_64-pc-windows-msvc' then
      -- On windows, transform 'file:///C:/path/to/dir' to 'C:/path/to/dir'
      return working_directory:gsub('file:///', '')
    elseif os == 'x86_64-unknown-linux-gnu' then
      -- On linux, transform 'file://{computer-name}/home/{user}/path/to/dir' to '/home/{user}/path/to/dir'
      return working_directory:gsub('^.*(/home/)', '/home/')
    else
      return working_directory:gsub('^.*(/Users/)', '/Users/')
    end
  end

  -- Checks if workspace data is empty
  if not workspace_data or not workspace_data.tabs then
    wezterm.log_info 'Invalid or empty workspace data provided'
    return
  end

  local tabs = window:mux_window():tabs()

  -- Only restore state if there is
  -- *1* tab with *1* pane
  if #tabs ~= 1 or #tabs[1]:panes() ~= 1 then
    wezterm.log_info 'Restoration can only be performed in a window with a single tab and a single pane, to prevent accidental data loss'
    return
  end

  local initial_pane = window:active_pane()
  local foreground_process = initial_pane:get_foreground_process_name()

  -- Check if the foreground process is a shell
  -- NOTE: *nix shells only! (I don't use windows, haha!)
  if
    foreground_process:find 'sh'
    or foreground_process:find 'cmd.exe'
    or foreground_process:find 'powershell.exe'
    or foreground_process:find 'pwsh.exe'
    or foreground_process:find 'nu'
  then
    -- Safe to close
    initial_pane:send_text 'exit\r'
  else
    wezterm.log_info 'Active program detected. Skipping exit command for initial pane.'
  end

  -- Recreate tabs and panes from the saved state
  for _, tab_data in ipairs(workspace_data.tabs) do
    -- local cwd_uri = tab_data.panes[1].cwd
    -- local cwd_path = extract_path_from_dir(cwd_uri)
    -- NOTE: Just condense it because I don't need it?
    local cwd_path = extract_path_from_dir(tab_data.panes[1].cwd)

    local new_tab = window:mux_window():spawn_tab { cwd = cwd_path }
    if not new_tab then
      wezterm.log_info('Failed to create a new tab for: ' .. cwd_path)
      break
    end

    -- Activate the new tab before creating panes
    new_tab:activate()
    -- Restore its title
    new_tab:set_title(tab_data.tab_title)

    -- Recreate panes within this tab
    for i, pane_data in ipairs(tab_data.panes) do
      local new_pane
      if i == 1 then
        new_pane = new_tab:active_pane()
      else
        local direction = 'Right'
        if pane_data.left == tab_data.panes[i - 1].left then
          direction = 'Bottom'
        end

        new_pane = new_tab:active_pane():split {
          direction = direction,
          cwd = extract_path_from_dir(pane_data.cwd),
        }
      end

      if not new_pane then
        wezterm.log_info 'Failed to create a new pane'
        break
      end

      -- Just copied this, I don't need to understand it
      -- If it breaks, I'll just comment it
      -- Restore TTY for Neovim on Linux
      -- NOTE: cwd is handled differently on windows. maybe extend functionality for windows later
      -- This could probably be handled better in general
      if not (os == 'x86_64-pc-windows-msvc') then
        -- Only neovim gets launched, all other programs just get shot into the sun
        if not (os == 'x86_64-pc-windows-msvc') and pane_data.tty:sub(-#'/bin/nvim') == '/bin/nvim' then
          new_pane:send_text(pane_data.tty .. ' .' .. '\n')
          -- elseif not pane_data.tty:find 'sh' then
          --   -- TODO - With running npm commands (e.g a running web client) this seems to execute Node, without the arguments
          --   new_pane:send_text(pane_data.tty .. '\n')
        end
      end
    end
  end

  tabs = window:mux_window():tabs()
  local active_tab = tabs[workspace_data.active_tab]
  if active_tab then
    tabs[workspace_data.active_tab]:activate()
  else
    wezterm.log_info 'Failed to activate tab, Active tab is invalid'
  end

  wezterm.log_info 'Workspace created with new tabs and panes based on saved state.'
  return true
end

local function load_from_json_file(file_path)
  local file = io.open(file_path, 'r')
  if not file then
    wezterm.log_info('Failed to open file: ' .. file_path)
    return nil
  end

  local file_content = file:read '*a'
  file:close()

  local data = wezterm.json_parse(file_content)
  if not data then
    wezterm.log_info('Failed to parse JSON data from file: ' .. file_path)
  end
  return data
end

-- [[
-- PUBLIC METHODS
-- ]]

function M.restore_state(window)
  -- Only restore data if the workspace is clean
  -- 1 tab, 1 pane, and nothing running in said tab
  local tabs = window:mux_window():tabs()

  -- Only restore state if there is
  -- *1* tab with *1* pane
  if #tabs ~= 1 or #tabs[1]:panes() ~= 1 then
    wezterm.log_info 'Shortcut!'
    wezterm.log_info 'Restoration can only be performed in a window with a single tab and a single pane, to prevent accidental data loss'
    return
  end

  local initial_pane = window:active_pane()
  local foreground_process = initial_pane:get_foreground_process_name()

  if not foreground_process:find 'sh' then
    wezterm.log_info 'Shortcut!'
    wezterm.log_info 'Active program detected. Restoration can only be performed on a bare shell'
    return
  end

  local workspace_name = window:active_workspace()
  local file_path = get_state_file_path(workspace_name)

  local workspace_data = load_from_json_file(file_path)
  if not workspace_data then
    display_notification(window, 'Workspace state file not found for workspace: ' .. workspace_name)
    -- window:toast_notification('Session', 'Workspace state file not found for workspace: ' .. workspace_name, nil, 4000)
    return
  end

  if recreate_workspace(window, workspace_data) then
    display_notification(window, 'Workspace state loaded for workspace: ' .. workspace_name)
  else
    display_notification(window, 'Failed to load state for workspace: ' .. workspace_name)
  end
end

function M.load_state(window)
  -- TODO Copied from here: https://github.com/danielcopper/wezterm-session-manager/blob/main/session-manager.lua#L209
  -- Not implemented there either
end

function M.save_state(window)
  local data = retrieve_workspace_data(window)

  -- Construct the file path based on the workspace name
  -- local file_path = wezterm.config_dir .. '/.session_data/state_' .. data.name .. '.json'
  local file_path = get_state_file_path(data.name)

  if save_to_json_file(data, file_path) then
    display_notification(window, 'Workspace state saved successfully')
    -- window:toast_notification('Session', 'Workspace state saved successfully', nil, 4000)
  else
    display_notification(window, 'Failed to save workspace state')
    -- window:toast_notification('Session', 'Failed to save workspace state', nil, 4000)
  end
end

return M
