-- I'm not sure if Pandoc allows mixing default and non-default column widths but we do. One of our filters surely
-- generates such tables. Also these widths account for borders, similar to CSS's "box-sizing: border-box".
---@param colSpecs List<ColSpec>
---@param source string|nil
---@return List<"max-width" | number>
local function makeColWidths(colSpecs, source)
	local widths = pandoc.List({})

	for _, colSpec in ipairs(colSpecs) do
		local colSpecWidth = colSpec[2]
		if colSpecWidth == "ColWidthDefault" then
			widths:insert("max-width")
		else
			assert(type(colSpecWidth) == "number")
			widths:insert(colSpecWidth)
		end
	end

	local totalPercentageWidth = 0
	for i = 1, #widths do
		totalPercentageWidth = totalPercentageWidth + widths[i]
	end
	if totalPercentageWidth > 1 then
		log.Warning("the table has a total column width greater than 100%", source)
	end

	return widths
end

---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return string | nil
local function makeWidthLatexString(width, border)
	if width == "max-width" then
		return nil
	elseif type(width) == "number" then
		return fun.Reduce(
			function(a, b)
				return a .. b
			end,
			fun.Flatten({
				fun.Flatten({
					{ "(" },
					fun.Flatten({
						{ "\\real{" },
						{ string.format("%.4f", width) },
						{ "}" },
					}),
					{ " * " },
					{ "\\columnwidth" },
					{ ")" },
				}),
				{ " - " },
				{ makeBorderWidthLatexString((border.L or 0) + (border.R or 0)) },
			}),
			""
		)
	else
		assert(false)
	end
end
