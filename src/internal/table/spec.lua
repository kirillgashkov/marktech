local border = require("internal.table.border")
local alignment = require("internal.table.alignment")

local element = require("internal.element")
local merge = element.Merge

local spec = {}

---@param a "left" | "center" | "right" # Alignment.
---@param w length | nil # Width. Nil behaves like CSS's "max-width".
---@param b { L: length, R: length } # Border.
---@param config config
---@return Inline
function spec.MakeLatex(a, w, b, config)
  return merge({
    border.MakeVerticalLatex(b.L, config),
    alignment.MakeLatex(a, w, b),
    border.MakeVerticalLatex(b.R, config),
  })
end

---@param colAlignments List<"left" | "center" | "right">
---@param colWidths List<length | nil>
---@param colBorders List<{ L: length, R: length }>
---@param config config
---@return Inline
function spec.MakeAllLatex(colAlignments, colWidths, colBorders, config)
  local inlines = pandoc.Inlines({})
  for i = 1, #colAlignments do
    inlines:insert(spec.MakeLatex(colAlignments[i], colWidths[i], colBorders[i], config))
  end
  return merge(inlines)
end

return spec
