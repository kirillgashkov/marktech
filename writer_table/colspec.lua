---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return Inlines
local function makeColSpecLatex(alignment, width, border)
	return pandoc.Inlines(fun.Flatten({
		border.L and { makeVerticalBorderLatex(border.L) } or {},
		{ makeAlignmentLatex(alignment, width, border) },
		border.R and { makeVerticalBorderLatex(border.R) } or {},
	}))
end
