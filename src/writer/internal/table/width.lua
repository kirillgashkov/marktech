local length = require("writer.internal.table.length")
local log = require("internal.log")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local width = {}

-- I'm not sure if Pandoc allows mixing default and non-default column widths but we do. One of our filters surely
-- generates such tables. Also these widths account for borders, similar to CSS's "box-sizing: border-box".
---@param colSpecs List<ColSpec>
---@param source string | nil
---@return List<length | "max-content">
function width.MakeColWidths(colSpecs, source)
  ---@type List<length | "max-content">
  local widths = pandoc.List({})

  for _, colSpec in ipairs(colSpecs) do
    local w = colSpec[2]

    if type(w) == "number" then
      widths:insert({ ["%"] = w * 100 })
    elseif w == nil then
      widths:insert("max-content")
    else
      assert(false)
    end
  end

  local total = 0
  for i = 1, #widths do
    local w = widths[i]
    if type(w) == "table" then
      total = total + (w["%"] or 0)
    elseif w == "max-content" then
    else
      assert(false)
    end
  end
  if total > 100 then
    log.Warning("table has a total column width of " .. total .. "% which is greater than 100%", source)
  end

  return widths
end

---@param w length # Width.
---@param b { L: length, R: length } # Border.
---@return Inline
function width.MakeLatex(w, b)
  return merge({
    raw([[\dimexpr]]),
    raw([[(]]),
    merge({
      length.MakeWidthLatex(length.Subtract(w, length.Add(b.L, b.R))),
      pandoc.Space(),
      raw([[-]]),
      pandoc.Space(),
      raw([[2]]),
      raw([[\tabcolsep]]),
    }),
    raw([[)]]),
    raw([[\relax]]),
  })
end

return width
