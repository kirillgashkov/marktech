local log = require("internal.log")
local utility = require("internal.table.utility")

local width = {}

-- I'm not sure if Pandoc allows mixing default and non-default column widths but we do. One of our filters surely
-- generates such tables. Also these widths account for borders, similar to CSS's "box-sizing: border-box".
---@param colSpecs List<ColSpec>
---@param source string|nil
---@return List<number | nil>
function width.MakeColWidths(colSpecs, source)
	---@type List<number | nil>
	local widths = pandoc.List({})

	for _, colSpec in ipairs(colSpecs) do
		local w = colSpec[2]

		if w == "ColWidthDefault" then
			widths:insert(nil)
		elseif type(w) == "number" then
			widths:insert(w)
		else
			assert(false)
		end
	end

	local total = 0
	for i = 1, #widths do
		total = total + (widths[i] or 0)
	end
	if total > 1 then
		log.Warning("the table has a total column width greater than 100%", source)
	end

	return widths
end

---@param w number # Width. Numbers are percentages. Nil behaves like CSS's "max-width".
---@param b { L: number, R: number } # Border. Numbers are in points.
---@return string
function width.MakeColWidthLatex(w, b)
	return utility.makePercentWidthLatex(w) .. " - " .. utility.MakeFixedWidthLatex(b.L + b.R)
end

return width
