local log = require("log")

---@param innerWidth number
---@param outerWidth number
---@param firstTop "inner" | "outer" | "none"
---@param lastBottom "inner" | "outer" | "none"
---@param rowCount integer
---@return List<{ T: number, B: number }>
local function makeRowBorders(innerWidth, outerWidth, firstTop, lastBottom, rowCount)
	local borders = pandoc.List({})
	for i = 1, rowCount do
		if i == 1 then
			if firstTop == "inner" then
				borders:insert({ T = innerWidth, B = 0 })
			elseif firstTop == "outer" then
				borders:insert({ T = outerWidth, B = 0 })
			elseif firstTop == "none" then
				borders:insert({ T = 0, B = 0 })
			else
				assert(false)
			end
		elseif i == rowCount then
			if lastBottom == "inner" then
				borders:insert({ T = 0, B = innerWidth })
			elseif lastBottom == "outer" then
				borders:insert({ T = 0, B = outerWidth })
			elseif lastBottom == "none" then
				borders:insert({ T = 0, B = 0 })
			else
				assert(false)
			end
		else
			borders:insert({ T = innerWidth, B = 0 })
		end
	end
	return borders
end

---@param innerWidth number
---@param outerWidth number
---@param colCount integer
---@return List<{ L: number, R: number }>
local function makeColBorders(innerWidth, outerWidth, colCount)
	local borders = pandoc.List({})
	for i = 1, colCount do
		if i == 1 then
			borders:insert({ L = outerWidth, R = 0 })
		elseif i == colCount then
			borders:insert({ L = 0, R = outerWidth })
		else
			borders:insert({ L = innerWidth, R = 0 })
		end
	end
	return borders
end

---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@param colCount integer
---@return { T: List<{ Width: number, Length: integer }>, B: List<{ Width: number, Length: integer }> }
local function getRowBorderSegments(y, t, colCount)
	---@type { T: List<{ Width: number, Length: integer }>, B: List<{ Width: number, Length: integer }> }
	local rBorderSegments = { T = pandoc.List({}), B = pandoc.List({}) }

	local rBorderSegment = { T = { Width = 0, Length = 0 }, B = { Width = 0, Length = 0 } }

	for x = 1, colCount do
		local cBorder = { T = 0, B = 0 }

		local c = t[y][x]
		if c.Type == "contentCell" then
			---@cast c contentCell

			cBorder.T = c.Border.T
			if c.RowSpan == 1 then
				cBorder.B = c.Border.B
			end
		elseif c.Type == "mergeCell" then
			---@cast c mergeCell

			local ofC = t[c.Of.Y][c.Of.X]
			assert(ofC.Type == "contentCell")
			---@cast ofC contentCell

			if y == c.Of.Y then
				cBorder.T = ofC.Border.T
			elseif y == c.Of.Y + ofC.RowSpan - 1 then
				cBorder.B = ofC.Border.B
			end
		else
			assert(false)
		end

		if cBorder.T == rBorderSegment.T.Width then
			rBorderSegment.T.Length = rBorderSegment.T.Length + 1
		else
			if rBorderSegment.T.Length > 0 then
				rBorderSegments.T:insert(rBorderSegment.T)
			end
			rBorderSegment.T = { Width = cBorder.T, Length = 1 }
		end

		if cBorder.B == rBorderSegment.B.Width then
			rBorderSegment.B.Length = rBorderSegment.B.Length + 1
		else
			if rBorderSegment.B.Length > 0 then
				rBorderSegments.B:insert(rBorderSegment.B)
			end
			rBorderSegment.B = { Width = cBorder.B, Length = 1 }
		end
	end

	if rBorderSegment.T.Length > 0 then
		rBorderSegments.T:insert(rBorderSegment.T)
	end
	rBorderSegment.T = { Width = 0, Length = 0 }

	if rBorderSegment.B.Length > 0 then
		rBorderSegments.B:insert(rBorderSegment.B)
	end
	rBorderSegment.B = { Width = 0, Length = 0 }

	return rBorderSegments
end

---@param w number
---@return string
local function makeBorderWidthLatexString(w)
	return string.format("%.4f", w) .. "pt"
end

---@param w number
---@param config config
---@return string
local function makeVerticalBorderLatexString(w, config)
	if w == 0 then
		return ""
	elseif w == config.arrayRuleWidth then
		return "|"
	else
		return "!{\\vrule width " .. makeBorderWidthLatexString(w) .. "}"
	end
end

---@param widthSegments List<{ Width: number, Length: integer }>
---@param source string|nil
---@param config config
---@return string
local function makeHorizontalBorderSegmentsLatexString(widthSegments, source, config)
	local s = ""

	local x = 1
	for _, w in ipairs(widthSegments) do
		if w.Width == 0 then
			x = x + w.Length
		else
			if w.Width ~= config.arrayRuleWidth then
				log.Error("the table has a segmented horizontal border with unsupported width", source)
				log.Note("use width " .. makeBorderWidthLatexString(config.arrayRuleWidth) .. " instead", source)
			end
			local x1, x2 = x, x + w.Length - 1
			s = s .. "\\cline{" .. x1 .. "-" .. x2 .. "}"
			x = x2 + 1
		end
	end

	return s
end

---@param widthSegments List<{ Width: number, Length: integer }>
---@param source string|nil
---@param config config
---@return string
local function makeHorizontalBorderLatexString(widthSegments, source, config)
	if #widthSegments == 0 then
		return ""
	end

	if #widthSegments == 1 then
		local w = widthSegments[1].Width

		if w == 0 then
			return ""
		elseif w == config.arrayRuleWidth then
			return "\\hline"
		else
			return "\\specialrule{" .. makeBorderWidthLatexString(w) .. "}{0pt}{0pt}"
		end
	end

	return makeHorizontalBorderSegmentsLatexString(widthSegments, source, config)
end
