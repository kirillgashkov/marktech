local border = require("writer.internal.table.border")
local alignment = require("writer.internal.table.alignment")

local element = require("internal.element")
local merge = element.Merge

local spec = {}

---@param a "left" | "center" | "right" # Alignment.
---@param w length | "max-content" # Width.
---@param b { L: length, R: length } # Border.
---@return Inline
function spec.MakeLatex(a, w, b)
  return merge({
    border.MakeVerticalLatex(b.L),
    alignment.MakeLatex(a, w, b),
    border.MakeVerticalLatex(b.R),
  })
end

---@param colAlignments List<"left" | "center" | "right">
---@param colWidths List<length | "max-content">
---@param colBorders List<{ L: length, R: length }>
---@return Inline
function spec.MakeAllLatex(colAlignments, colWidths, colBorders)
  local inlines = pandoc.Inlines({})
  for i = 1, #colAlignments do
    inlines:insert(spec.MakeLatex(colAlignments[i], colWidths[i], colBorders[i]))
  end
  return merge(inlines)
end

return spec
