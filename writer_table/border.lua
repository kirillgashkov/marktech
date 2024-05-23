---@param innerWidth number
---@param outerWidth number
---@param firstTop "inner" | "outer" | nil
---@param lastBottom "inner" | "outer" | nil
---@param rowCount integer
---@return List<{ T: number | nil, B: number | nil }>
local function makeRowBorders(innerWidth, outerWidth, firstTop, lastBottom, rowCount)
	local borders = pandoc.List({})
	for i = 1, rowCount do
		if i == 1 then
			if firstTop == "inner" then
				borders:insert({ T = innerWidth })
			elseif firstTop == "outer" then
				borders:insert({ T = outerWidth })
			elseif firstTop == nil then
				borders:insert({})
			else
				assert(false)
			end
		elseif i == rowCount then
			if lastBottom == "inner" then
				borders:insert({ B = innerWidth })
			elseif lastBottom == "outer" then
				borders:insert({ B = outerWidth })
			elseif lastBottom == nil then
				borders:insert({})
			else
				assert(false)
			end
		else
			borders:insert({ T = innerWidth })
		end
	end
	return borders
end

---@param innerWidth number
---@param outerWidth number
---@param colCount integer
---@return List<{ L: number | nil, R: number | nil }>
local function makeColBorders(innerWidth, outerWidth, colCount)
	local borders = pandoc.List({})
	for i = 1, colCount do
		if i == 1 then
			borders:insert({ L = outerWidth })
		elseif i == colCount then
			borders:insert({ R = outerWidth })
		else
			borders:insert({ L = innerWidth })
		end
	end
	return borders
end

---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@param colCount integer
---@return { T: List<{ Width: number | nil, Length: integer }>, B: List<{ Width: number | nil, Length: integer }> }
local function getRowBorderSegments(y, t, colCount)
	---@type { T: List<{ Width: number | nil, Length: integer }>, B: List<{ Width: number | nil, Length: integer }> }
	local rBorderSegments = { T = pandoc.List({}), B = pandoc.List({}) }

	local rBorderSegment = { T = { Width = nil, Length = 0 }, B = { Width = nil, Length = 0 } }

	for x = 1, colCount do
		---@type { T: number | nil, B: number | nil }
		local cBorder = { T = nil, B = nil }

		local c = t[y][x]
		if c.Type == "contentCell" then
			---@cast c contentCell
			cBorder.T = c.Border.T or nil

			if c.RowSpan == 1 then
				cBorder.B = c.Border.B or nil
			end
		elseif c.Type == "mergeCell" then
			---@cast c mergeCell

			local ofC = t[c.Of.Y][c.Of.X]
			assert(ofC.Type == "contentCell")
			---@cast ofC contentCell

			if y == c.Of.Y then
				cBorder.T = ofC.Border.T or nil
			elseif y == c.Of.Y + ofC.RowSpan - 1 then
				cBorder.B = ofC.Border.B or nil
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
	rBorderSegment.T = { Width = nil, Length = 0 }

	if rBorderSegment.B.Length > 0 then
		rBorderSegments.B:insert(rBorderSegment.B)
	end
	rBorderSegment.B = { Width = nil, Length = 0 }

	return rBorderSegments
end

---@param borderWidth number
---@return string
local function makeBorderWidthLatexString(borderWidth)
	return string.format("%.4f", borderWidth) .. "pt"
end

---@param borderWidth number
---@return RawInline
local function makeVerticalBorderLatex(borderWidth)
	return pandoc.RawInline("latex", "!{\\vrule width " .. makeBorderWidthLatexString(borderWidth) .. "}")
end

---@param borderWidth number
---@param startX? integer | nil
---@param endX? integer | nil
---@param source string|nil
---@return RawInline
local function makeHorizontalBorderLatex(borderWidth, startX, endX, source)
	if startX ~= nil or endX ~= nil then
		log.Warning("the table has a partial horizontal border due to spans which is not supported yet", source)
	end
	return pandoc.RawInline("latex", "\\specialrule{" .. makeBorderWidthLatexString(borderWidth) .. "}{0pt}{0pt}")
end
