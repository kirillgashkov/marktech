local codeblock = {}

---@param e pandoc.CodeBlock
---@return any
function codeblock.EmbedRaw(e)
  if e.attr.classes:includes("raw") then
    return pandoc.RawBlock("latex", e.text)
  else
    return e
  end
end

return codeblock
