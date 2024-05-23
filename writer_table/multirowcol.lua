local fun = require("fun")
local spec = require("writer_table.spec")
local width = require("writer_table.width")

local multirowcol = {}

---@param c contentCell
---@return boolean
local function isMultirow(c)
	return c.RowSpan > 1
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
function multirowcol.MakeMultirowLatex(content, c)
	return pandoc.Inlines(fun.Flatten({
		{
			pandoc.RawInline(
				"latex",
				(
					"\\multirow"
					.. ("{" .. c.RowSpan .. "}")
					.. ("{" .. width.MakeColWidthLatex(c.Width, c.Border) .. "}")
					.. "{"
				)
			),
		},
		content,
		{ pandoc.RawInline("latex", "}") },
	}))
end

---@param content Inlines # Used instead of c.content.
---@param c contentCell
---@param config config
---@return Inlines
function multirowcol.MakeMulticolLatex(content, c, config)
	return pandoc.Inlines(fun.Flatten({
		{
			pandoc.RawInline(
				"latex",
				(
					"\\multicol"
					.. ("{" .. c.ColSpan .. "}")
					.. ("{" .. spec.MakeColSpecLatex(c.Alignment, c.Width, c.Border, config) .. "}")
					.. "{"
				)
			),
		},
		content,
		{ pandoc.RawInline("latex", "}") },
	}))
end

return multirowcol
