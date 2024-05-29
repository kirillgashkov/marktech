local orderedlist = {}

---@param e pandoc.OrderedList
---@return pandoc.OrderedList
function orderedlist.Reset(e)
  -- Prevents Pandoc from injecting \def\labelenumi{\arabic{enumi}.} into
  -- ordered lists by resetting the style and delimiter list attributes.
  --
  -- Sources:
  -- - https://forum.posit.co/t/how-to-prevent-pandoc-from-forcing-lists-to-be-arabic/138681/2
  -- - https://pandoc.org/lua-filters.html#type-orderedlist
  -- - https://pandoc.org/lua-filters.html#type-listattributes
  -- - Experiment about running "pandoc --from commonmark --to json" and
  --   "pandoc --from markdown_strict+fancy_list --to json" and comparing
  --   the results.
  e.listAttributes = pandoc.ListAttributes(
    e.listAttributes.start, -- start
    "DefaultStyle", -- style
    "DefaultDelim" -- delimiter
  )
  return e
end

return orderedlist
