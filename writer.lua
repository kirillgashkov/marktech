local writer = {}

---@param code_block CodeBlock
writer.CodeBlock = function(code_block)
	print("code block!")
end

---@param doc Pandoc
---@param opts WriterOptions
---@return string
function Writer(doc, opts)
	return pandoc.write(doc:walk(writer), "commonmark", opts)
end

---@return string
function Template()
	return pandoc.template.default("commonmark")
end

---@type { [string]: boolean }
Extensions = {}
