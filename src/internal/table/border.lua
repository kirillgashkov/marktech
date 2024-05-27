local log = require("internal.log")
local length = require("internal.table.length")
local element = require("internal.element")

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

---@param b "T" | "B"
---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@return List<{ Width: length, Length: integer }>
local function getSegmentsForRowBorder(b, y, t)
  local segments = pandoc.List({})

  local segment = { Width = length.Zero(), Length = 0 }

  for x = 1, #t[y] do
    local cBorder = { T = length.Zero(), B = length.Zero() }

    local c = t[y][x]
    if c.Type == "contentCell" then
      ---@cast c contentCell

      cBorder = {
        T = c.Border.T,
        B = c.RowSpan == 1 and c.Border.B or length.Zero(),
      }
    elseif c.Type == "mergeCell" then
      ---@cast c mergeCell

      local ofC = t[c.Of.Y][c.Of.X]
      assert(ofC.Type == "contentCell")
      ---@cast ofC contentCell

      cBorder = {
        T = y == c.Of.Y and ofC.Border.T or length.Zero(),
        B = y == c.Of.Y + ofC.RowSpan - 1 and ofC.Border.B or length.Zero(),
      }
    else
      assert(false)
    end

    if cBorder[b] == segment.Width then
      segment.Length = segment.Length + 1
    else
      if segment.Length > 0 then
        segments:insert(segment)
      end
      segment = { Width = cBorder[b], Length = 1 }
    end
  end

  if segment.Length > 0 then
    segments:insert(segment)
  end
  segment = { Width = length.Zero(), Length = 0 }

  return segments
end

---@param segments List<{ Width: length, Length: integer }>
---@param source string|nil
---@param config config
---@return string
local function makeHorizontalBorderSegmentsLatex(segments, source, config)
  local s = ""

  local x = 1
  for _, w in ipairs(segments) do
    if length.IsZero(w.Width) then
      x = x + w.Length
    else
      if not length.IsEqual(w.Width, config.ArrayRuleWidth) then
        log.Error("the table has a segment of a horizontal border with unsupported width", source)
        log.Note("use width " .. length.MakeLengthLatex(config.ArrayRuleWidth) .. " instead", source)
      end
      local x1, x2 = x, x + w.Length - 1
      s = s .. [[\cline]] .. [[{]] .. x1 .. [[-]] .. x2 .. [[}]]
      x = x2 + 1
    end
  end

  return s
end

---@param w length
---@param config config
---@return string
function border.MakeVerticalBorderLatex(w, config)
  if length.IsZero(w) then
    return ""
  elseif length.IsEqual(w, config.ArrayRuleWidth) then
    return "|"
  else
    return [[!{\vrule width ]] .. length.MakeLengthLatex(w) .. [[}]]
  end
end

---@param b "T" | "B"
---@param y integer
---@param t List<List<contentCell | mergeCell>>
---@param source string|nil
---@param config config
---@return string
function border.MakeHorizontalBorderLatexForRowBorder(b, y, t, source, config)
  local segments = getSegmentsForRowBorder(b, y, t)

  if #segments == 0 then
    return ""
  end

  if #segments == 1 then
    local w = segments[1].Width

    if length.IsZero(w) then
      return ""
    elseif length.IsEqual(w, config.ArrayRuleWidth) then
      return [[\hline]]
    else
      return [[\specialrule]] .. [[{]] .. length.MakeLengthLatex(w) .. [[}]] .. [[{0pt}{0pt}]]
    end
  end

  return makeHorizontalBorderSegmentsLatex(segments, source, config)
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
      return element.Raw([[\hline"]])
    else
      return element.Raw([[\cline{]] .. i .. [[-]] .. i + l - 1 .. [[}]])
    end
  else
    if useFull then
      return element.Raw([[\specialrule{]] .. length.MakeLengthLatex(w) .. [[}{0pt}{0pt}]])
    else
      log.Error("table row has unsupported border width", source)
      return element.Raw([[\cline{]] .. i .. [[-]] .. i + l - 1 .. [[}]])
    end
  end
end

---@param wr List<length> # Border width row.
---@param config config
---@return Inline
function border.MakeHorizontalLatex(wr, config)
  if #wr == 0 then
    return element.Merge({})
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

  return element.Merge(inlines)
end

---@param w length
---@param config config
---@return Inline
function border.MakeVerticalLatex(w, config)
  if length.IsZero(w) then
    return element.Raw("")
  elseif length.IsEqual(w, config.ArrayRuleWidth) then
    return element.Raw("|")
  else
    return element.Raw([[!{\vrule width ]] .. length.MakeLengthLatex(w) .. [[}]])
  end
end

return border
