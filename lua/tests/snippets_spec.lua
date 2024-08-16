local luasnip = require("ledger.snippets.luasnip")
local native = require("ledger.snippets.native")

local template = {
  { pre = "", text = "YYYY-MM-DD", insert = true, post = " " },
  { pre = "", text = "*", insert = true, post = " " },
  { pre = "", text = "Payee", insert = true, post = "\n" },
  { pre = "\t", text = "Account", insert = true, post = "" },
}

describe("snippets", function()
  it("converts from common format to a valid vim.snippet.expand format", function()
    local expected = "${1:YYYY-MM-DD} ${2:*} ${3:Payee}\n\t${4:Account}"

    local result = native.template_to_builtin(template)

    assert.are.same(result, expected)
  end)

  it("converts from common format to a valid luasnip format", function()
    assert.is.not_nil(luasnip.template_to_luasnip("tt", template))
  end)
end)
