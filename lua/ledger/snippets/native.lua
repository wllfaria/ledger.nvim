local template_converter = require("ledger.snippets.template_converter")

local M = {}

--- Setup snippets to use the builtin neovim snippet expansion
--- we use the user defined triggers to set keymaps for each snippet
--- that can be used
---
--- @param snippets ledger.SnippetList
function M.setup(snippets)
  for _, snippet in pairs(snippets) do
    for _, trigger in pairs(snippet.triggers) do
      local snippet_text = template_converter.template_to_builtin(snippet.template)
      vim.keymap.set("i", trigger, function()
        vim.snippet.expand(snippet_text)
      end)
    end
  end
end

return M
