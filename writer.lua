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

---@class contentCellWithContent
---@field Type "contentCell"
---@field Content Inlines
---@field RowSpan integer
---@field ColSpan integer

---@class contentCellWithContentAlignment: contentCellWithContent
---@field Alignment "left" | "center" | "right"

---@class contentCellWithContentAlignmentWidth: contentCellWithContentAlignment
---@field Width "max-width" | number

---@class contentCellWithContentAlignmentWidthBorder: contentCellWithContentAlignmentWidth
---@field Border { T: number | nil, B: number | nil, L: number | nil, R: number | nil }

---@alias contentCell contentCellWithContentAlignmentWidthBorder

---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@param rowCount integer
---@param colCount integer
---@param rows List<Row>
---@param source string|nil
---@return List<List<contentCellWithContent | mergeCell>>
local function makeTablePartBase(rowCount, colCount, rows, source)
	---@type List<List<contentCellWithContent | mergeCell | nil>>
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
						if y + y_offset > rowCount then
							log.Error("the table has a cell that spans beyond the row count", source)
							assert(false)
						end
						if x + x_offset > colCount then
							log.Error("the table has a cell that spans beyond the column count", source)
							assert(false)
						end
						assert(t[y + y_offset][x + x_offset] == nil)

						local c
						if y_offset == 0 and x_offset == 0 then
							local content = pandoc.utils.blocks_to_inlines(cell.contents, { pandoc.LineBreak() })
							---@type contentCellWithContent
							c = {
								Type = "contentCell",
								Content = content,
								RowSpan = cell.row_span,
								ColSpan = cell.col_span,
							}
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

	for y = 1, rowCount do
		for x = 1, colCount do
			assert(t[y][x] ~= nil)
		end
	end
	---@type List<List<any>>
	t = t
	---@type List<List<contentCellWithContent | mergeCell>>
	t = t

	return t
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

---@param t List<List<contentCellWithContent | mergeCell>>
---@param rowCount integer
---@param colCount integer
---@param rows List<Row> # Used to derive per-cell alignments.
---@param colAlignments List<"left" | "center" | "right">
---@return List<List<contentCellWithContentAlignment | mergeCell>>
local function setCellAlignments(t, rowCount, colCount, rows, colAlignments)
	---@cast t contentCellWithContentAlignment
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

---@param t List<List<contentCellWithContentAlignment | mergeCell>>
---@param rowCount integer
---@param colCount integer
---@param colWidths List<"max-width" | number>
---@param source string|nil
---@return List<List<contentCellWithContentAlignmentWidth | mergeCell>>
local function setCellWidths(t, rowCount, colCount, colWidths, source)
	---@cast t contentCellWithContentAlignmentWidth
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

---@param t List<List<contentCellWithContentAlignmentWidth | mergeCell>>
---@param rowCount integer
---@param colCount integer
---@param rowBorders List<{ T: number | nil, B: number | nil }>
---@param colBorders List<{ L: number | nil, R: number | nil }>
---@return List<List<contentCellWithContentAlignmentWidthBorder | mergeCell>>
local function setCellBorders(t, rowCount, colCount, rowBorders, colBorders)
	---@cast t contentCellWithContentAlignmentWidthBorder
	for y = 1, rowCount do
		for x = 1, colCount do
			if t[y][x].Type == "contentCell" then
				t[y][x].Border = {
					T = rowBorders[y].T,
					B = rowBorders[y + t[y][x].RowSpan - 1].B,
					L = colBorders[x].L,
					R = colBorders[x + t[y][x].ColSpan - 1].R,
				}
			elseif t[y][x].Type == "mergeCell" then
			else
				assert(false)
			end
		end
	end
	return t
end

---@param rowCount integer
---@param colCount integer
---@param rows List<Row>
---@param colSpecs List<ColSpec>
---@param source string|nil
---@return List<List<contentCell|mergeCell>>
local function makeTablePart(rowCount, colCount, rows, colSpecs, source)
	local t = makeTablePartBase(rowCount, colCount, rows, source)
	local colAlignments = makeColAlignments(colSpecs)
	local colWidths = makeColWidths(colSpecs, source)
	local innerWidth = 0.5 -- pt
	local outerWidth = 1 -- pt
	local firstTop = "inner"
	local lastBottom = "inner"
	local rowBorders = makeRowBorders(innerWidth, outerWidth, firstTop, lastBottom, rowCount)
	local colBorders = makeColBorders(innerWidth, outerWidth, colCount)
	t = setCellAlignments(t, rowCount, colCount, rows, colAlignments)
	t = setCellWidths(t, rowCount, colCount, colWidths, source)
	t = setCellBorders(t, rowCount, colCount, rowBorders, colBorders)
	return t
end

---@param borderWidth number
---@return string
local function makeBorderWidthLatexString(borderWidth)
	return string.format("%.4f", borderWidth) .. "pt"
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

---@param alignment "left" | "center" | "right"
---@return RawInline
local function makeMaxWidthAlignmentLatex(alignment)
	if alignment == "left" then
		return pandoc.RawInline("latex", "l")
	elseif alignment == "center" then
		return pandoc.RawInline("latex", "c")
	elseif alignment == "right" then
		return pandoc.RawInline("latex", "r")
	else
		assert(false)
	end
end

---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return RawInline
local function makeNumberWidthAlignmentLatex(alignment, width, border)
	local raggedOrCenteringLatex
	if alignment == "left" then
		raggedOrCenteringLatex = "\\raggedright"
	elseif alignment == "center" then
		raggedOrCenteringLatex = "\\centering"
	elseif alignment == "right" then
		raggedOrCenteringLatex = "\\raggedleft"
	else
		assert(false)
	end

	return pandoc.RawInline(
		"latex",
		(
			">{"
			.. raggedOrCenteringLatex
			.. "\\arraybackslash"
			.. "}"
			.. "p{"
			.. makeWidthLatexString(width, border)
			.. "}"
		)
	)
end

---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return RawInline
local function makeAlignmentLatex(alignment, width, border)
	local latex
	if width == "max-width" then
		latex = makeMaxWidthAlignmentLatex(alignment)
	elseif type(width) == "number" then
		latex = makeNumberWidthAlignmentLatex(alignment, width, border)
	else
		assert(false)
	end
	return latex
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

---@param alignment "left" | "center" | "right"
---@param width "max-width" | number
---@param border { L: number | nil, R: number | nil }
---@return Inlines
local function makeColSpecLatex(alignment, width, border)
	return pandoc.Inlines(fun.Flatten({
		border.L and { makeVerticalBorderLatex(border.L) } or {},
		{ makeAlignmentLatex(alignment, width, border) },
		border.R and { makeVerticalBorderLatex(border.R) } or {},
	}))
end

---@param c contentCell
---@return boolean
local function isMultirow(c)
	return c.RowSpan > 1
end

---@param content Inlines # Used instead of c.content.
---@param c contentCell
---@return Inlines
local function makeMultirowLatex(content, c)
	return pandoc.Inlines(fun.Flatten({
		{ pandoc.RawInline("latex", "\\multirow") },
		{ pandoc.RawInline("latex", "{" .. tostring(c.RowSpan) .. "}") },
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			{ pandoc.RawInline("latex", makeWidthLatexString(c.Width, c.Border) or "*") }, -- "*" means natural width.
			{ pandoc.RawInline("latex", "}") },
		}),
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			content,
			{ pandoc.RawInline("latex", "}") },
		}),
	}))
end

---@param c contentCell
---@param x integer # The column index.
---@param colAlignments List<"left" | "center" | "right">
---@return boolean
local function isMulticol(c, x, colAlignments)
	return c.ColSpan > 1 or c.Alignment ~= colAlignments[x]
end

---@param content Inlines # Used instead of c.content.
---@param c contentCell
---@return Inlines
local function makeMulticolLatex(content, c)
	return pandoc.Inlines(fun.Flatten({
		{ pandoc.RawInline("latex", "\\multicol") },
		{ pandoc.RawInline("latex", "{" .. tostring(c.ColSpan) .. "}") },
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			makeColSpecLatex(c.Alignment, c.Width, c.Border),
			{ pandoc.RawInline("latex", "}") },
		}),
		fun.Flatten({
			{ pandoc.RawInline("latex", "{") },
			content,
			{ pandoc.RawInline("latex", "}") },
		}),
	}))
end

---@param t List<List<contentCell | mergeCell>>
---@param rowCount integer
---@param colCount integer
---@param colAlignments List<"left" | "center" | "right">
local function makeTablePartLatex(t, rowCount, colCount, colAlignments, rowBorders)
	---@type List<List<Inlines>>
	local rows = pandoc.List({})

	for y = 1, rowCount do
		---@type List<Inlines>
		local row = pandoc.List({})

		for x = 1, colCount do
			assert(t[y][x] ~= nil)

			local c = t[y][x]
			if c.Type == "contentCell" then
				---@cast c contentCell

				local cell = c.Content
				if isMultirow(c) then
					cell = makeMultirowLatex(cell, c)
				end
				if isMulticol(c, x, colAlignments) then
					cell = makeMulticolLatex(cell, c)
				end
				row:insert(cell)
			elseif t[y][x].Type == "mergeCell" then
				---@cast c mergeCell

				local ofC = t[c.Of.Y][c.Of.X]
				assert(ofC.Type == "contentCell")
				---@cast ofC contentCell

				if y == c.Of.Y then
					local cell = pandoc.Inlines({})
					if isMulticol(ofC, c.Of.X, colAlignments) then
						inlinesCell = makeMulticolLatex(inlinesCell, ofC)
					end
					row:insert(cell)
				end
			else
				assert(false)
			end
		end
		rows:insert(row)
	end

	local inlinesList = pandoc.List({})

	for i = 1, rowCount do
		-- rowBorders[i].T
		local rowInlines = fun.Reduce(function(reduced, a)
			if #reduced > 0 then
				reduced:insert(pandoc.RawInline("latex", "&"))
			end
			reduced:embed(a)
			return reduced
		end, rows[i], pandoc.Inlines({}))
	end

	return rows
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
