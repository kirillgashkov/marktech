---@param pa Alignment
---@return "left" | "center" | "right" | nil
local function getAlignment(pa)
	local a

	if pa == "AlignDefault" then
		a = nil
	elseif pa == "AlignLeft" then
		a = "left"
	elseif pa == "AlignCenter" then
		a = "center"
	elseif pa == "AlignRight" then
		a = "right"
	else
		assert(false)
	end

	return a
end

---@param colSpecs List<ColSpec>
---@return List<"left" | "center" | "right">
local function makeColAlignments(colSpecs)
	local alignments = pandoc.List({})

	for _, colSpec in ipairs(colSpecs) do
		local colSpecAlignment = colSpec[1]
		alignments:insert(getAlignment(colSpecAlignment) or "left")
	end

	return alignments
end

---@param alignment "left" | "center" | "right"
---@return RawInline
local function makeMaxWidthAlignmentLatex(alignment)
	if alignment == "left" then
		return pandoc.RawInline("latex", "l")
	elseif alignment == "center" then
		return pandoc.RawInline("latex", "c")
	elseif alignment == "right" then
		return pandoc.RawInline("latex", "r")
	else
		assert(false)
	end
end

---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return RawInline
local function makeNumberWidthAlignmentLatex(alignment, width, border)
	local raggedOrCenteringLatex
	if alignment == "left" then
		raggedOrCenteringLatex = "\\raggedright"
	elseif alignment == "center" then
		raggedOrCenteringLatex = "\\centering"
	elseif alignment == "right" then
		raggedOrCenteringLatex = "\\raggedleft"
	else
		assert(false)
	end

	return pandoc.RawInline(
		"latex",
		(
			">{"
			.. raggedOrCenteringLatex
			.. "\\arraybackslash"
			.. "}"
			.. "p{"
			.. makeWidthLatexString(width, border)
			.. "}"
		)
	)
end

---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return RawInline
local function makeAlignmentLatex(alignment, width, border)
	local latex
	if width == "max-width" then
		latex = makeMaxWidthAlignmentLatex(alignment)
	elseif type(width) == "number" then
		latex = makeNumberWidthAlignmentLatex(alignment, width, border)
	else
		assert(false)
	end
	return latex
end
