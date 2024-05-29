assert(tostring(PANDOC_API_VERSION) == "1.23.1", "Unsupported Pandoc API")

local file = require("internal.file")
local element = require("internal.element")
local table_ = require("writer.internal.table.table")

---@param d pandoc.Pandoc
---@param options pandoc.WriterOptions
---@return string
function Writer(d, options)
  d = d:walk({
    ---@param t pandoc.Table
    ---@return pandoc.Block
    Table = function(t)
      return table_.MakeLatex(t)
    end,
  })
  d = element.RemoveMerges(d)
  d = element.RemoveSources(d)
  d = element.RemoveRedundants(d)

  if options.variables["template_debug"] ~= nil and options.variables["template_debug"]:render() == "1" then
    io.stderr:write(pandoc.write(d, "native", options))
  end
  options.columns = 10000
  return pandoc.write(d, {
    format = "latex",
    extensions = {
      auto_identifiers = false,
      latex_macros = false,
      smart = true,
      task_lists = true,
    },
  }, options)
end

---@return string
function Template()
  local scriptDir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
  local templateFile = pandoc.path.join({ scriptDir, "template.tex" })
  local template = file.Read(templateFile)
  assert(template ~= nil)
  return template
end

---@type { [string]: boolean }
Extensions = {}
