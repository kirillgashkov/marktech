local element = {}

local mdFormat = "gfm-yaml_metadata_block"

---@param e { attr: Attr }
---@return string|nil
function element.GetSource(e)
	return e.attr.attributes["data-pos"]
end

---@param attr Attr
---@return boolean
function element.IsMerge(attr)
	return attr.attributes["data-template--is-merge"] == "1"
end

---@param inlines Inlines
---@return Inline
function element.Merge(inlines)
	local i = pandoc.Span(inlines)
	i.attr.attributes["data-template--is-merge"] = "1"
	return i
end

---@param blocks Blocks
---@return Block
function element.MergeBlock(blocks)
	local b = pandoc.Div(blocks)
	b.attr.attributes["data-template--is-merge"] = "1"
	return b
end

---@param s string
---@return Inline
function element.Raw(s)
	return pandoc.RawInline("latex", s)
end

---@param s string
---@return Inline
function element.Md(s)
	return element.Merge(pandoc.utils.blocks_to_inlines(pandoc.read(s, mdFormat).blocks))
end

---@param s string
---@return Block
function element.MdBlock(s)
	return element.MergeBlock(pandoc.read(s, mdFormat).blocks)
end

---@param d Pandoc
---@return Pandoc
function element.RemoveMerges(d)
	return d:walk({
		---@param div Div
		---@return Div | Blocks
		Div = function(div)
			if element.IsMerge(div.attr) then
				return div.content
			end
			return div
		end,

		---@param span Span
		---@return Span | Inlines
		Span = function(span)
			if element.IsMerge(span.attr) then
				return span.content
			end
			return span
		end,
	})
end

return element
