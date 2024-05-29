local rawblock = {}

---@param e pandoc.RawBlock
---@param htmlReader { read: fun(string): pandoc.Pandoc }
---@return pandoc.Blocks | pandoc.RawBlock
function rawblock.EmbedHtml(e, htmlReader)
  if e.format ~= "html" then
    return e
  end
  return htmlReader.read(e.text).blocks
end

return rawblock
