local M = {}

--- merges every content of table_b with table_a, and returns a new table
---
--- although this works for non-list tables, you should probably use
--- `vim.tbl_extend()` or `vim.tbl_deep_extend()`
---
--- when the table is not a list, the behavior of the merge depends on
--- the `behavior` parameter which differs like:
---
--- 1. force: overrides the item of table_a with the value of table_b
--- 2. keep: ignore repeated values from table_b keeping the original value
--- 3. error: error when a repeated key is found
---
--- the resulting table will contains entries from both table_a and table_b
---
--- @param behavior "force" | "keep" | "error"
--- @param table_a table
--- @param table_b table
function M.tbl_merge(behavior, table_a, table_b)
  local result = {}

  for key, value in pairs(table_a) do
    if type(key) == "number" then
      table.insert(result, value)
    else
      result[key] = value
    end
  end

  for key, value in pairs(table_b) do
    if type(key) == "number" then
      table.insert(result, value)
    else
      local has_key = result[key] ~= nil
      if has_key and behavior == "error" then
        error("duplicate key (" .. key .. ") on right side table")
      elseif has_key and behavior == "keep" then
        goto continue
      end
      result[key] = value
    end
    ::continue::
  end

  return result
end

--- returns a formatted string of today as YYYY-MM-DD
---
--- @return string
function M.today_str()
  local date = os.date("%Y-%m-%d")
  return date .. ""
end

return M
