local log = require("internal.log")
local fun = require("internal.fun")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local length = {}

---@param a length
---@param b length
---@return length
function length.Add(a, b)
  local c = a
  for u, v in pairs(b) do
    c[u] = (c[u] or 0) + v
  end
  return c
end

---@param a length
---@param b length
---@return length
function length.Subtract(a, b)
  local c = a
  for u, v in pairs(b) do
    c[u] = (c[u] or 0) - v
  end
  return c
end

---@param a length
---@param b length
---@return boolean
function length.IsEqual(a, b)
  local units = {}
  for u, _ in pairs(a) do
    units[u] = true
  end
  for u, _ in pairs(b) do
    units[u] = true
  end
  for u, _ in pairs(units) do
    local av = a[u] or 0
    local bv = b[u] or 0
    if av ~= bv then
      return false
    end
  end
  return true
end

---@return length
function length.Zero()
  return {}
end

---@param l length
---@return boolean
function length.IsZero(l)
  return length.IsEqual(l, length.Zero())
end

---@param l length
---@return Inline
function length.MakeWidthLatex(l)
  local addends = pandoc.Inlines({})
  for u, v in pairs(l) do
    if u == "pt" then
      -- Parentheses help with negative values.
      addends:insert(merge({
        raw("("),
        raw(string.format("%.4f", v)),
        raw("pt"),
        raw(")"),
      }))
    elseif u == "%" then
      addends:insert(merge({
        raw([[(]]),
        merge({ raw([[\real]]), raw([[{]]), raw(string.format("%.4f", v)), raw([[}]]) }),
        raw([[*]]),
        raw([[\textwidth]]),
        raw([[)]]),
      }))
    else
      log.Error("unsupported width unit: " .. u)
      assert(false)
    end
  end
  return #addends == 0 and raw("0pt") or merge(fun.Intersperse(addends, raw(" + ")))
end

---@param l length
---@return Inline
function length.MakeHeightLatex(l)
  local addends = pandoc.Inlines({})
  for u, v in pairs(l) do
    if u == "pt" then
      -- Parentheses help with negative values.
      addends:insert(merge({
        raw("("),
        raw(string.format("%.4f", v)),
        raw("pt"),
        raw(")"),
      }))
    else
      log.Error("unsupported width unit: " .. u)
      assert(false)
    end
  end
  return #addends == 0 and raw("0pt") or merge(fun.Intersperse(addends, raw(" + ")))
end

---@param l length
---@return Inline
function length.MakeLatex(l)
  local addends = pandoc.Inlines({})
  for u, v in pairs(l) do
    if u == "pt" then
      -- Parentheses help with negative values.
      addends:insert(merge({
        raw("("),
        raw(string.format("%.4f", v)),
        raw("pt"),
        raw(")"),
      }))
    else
      log.Error("unsupported width unit: " .. u)
      assert(false)
    end
  end
  return #addends == 0 and raw("0pt") or merge(fun.Intersperse(addends, raw(" + ")))
end

return length
