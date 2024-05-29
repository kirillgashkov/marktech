ocal rawinline = {}

---@param e pandoc.RawInline
---@param htmlReader { read: fun(string): pandoc.Pandoc }
---@return pandoc.Inlines | pandoc.RawInline
function rawinline.EmbedHtml(e, htmlReader)
  if e.format ~= "html" then
    return e
  end
  return pandoc.utils.blocks_to_inlines(htmlReader.read(e.text).blocks)
end

return rawinline
