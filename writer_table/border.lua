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
