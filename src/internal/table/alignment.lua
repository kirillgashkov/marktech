local width = require("internal.table.width")
local element = require("internal.element")

local merge = element.Merge
local raw = element.Raw

local alignment = {}

---@param pa Alignment
---@return "left" | "center" | "right" | nil
local function getAlignment(pa)
  local a

  if pa == "AlignDefault" then
    a = nil
  elseif pa == "AlignLeft" then
    a = "left"
  elseif pa == "AlignCenter" then
    a = "center"
  elseif pa == "AlignRight" then
    a = "right"
  else
    assert(false)
  end

  return a
end

---@param colSpecs List<ColSpec>
---@return List<"left" | "center" | "right">
function alignment.MakeColAlignments(colSpecs)
  local alignments = pandoc.List({})

  for _, colSpec in ipairs(colSpecs) do
    local colSpecAlignment = colSpec[1]
    alignments:insert(getAlignment(colSpecAlignment) or "left")
  end

  return alignments
end

---@param c Cell
---@param colAlignment "left" | "center" | "right"
---@return "left" | "center" | "right"
function alignment.MakeCellAlignment(c, colAlignment)
  return getAlignment(c.alignment) or colAlignment
end

---@param a "left" | "center" | "right"
---@return Inline
local function makeMaxWidthLatex(a)
  local c
  if a == "left" then
    c = "l"
  elseif a == "center" then
    c = "c"
  elseif a == "right" then
    c = "r"
  else
    assert(false)
  end

  return raw(c)
end

---@param a "left" | "center" | "right" # Alignment.
---@param w length # Width.
---@param b { L: length, R: length } # Border.
---@return Inline
local function makeLengthWidthLatex(a, w, b)
  local c
  if a == "left" then
    c = [[\raggedright]]
  elseif a == "center" then
    c = [[\centering]]
  elseif a == "right" then
    c = [[\raggedleft]]
  else
    assert(false)
  end

  return merge({
    merge({
      raw([[>]]),
      raw([[{]]),
      raw(c),
      raw([[\arraybackslash]]),
      raw([[}]]),
    }),
    merge({
      raw([[p]]),
      raw([[{]]),
      width.MakeLatex(w, b),
      raw([[}]]),
    }),
  })
end

---@param a "left" | "center" | "right" # Alignment.
---@param w length | nil # Width. Nil behaves like CSS's "max-width".
---@param b { L: length, R: length } # Border.
---@return Inline
function alignment.MakeLatex(a, w, b)
  local s

  if type(w) == "table" then
    s = makeLengthWidthLatex(a, w, b)
  elseif w == nil then
    s = makeMaxWidthLatex(a)
  else
    assert(false)
  end

  return s
end

return alignment
