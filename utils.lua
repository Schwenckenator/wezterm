local M = {}

--- JS-like map over a table
--- @param table table
--- @param func function
---@return table
function M.map(table, func)
  local new_list = {}
  for i, v in pairs(table) do
    new_list[i] = func(v)
  end
  return new_list
end

--- JS-like filter of table
--- @param tbl table
--- @param func function(value, index)
--- @return table
function M.filter(tbl, func)
  local new_list = {}
  for i, v in ipairs(tbl) do
    if func(v, i) then
      table.insert(new_list, v)
    end
  end
  return new_list
end

--- Shallow copies a table
--- @param table table
---@return table
function M.shallow_copy(table)
  local new_copy = {}
  for k, v in pairs(table) do
    new_copy[k] = v
  end

  return new_copy
end

return M
