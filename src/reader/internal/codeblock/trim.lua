local codeblock = {}

---@param e pandoc.CodeBlock
---@return pandoc.CodeBlock
function codeblock.Trim(e)
  e.text = e.text:gsub("^\n+", ""):gsub("\n+$", "")
  return e
end

return codeblock
