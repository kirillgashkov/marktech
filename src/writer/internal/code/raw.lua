local code = {}

---@param e pandoc.Code
---@return pandoc.Code | pandoc.RawInline
function code.EmbedRaw(e)
  if e.attr.classes:includes("raw") then
    return pandoc.RawInline("latex", e.text)
  else
    return e
  end
end

return code
