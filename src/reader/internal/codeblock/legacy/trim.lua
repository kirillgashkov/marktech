-- New.

local trim = {}

---@param e pandoc.CodeBlock
---@return pandoc.CodeBlock
function trim.Trim(e)
  e.text = e.text:gsub("^\n+", ""):gsub("\n+$", "")
  return e
end

return trim
