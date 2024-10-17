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

return {
  map = map,
}
