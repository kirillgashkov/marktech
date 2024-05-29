local length = require("writer.internal.table.length")

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
    local b = { T = length.Zero(), B = divideWidth }
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
    local b = { L = length.Zero(), R = divideWidth }
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
---@return Inline | nil
local function makeHorizontalLatex(i, w, l, maxIndex)
  if length.IsZero(w) then
    return nil
  end

  local useFull = i == 1 and i + l - 1 == maxIndex
  if useFull then
    return merge({ raw([[\varhline]]), raw([[{]]), length.MakeLatex(w), raw([[}]]) })
  else
    return merge({
      raw([[\varcline]]),
      merge({ raw([[{]]), length.MakeLatex(w), raw([[}]]) }),
      merge({ raw([[{]]), raw(tostring(i)), raw([[-]]), raw(tostring(i + l - 1)), raw([[}]]) }),
    })
  end
end

---@param wr List<length> # Border width row.
---@return Inline | nil
function border.MakeHorizontalLatex(wr)
  if #wr == 0 then
    return nil
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
        local inline = makeHorizontalLatex(currentStart, currentWidth, currentLength, #wr)
        if inline ~= nil then
          inlines:insert(inline)
        end
        currentStart = i
        currentWidth = w
        currentLength = 1
      end
    end
  end

  local inline = makeHorizontalLatex(currentStart, currentWidth, currentLength, #wr)
  if inline ~= nil then
    inlines:insert(inline)
  end

  return #inlines > 0 and merge(inlines) or nil
end

---@param w length
---@return Inline
function border.MakeVerticalLatex(w)
  if length.IsZero(w) then
    return raw("")
  else
    return merge({
      raw([[!{\vrule width ]]),
      length.MakeLatex(w),
      raw([[}]]),
    })
  end
end

return border
