--- JS-like map over a table
--- @param table table
--- @param func function
---@return table
local map = function(table, func)
  local new_list = {}
  for i, v in pairs(table) do
    new_list[i] = func(v)
  end
  return new_list
end

--- Shallow copies a table
--- @param table table
---@return table
local shallow_copy = function(table)
  local new_copy = {}
  for k, v in pairs(table) do
    new_copy[k] = v
  end

  return new_copy
end

return {
  map = map,
  shallow_copy = shallow_copy,
}
