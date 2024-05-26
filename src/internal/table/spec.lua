local border = require("internal.table.border")
local alignment = require("internal.table.alignment")

local spec = {}

---@param a "left" | "center" | "right" # Alignment.
---@param w length | nil # Width. Nil behaves like CSS's "max-width".
---@param b { L: length, R: length } # Border.
---@param config config
---@return string
function spec.MakeColSpecLatex(a, w, b, config)
	return border.MakeVerticalBorderLatex(b.L, config)
		.. alignment.MakeColAlignmentLatex(a, w, b)
		.. border.MakeVerticalBorderLatex(b.R, config)
end

return spec
