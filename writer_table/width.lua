local log = require("log")
local utility = require("writer_table.utility")

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

---@param w number # Percentage.
---@param colBorder { L: number, R: number }
---@return string
function width.MakeColWidthLatex(w, colBorder)
	return utility.makePercentWidthLatex(w) .. " - " .. utility.MakeFixedWidthLatex(colBorder.L + colBorder.R)
end

return width
