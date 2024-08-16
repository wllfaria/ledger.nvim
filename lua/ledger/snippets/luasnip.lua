local ok, ls = pcall(require, "luasnip")

local M = {
  snippets = {},
}

--- Converts from our default snippet template to a luasnip valid snippet
---
--- @param trigger string
--- @param template ledger.SnippetTemplate[]
function M.template_to_luasnip(trigger, template)
  local s = ls.snippet
  local fmt = require("luasnip.extras.fmt").fmt
  local i = ls.insert_node

  local snippet = {}
  local nodes = {}
  local placeholder_counter = 1

  for _, entry in ipairs(template) do
    -- insert the pre text into the snippet template
    table.insert(snippet, entry.pre)

    if entry.insert then
      -- when the snippet is a insert node, we add a placeholder to the
      -- template and include a new insert node into nodes with the text
      -- to be used as placeholder
      table.insert(snippet, "{}")
      table.insert(nodes, i(placeholder_counter, entry.text))
      placeholder_counter = placeholder_counter + 1
    else
      -- when its just a text node we add the text to the snippet as is
      table.insert(snippet, entry.text)
    end

    -- insert the post text into the snippet template
    table.insert(snippet, entry.post)
  end

  return s(trigger, fmt(table.concat(snippet), nodes))
end

--- Setup the luasnip integration by creating and registering all
--- the available snippets
---
--- @param snippets ledger.SnippetList
function M.setup(snippets)
  if not ok then
    return
  end

  for _, snippet in pairs(snippets) do
    for _, trigger in pairs(snippet.triggers) do
      table.insert(M.snippets, M.template_to_luasnip(trigger, snippet.template))
    end
  end

  ls.add_snippets("ledger", M.snippets)
end

return M
