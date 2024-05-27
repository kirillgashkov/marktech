local log = require("internal.log")
local length = require("internal.table.length")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local border = {}

---@param rowCount integer
---@param topWidth length
---@param divideWidth length
---@param bottomWidth length
---@return List<{ T: length, B: length }>
function border.MakeRowBorders(rowCount, topWidth, divideWidth, bottomWidth)
  local borders = pandoc.List({})
  for i = 1, rowCount do
    local b = { T = divideWidth, B = divideWidth }
    if i == 1 then
      b.T = topWidth
    end
    if i == rowCount then
      b.B = bottomWidth
    end
    borders:insert(b)
  end
  return borders
end

---@param colCount integer
---@param leftWidth length
---@param divideWidth length
---@param rightWidth length
---@return List<{ L: length, R: length }>
function border.MakeColBorders(colCount, leftWidth, divideWidth, rightWidth)
  local borders = pandoc.List({})
  for i = 1, colCount do
    local b = { L = divideWidth, R = divideWidth }
    if i == 1 then
      b.L = leftWidth
    end
    if i == colCount then
      b.R = rightWidth
    end
    borders:insert(b)
  end
  return borders
end

---@param i integer # Border start index.
---@param w length # Border width.
---@param l integer # Border length.
---@param maxIndex integer
---@param config config
---@param source? string | nil
---@return Inline
local function makeHorizontalLatex(i, w, l, maxIndex, config, source)
  local useLine = length.IsEqual(w, config.ArrayRuleWidth)
  local useFull = i == 1 and i + l - 1 == maxIndex

  if useLine then
    if useFull then
      return raw([[\hline"]])
    else
      return raw([[\cline{]] .. i .. [[-]] .. i + l - 1 .. [[}]])
    end
  else
    if useFull then
      return merge({
        raw([[\specialrule]]),
        raw([[{]]),
        length.MakeLatex(w),
        raw([[}]]),
        raw([[{0pt}]]),
        raw([[{0pt}]]),
      })
    else
      log.Error("table row has unsupported border width", source)
      return raw([[\cline{]] .. i .. [[-]] .. i + l - 1 .. [[}]])
    end
  end
end

---@param wr List<length> # Border width row.
---@param config config
---@return Inline
function border.MakeHorizontalLatex(wr, config)
  if #wr == 0 then
    return merge({})
  end

  local inlines = pandoc.List({})

  local currentStart = 1
  local currentWidth = wr[1]
  local currentLength = 1

  for i, w in ipairs(wr) do
    if i > 1 then
      if length.IsEqual(w, currentWidth) then
        currentLength = currentLength + 1
      else
        inlines:insert(makeHorizontalLatex(currentStart, currentWidth, currentLength, #wr, config))
        currentStart = i
        currentWidth = w
        currentLength = 1
      end
    end
  end

  inlines:insert(makeHorizontalLatex(currentStart, currentWidth, currentLength, #wr, config))

  return merge(inlines)
end

---@param w length
---@param config config
---@return Inline
function border.MakeVerticalLatex(w, config)
  if length.IsZero(w) then
    return raw("")
  elseif length.IsEqual(w, config.ArrayRuleWidth) then
    return raw("|")
  else
    return merge({
      raw([[!{\vrule width ]]),
      length.MakeLatex(w),
      raw([[}]]),
    })
  end
end

return border
