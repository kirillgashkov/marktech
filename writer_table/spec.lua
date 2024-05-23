local border = require("writer_table.border")
local alignment = require("writer_table.alignment")

local spec = {}

---@param a "left" | "center" | "right" # Alignment.
---@param w number | nil # Width. Numbers are percentages. Nil behaves like CSS's "max-width".
---@param b { L: number, R: number } # Border. Numbers are in points.
---@param config config
---@return string
function spec.MakeColSpecLatex(a, w, b, config)
	return border.MakeVerticalBorderLatex(b.L, config)
		.. alignment.MakeColAlignmentLatex(a, w, b)
		.. border.MakeVerticalBorderLatex(b.R, config)
end

return spec
