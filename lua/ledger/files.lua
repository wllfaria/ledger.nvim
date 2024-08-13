local M = {}

--- @param path string
--- @return boolean
function M.is_ledger(path)
  local config = require("ledger.config").setup()
  local has_match = false
  for _, extension in pairs(config.extensions) do
    if has_match then goto continue end
    has_match = path:match(extension) ~= nil and true or false
  end
  ::continue::
  return has_match
end

function M.is_directory()
  local a = ""
  return a
end

--- Reads a directory recursively, adding every file defined in the config
--- `extensions` entry into a map of file names to file path. returning the
--- map of files at the end, eg:
---
--- ```lua
--- { ["filename.ledger"] = "/path/to/filename.ledger" }
--- ```
---
--- @param path string
--- @return table<string, string>
function M.read_dir_rec(path)
  local map = {}

  local recurse = function(_path, acc)
    local ok, entries = pcall(vim.fn.readdir, _path)
    if not ok then return end
  end

  recurse(path, map)

  return map
end

--- reads every line from a path `filename` and returns
--- a tuple of `ok` and `lines`, where ok is true if the
--- file exists and could be read
---
--- @param filename string
--- @return boolean, string[]?
function M.read_file(filename)
  local ok, lines = pcall(vim.fn.readfile, filename)
  if not ok then return false, nil end
  return true, lines
end

--- reads every entry on the given path and returns true when
--- a valid ledger extension was found or false otherwise. This
--- will also return false if the path is invalid.
---
--- @param path string
--- @return boolean
function M.has_ledger_file(path)
  local ok, entries = pcall(vim.fn.readdir, path)
  if not ok then return false end

  for _, entry in ipairs(entries) do
    if M.is_ledger(entry) then return true end
  end

  return false
end

M.has_ledger_file(vim.fn.getcwd())

return M
