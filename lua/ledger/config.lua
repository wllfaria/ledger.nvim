local M = {}

--- @class ledger.SnippetKeymaps
--- @field new_account string[]
--- @field new_posting string[]
--- @field new_posting_today string[]
--- @field new_commodity string[]

--- @class ledger.ReportKeymap
--- @field name string
--- @field key string
--- @field command string

--- @class ledger.Keymaps
--- @field snippets ledger.SnippetKeymaps
--- @field reports ledger.ReportKeymap[]

--- @class ledger.PartialKeymaps
--- @field snippets? ledger.SnippetKeymaps
--- @field reports? ledger.ReportKeymap[]

--- @class ledger.CompletionSource
--- @field enabled boolean

--- @class ledger.SnippetSource
--- @field enabled boolean

--- @class ledger.Completion
--- @field cmp ledger.CompletionSource

--- @class ledger.Snippet
--- @field native ledger.SnippetSource
--- @field luasnip ledger.SnippetSource
--- @field cmp ledger.SnippetSource

--- @class ledger.PartialConfig
--- @field extensions string[]?
--- @field completion ledger.Completion?
--- @field snippets ledger.Snippet?
--- @field keymaps ledger.PartialKeymaps?
--- @field diagnostics ledger.Diagnostics?

--- @class ledger.Diagnostics
--- @field lsp_diagnostics boolean
--- @field strict boolean

--- @class ledger.Config
--- @field extensions string[]
--- @field default_ignored_paths string[]
--- @field completion ledger.Completion
--- @field snippets ledger.Snippet
--- @field keymaps ledger.Keymaps
--- @field diagnostics ledger.Diagnostics
local LedgerConfig = {}
LedgerConfig.__index = LedgerConfig

--- @type ledger.Config
local instance = nil

--- @class ledger.Snippet
local LedgerConfigSnippets = {}
LedgerConfigSnippets.__index = LedgerConfigSnippets

--- @class ledger.Completion
local LedgerConfigCompletion = {}
LedgerConfigCompletion.__index = LedgerConfigCompletion

--- @class ledger.Diagnostics
local LedgerConfigDiagnostics = {}
LedgerConfigDiagnostics.__index = LedgerConfigDiagnostics

--- @class ledger.

--- checks if any of the completion providers are enabled and return
--- true/false
---
--- @return boolean
function LedgerConfigCompletion:is_enabled()
  if self.cmp.enabled then
    return true
  end
  return false
end

--- checks if any of the existing snippet providers are available and
--- return true/false
---
--- @return boolean
function LedgerConfigSnippets:is_enabled()
  if self.native.enabled then
    return true
  elseif self.luasnip.enabled then
    return true
  elseif self.cmp.enabled then
    return true
  end
  return false
end

--- checks if any of the existing snippet providers are available and
--- return true/false
---
--- @return boolean
function LedgerConfigDiagnostics:is_enabled()
  if self.lsp_diagnostics then
    return true
  end
  return false
end

function LedgerConfig.__tostring()
  return "<LedgerConfig>"
end

--- @return ledger.Config
local function get_default_config()
  --- @type ledger.Config
  local default_config = {
    extensions = {
      "ledger",
      "hledger",
      "journal",
    },
    completion = setmetatable({
      cmp = { enabled = true },
    }, LedgerConfigCompletion),
    default_ignored_paths = {
      ".git",
    },
    diagnostics = setmetatable({
      lsp_diagnostics = true,
      strict = false,
    }, LedgerConfigDiagnostics),
    snippets = setmetatable({
      native = { enabled = false },
      cmp = { enabled = true },
      luasnip = { enabled = false },
    }, LedgerConfigSnippets),
    keymaps = {
      snippets = {
        new_posting = { "tt" },
        new_account = { "acc" },
        new_posting_today = { "td" },
        new_commodity = { "cm" },
      },
      reports = {},
    },
  }

  return default_config
end

--- set keymaps for running reports
function LedgerConfig:set_keymaps()
  local commands = require("ledger.commands").setup()
  for _, keymap in pairs(self.keymaps.reports) do
    vim.keymap.set("n", keymap.key, function()
      commands:run_report(keymap.command)
    end)
  end
end

--- Config is a singleton, allowing us to call `get` as many times as we
--- want and always getting the same instance, so we don't have to pass
--- the table around
---
--- @param overrides? ledger.PartialConfig
--- @return ledger.Config
function M.setup(overrides)
  if not instance then
    local default = get_default_config()
    local with_overrides = vim.tbl_deep_extend("force", default, overrides or {})

    setmetatable(with_overrides.snippets, LedgerConfigSnippets)
    setmetatable(with_overrides.completion, LedgerConfigCompletion)
    setmetatable(with_overrides.diagnostics, LedgerConfigDiagnostics)

    instance = setmetatable(with_overrides, LedgerConfig)
    instance:set_keymaps()
  end
  return instance
end

function M.get()
  return instance
end

return M
