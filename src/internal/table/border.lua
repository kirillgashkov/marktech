local log = require("internal.log")
local length = require("internal.table.length")

local border = {}

---@param innerWidth length
---@param outerWidth length
---@param firstTop "inner" | "outer" | "none"
---@param lastBottom "inner" | "outer" | "none"
---@param rowCount integer
---@return List<{ T: length, B: length }>
function border.MakeRowBorders(innerWidth, outerWidth, firstTop, lastBottom, rowCount)
	local borders = pandoc.List({})
	for i = 1, rowCount do
		if i == 1 then
			if firstTop == "inner" then
				borders:insert({ T = innerWidth, B = length.Zero() })
			elseif firstTop == "outer" then
				borders:insert({ T = outerWidth, B = length.Zero() })
			elseif firstTop == "none" then
				borders:insert({ T = length.Zero(), B = length.Zero() })
			else
				assert(false)
			end
		elseif i == rowCount then
			if lastBottom == "inner" then
				borders:insert({ T = length.Zero(), B = innerWidth })
			elseif lastBottom == "outer" then
				borders:insert({ T = length.Zero(), B = outerWidth })
			elseif lastBottom == "none" then
				borders:insert({ T = length.Zero(), B = length.Zero() })
			else
				assert(false)
			end
		else
			borders:insert({ T = innerWidth, B = length.Zero() })
		end
	end
	return borders
end

---@param innerWidth length
---@param outerWidth length
---@param colCount integer
---@return List<{ L: length, R: length }>
function border.MakeColBorders(innerWidth, outerWidth, colCount)
	local borders = pandoc.List({})
	for i = 1, colCount do
		if i == 1 then
			borders:insert({ L = outerWidth, R = length.Zero() })
		elseif i == colCount then
			borders:insert({ L = length.Zero(), R = outerWidth })
		else
			borders:insert({ L = innerWidth, R = length.Zero() })
		end
	end
	return borders
end

---@param b "T" | "B"
---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@return List<{ Width: length, Length: integer }>
local function getSegmentsForRowBorder(b, y, t)
	local segments = pandoc.List({})

	local segment = { Width = length.Zero(), Length = 0 }

	for x = 1, #t[y] do
		local cBorder = { T = length.Zero(), B = length.Zero() }

		local c = t[y][x]
		if c.Type == "contentCell" then
			---@cast c contentCell

			cBorder = {
				T = c.Border.T,
				B = c.RowSpan == 1 and c.Border.B or length.Zero(),
			}
		elseif c.Type == "mergeCell" then
			---@cast c mergeCell

			local ofC = t[c.Of.Y][c.Of.X]
			assert(ofC.Type == "contentCell")
			---@cast ofC contentCell

			cBorder = {
				T = y == c.Of.Y and ofC.Border.T or length.Zero(),
				B = y == c.Of.Y + ofC.RowSpan - 1 and ofC.Border.B or length.Zero(),
			}
		else
			assert(false)
		end

		if cBorder[b] == segment.Width then
			segment.Length = segment.Length + 1
		else
			if segment.Length > 0 then
				segments:insert(segment)
			end
			segment = { Width = cBorder[b], Length = 1 }
		end
	end

	if segment.Length > 0 then
		segments:insert(segment)
	end
	segment = { Width = length.Zero(), Length = 0 }

	return segments
end

---@param segments List<{ Width: length, Length: integer }>
---@param source string|nil
---@param config config
---@return string
local function makeHorizontalBorderSegmentsLatex(segments, source, config)
	local s = ""

	local x = 1
	for _, w in ipairs(segments) do
		if length.IsZero(w.Width) then
			x = x + w.Length
		else
			if not length.IsEqual(w.Width, config.arrayRuleWidth) then
				log.Error("the table has a segment of a horizontal border with unsupported width", source)
				log.Note("use width " .. length.MakeLengthLatex(config.arrayRuleWidth) .. " instead", source)
			end
			local x1, x2 = x, x + w.Length - 1
			s = s .. "\\cline{" .. x1 .. "-" .. x2 .. "}"
			x = x2 + 1
		end
	end

	return s
end

---@param w length
---@param config config
---@return string
function border.MakeVerticalBorderLatex(w, config)
	if length.IsZero(w) then
		return ""
	elseif length.IsEqual(w, config.arrayRuleWidth) then
		return "|"
	else
		return "!{\\vrule width " .. length.MakeLengthLatex(w) .. "}"
	end
end

---@param b "T" | "B"
---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@param source string|nil
---@param config config
---@return string
function border.MakeHorizontalBorderLatexForRowBorder(b, y, t, source, config)
	local segments = getSegmentsForRowBorder(b, y, t)

	if #segments == 0 then
		return ""
	end

	if #segments == 1 then
		local w = segments[1].Width

		if length.IsZero(w) then
			return ""
		elseif length.IsEqual(w, config.arrayRuleWidth) then
			return "\\hline"
		else
			return "\\specialrule{" .. length.MakeLengthLatex(w) .. "}{0pt}{0pt}"
		end
	end

	return makeHorizontalBorderSegmentsLatex(segments, source, config)
end

return border
