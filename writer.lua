local file = require("file")
local fun = require("fun")
local log = require("log")

assert(tostring(PANDOC_API_VERSION) == "1.23.1", "Unsupported Pandoc API")

local filter = {}

---@param attr Attr
---@return string|nil
local function getSource(attr)
	return attr.attributes["data-pos"]
end

---@param cell Cell
---@return boolean
local function isMultirow(cell)
	return cell.row_span > 1
end

---@param content Inlines # Used instead of blocks_to_inlines(cell.contents).
---@param cell Cell
---@param colSpec ColSpec
---@return Inlines
local function makeMultirow(content, cell, colSpec)
	return pandoc.Inlines(fun.Flatten({
		{ pandoc.RawInline("latex", "\\multirow") },
		{ pandoc.RawInline("latex", "{" .. tostring(cell.row_span) .. "}") },
		{ pandoc.RawInline("latex", "{" .. "..." .. "}") }, -- FIXME: E.g. "{4em}"
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			content,
			{ pandoc.RawInline("latex", "}") },
		}),
	}))
end

---@param cell Cell
---@return boolean
local function isMulticol(cell)
	return cell.col_span > 1 or cell.alignment ~= "AlignDefault"
end

---@param content Inlines # Used instead of blocks_to_inlines(cell.contents).
---@param cell Cell
---@param colSpec ColSpec
---@return Inlines
local function makeMulticol(content, cell, colSpec)
	return pandoc.Inlines(fun.Flatten({
		{ pandoc.RawInline("latex", "\\multicol") },
		{ pandoc.RawInline("latex", "{" .. tostring(cell.col_span) .. "}") },
		{ pandoc.RawInline("latex", "{" .. "..." .. "}") }, -- FIXME: E.g. "{|l|}"
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			content,
			{ pandoc.RawInline("latex", "}") },
		}),
	}))
end

---@class cell_
---@field Type "cell"
---@field Cell Cell
---@class mergeCell_
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@param rows List<Row>
---@param rowCount integer
---@param colCount integer
---@param source string|nil
local function makeRows(rows, rowCount, colCount, source)
	---@type List<List<cell_ | mergeCell_ | nil>>
	local t = pandoc.List({})
	for y = 1, rowCount do
		local r = pandoc.List({})
		for x = 1, colCount do
			r:insert(nil)
		end
		t:insert(r)
	end

	for y = 1, rowCount do
		local cellIndex = 1
		for x = 1, colCount do
			if t[y][x] == nil then
				local cell = rows[y].cells[cellIndex]

				for y_offset = 0, cell.row_span do
					for x_offset = 0, cell.col_span do
						if t[y + y_offset][x + x_offset] ~= nil then
							log.Error("the table has overlapping spans", getSource(cell.attr))
							assert(false)
						end

						local c
						if y_offset == 0 and x_offset == 0 then
							---@type cell_
							c = { Type = "cell", Cell = cell }
						else
							---@type mergeCell_
							c = { Type = "mergeCell", Of = { X = x, Y = y } }
						end
						t[y + y_offset][x + x_offset] = c
					end
				end

				cellIndex = cellIndex + 1
			end
		end
	end

	---@type List<List<Inlines>>
	local inlinesCellsRows = pandoc.List({})
	for y = 1, rowCount do
		---@type List<Inlines>
		local inlinesCells = pandoc.List({})
		for x = 1, colCount do
			if t[y][x] == nil then
				log.Error("the table is incomplete", source)
				assert(false)
			end

			if t[y][x].Type == "cell" then
				---@type any
				local c = t[y][x]
				---@type cell_
				c = c

				local inlinesCell = pandoc.utils.blocks_to_inlines(c.Cell.contents, { pandoc.LineBreak() })
				if isMultirow(c.Cell) then
					inlinesCell = makeMultirow(inlinesCell, c.Cell, nil) -- FIXME: colSpec
				end
				if isMulticol(c.Cell) then
					inlinesCell = makeMulticol(inlinesCell, c.Cell, nil) -- FIXME: colSpec
				end

				inlinesCells:insert(inlinesCell)
			elseif t[y][x].Type == "mergeCell" then
				---@type any
				local c = t[y][x]
				---@type mergeCell_
				c = c

				---@type any
				ofC = t[c.Of.Y][c.Of.X]
				assert(ofC.Type == "cell")
				---@type cell_
				ofC = ofC

				if y == c.Of.Y then
					local inlinesCell = pandoc.Inlines({})
					if isMulticol(ofC.Cell) then
						inlinesCell = makeMulticol(inlinesCell, ofC.Cell, nil) -- FIXME: colSpec
					end

					inlinesCells:insert(inlinesCell)
				end
			else
				assert(false)
			end
		end
		inlinesCellsRows:insert(inlinesCells)
	end

	return inlinesCellsRows
end

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

---@alias cell contentCell | mergeCell
---@class contentCell
---@field Type "contentCell"
---@field Content Inlines
---@field Border { T: number | nil, B: number | nil, L: number | nil, R: number | nil }
---@field Alignment "left" | "center" | "right"
---@field Width "max-width" | number
---@field RowSpan integer
---@field ColSpan integer
---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@param t List<List<cell>>
---@param rowCount integer
---@param colCount integer
---@param rows List<Row> # Used to derive per-cell alignments.
---@param colAlignments List<"left" | "center" | "right">
---@return List<List<cell>>
local function setCellAlignments(t, rowCount, colCount, rows, colAlignments)
	for y = 1, rowCount do
		local colIndex = 1
		for x = 1, colCount do
			if t[y][x].Type == "contentCell" then
				t[y][x].Alignment = getAlignment(rows[y].cells[colIndex].alignment) or colAlignments[x]
				colIndex = colIndex + 1
			elseif t[y][x].Type == "mergeCell" then
			else
				assert(false)
			end
		end
	end
	return t
end

---@param t List<List<cell>>
---@param rowCount integer
---@param colCount integer
---@param colWidths List<"max-width" | number>
---@param source string|nil
---@return List<List<cell>>
local function setCellWidths(t, rowCount, colCount, colWidths, source)
	for y = 1, rowCount do
		for x = 1, colCount do
			if t[y][x].Type == "contentCell" then
				local width = 0
				local anyMaxWidth = false
				local anyNumber = false

				for i = 1, t[y][x].ColSpan do
					local colWidth = colWidths[x + i - 1]
					if colWidth == "max-width" then
						anyMaxWidth = true
					elseif type(colWidth) == "number" then
						width = width + colWidth
						anyNumber = true
					else
						assert(false)
					end
				end

				if anyMaxWidth and anyNumber then
					log.Error("the table has cell merging with mixed content-based and percentage widths", source)
					assert(false)
				elseif anyMaxWidth then
					t[y][x].Width = "max-width"
				elseif anyNumber then
					t[y][x].Width = width
				else
					assert(false)
				end
			elseif t[y][x].Type == "mergeCell" then
			else
				assert(false)
			end
		end
	end
	return t
end

---@param t List<List<cell>>
---@param rowCount integer
---@param colCount integer
---@param rowBorders List<{ T: number | nil, B: number | nil }>
---@param colBorders List<{ L: number | nil, R: number | nil }>
---@return List<List<cell>>
local function setCellBorders(t, rowCount, colCount, rowBorders, colBorders)
	for y = 1, rowCount do
		for x = 1, colCount do
			if t[y][x].Type == "contentCell" then
				t[y][x].Border = {
					T = rowBorders[y].T,
					B = rowBorders[y].B,
					L = colBorders[x].L,
					R = colBorders[x].R,
				}
			elseif t[y][x].Type == "mergeCell" then
			else
				assert(false)
			end
		end
	end
	return t
end

---@param t Table
filter.Table = function(t)
	return t
end

---@param doc Pandoc
---@param opts WriterOptions
---@return string
function Writer(doc, opts)
	return pandoc.write(doc:walk(filter), "latex", opts)
end

---@return string
function Template()
	local scriptDir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
	local templateFile = pandoc.path.join({ scriptDir, "template.tex" })
	local template = file.Read(templateFile)
	assert(template ~= nil)
	return template
end

---@type { [string]: boolean }
Extensions = {}
