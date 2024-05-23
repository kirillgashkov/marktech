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
