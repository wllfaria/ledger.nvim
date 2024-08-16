local M = {}

--- Converts from our default snippet template to a valid builtin snippet
---
--- @param template ledger.SnippetTemplate[]
function M.template_to_builtin(template)
  local result = {}
  local placeholder_counter = 1

  for _, entry in ipairs(template) do
    -- add the pre text
    table.insert(result, entry.pre)

    if entry.insert then
      -- create a placeholder for builtin snippets like ${1:Label} or ${1}
      -- when there is no label
      if entry.text and #entry.text > 0 then
        table.insert(result, string.format("${%d:%s}", placeholder_counter, entry.text))
      else
        table.insert(result, string.format("${%d}", placeholder_counter))
      end
      placeholder_counter = placeholder_counter + 1
    else
      -- add the static text or placeholder, if any
      table.insert(result, entry.text)
    end

    -- Add post text
    table.insert(result, entry.post)
  end

  return table.concat(result)
end

return M
