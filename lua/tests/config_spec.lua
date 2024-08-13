describe("Ledger Config", function()
  it("should only instantiate config once", function()
    local first = require("ledger.config").setup({ extensions = { "lol" } })
    local second = require("ledger.config").setup({ extensions = { "another value" } })

    assert.are_same(first, second)
  end)
end)
