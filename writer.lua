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

---@class cell
---@field Type "cell"
---@field Cell Cell
---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@param rows List<Row>
---@param rowCount integer
---@param colCount integer
---@param source string|nil
local function makeRows(rows, rowCount, colCount, source)
	---@type List<List<cell | mergeCell | nil>>
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
							---@type cell
							c = { Type = "cell", Cell = cell }
						else
							---@type mergeCell
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
				---@type cell
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
				---@type mergeCell
				c = c

				---@type any
				ofC = t[c.Of.Y][c.Of.X]
				assert(ofC.Type == "cell")
				---@type cell
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
