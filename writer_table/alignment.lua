local width = require("writer_table.width")

local alignment = {}

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
function alignment.MakeColAlignments(colSpecs)
	local alignments = pandoc.List({})

	for _, colSpec in ipairs(colSpecs) do
		local colSpecAlignment = colSpec[1]
		alignments:insert(getAlignment(colSpecAlignment) or "left")
	end

	return alignments
end

---@param a "left" | "center" | "right"
---@return string
local function makeMaxWidthColAlignmentLatexString(a)
	local s

	if a == "left" then
		s = "l"
	elseif a == "center" then
		s = "c"
	elseif a == "right" then
		s = "r"
	else
		assert(false)
	end

	return s
end

---@param a "left" | "center" | "right" # Alignment.
---@param w number # Width.
---@param b { L: number, R: number } # Border.
---@return string
local function makeWidthColAlignmentLatex(a, w, b)
	local m
	if a == "left" then
		m = "\\raggedright"
	elseif a == "center" then
		m = "\\centering"
	elseif a == "right" then
		m = "\\raggedleft"
	else
		assert(false)
	end

	return (">{" .. m .. "\\arraybackslash" .. "}" .. "p{" .. width.MakeColWidthLatex(w, b) .. "}")
end

---@param a "left" | "center" | "right" # Alignment.
---@param w number | nil # Width. Numbers are percentages. Nil behaves like CSS's "max-width".
---@param b { L: number, R: number } # Border. Numbers are in points.
---@return string
function alignment.MakeColAlignmentLatex(a, w, b)
	local s

	if type(w) == "number" then
		s = makeWidthColAlignmentLatex(a, w, b)
	elseif w == nil then
		s = makeMaxWidthColAlignmentLatexString(a)
	else
		assert(false)
	end

	return s
end

return alignment
