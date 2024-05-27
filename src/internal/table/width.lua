local length = require("internal.table.length")

local width = {}

-- I'm not sure if Pandoc allows mixing default and non-default column widths but we do. One of our filters surely
-- generates such tables. Also these widths account for borders, similar to CSS's "box-sizing: border-box".
---@param colSpecs List<ColSpec>
---@return List<length | nil>
function width.MakeColWidths(colSpecs)
  ---@type List<length | nil>
  local widths = pandoc.List({})

  for _, colSpec in ipairs(colSpecs) do
    local w = colSpec[2]

    if type(w) == "number" then
      widths:insert({ ["%"] = w })
    elseif w == nil then
      widths:insert(nil)
    else
      assert(false)
    end
  end

  -- local total = 0
  -- for i = 1, #widths do
  -- 	total = total + (widths[i] or 0)
  -- end
  -- if total > 1 then
  -- 	log.Warning("the table has a total column width greater than 100%", source)
  -- end

  return widths
end

---@param w length # Width.
---@param b { L: length, R: length } # Border.
---@return Inline
function width.MakeLatex(w, b)
  return length.MakeWidthLatex(length.Subtract(w, length.Add(b.L, b.R)))
end

return width
