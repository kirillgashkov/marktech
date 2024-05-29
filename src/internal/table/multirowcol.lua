local spec = require("internal.table.spec")
local width = require("internal.table.width")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local multirowcol = {}

---@param c contentCell
---@return boolean
function multirowcol.IsMultirow(c)
  return c.RowSpan > 1
end

---@param c contentCell
---@param x integer # The column index.
---@param colAlignments List<"left" | "center" | "right">
---@return boolean
function multirowcol.IsMulticol(c, x, colAlignments)
  return c.ColSpan > 1 or c.Alignment ~= colAlignments[x]
end

---@param content Inline
---@param forCell contentCell
---@return Inline
function multirowcol.MakeMultirowLatex(content, forCell)
  return merge({
    raw([[\multirow]]),
    merge({
      raw([[{]]),
      raw(tostring(forCell.RowSpan)),
      raw([[}]]),
    }),
    merge({
      raw([[{]]),
      -- TODO: Consider using = instead.
      forCell.Width ~= "max-content" and width.MakeLatex(forCell.Width --[[@as length]], forCell.Border)
        or raw([[*]]),
      raw([[}]]),
    }),
    merge({
      raw([[{]]),
      content,
      raw([[}]]),
    }),
  })
end

---@param content Inline
---@param forCell contentCell
---@param config config
---@return Inline
function multirowcol.MakeMulticolLatex(content, forCell, config)
  return merge({
    raw([[\multicolumn]]),
    merge({
      raw([[{]]),
      raw(tostring(forCell.ColSpan)),
      raw([[}]]),
    }),
    merge({
      raw([[{]]),
      spec.MakeLatex(forCell.Alignment, forCell.Width, forCell.Border),
      raw([[}]]),
    }),
    merge({
      raw([[{]]),
      content,
      raw([[}]]),
    }),
  })
end

return multirowcol
