local element = {}

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

element.MergeFilter = {
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
}

return element
