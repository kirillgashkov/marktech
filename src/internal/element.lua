local utility = require("internal.utility.utility")
local log = require("internal.log")

local element = {}

local mdFormat = "gfm-yaml_metadata_block"

---@param e { attr: Attr }
---@return string|nil
function element.GetSource(e)
  return e.attr.attributes["data-pos"]
end

---@param e { attr: Attr }
---@return nil
local function removeSource(e)
  e.attr.attributes["data-pos"] = nil
end

---@param e { attr: Attr }
---@return nil
local function setWidth(e)
  local w = nil
  for _, c in ipairs(e.attr.classes) do
    local parsedWidth = utility.ParseWidth(c, element.GetSource(e))
    if parsedWidth ~= nil then
      w = parsedWidth
    end
  end
  if w ~= nil then
    if e.attr.attributes["width"] ~= nil and e.attr.attributes["width"] ~= "" then
      log.Warning("element already has a width, the utility class will take precedence", element.GetSource(e))
    end
    e.attr.attributes["width"] = w
  end
end

---@param e Div | Span
---@return boolean
local function isMerge(e)
  return e.attr.attributes["data-template--is-merge"] == "1"
end

---@param e Div | Span
---@return boolean
local function isRedundant(e)
  if e.attr.identifier ~= "" then
    return false
  end
  if #e.attr.classes > 0 then
    return false
  end
  for _ in pairs(e.attr.attributes) do
    return false
  end
  if #e.content > 1 then
    return false
  end
  return true
end

---@param inlines Inlines
---@return Inline
function element.Merge(inlines)
  local i = pandoc.Span(inlines)
  i.attr.attributes["data-template--is-merge"] = "1"
  return i
end

---@param blocks Blocks
---@return Block
function element.MergeBlock(blocks)
  local b = pandoc.Div(blocks)
  b.attr.attributes["data-template--is-merge"] = "1"
  return b
end

---@param s string
---@return Inline
function element.Raw(s)
  return pandoc.RawInline("latex", s)
end

---@param s string
---@return Inline
function element.Md(s)
  return element.Merge(pandoc.utils.blocks_to_inlines(pandoc.read(s, mdFormat).blocks))
end

---@param s string
---@return Block
function element.MdBlock(s)
  return element.MergeBlock(pandoc.read(s, mdFormat).blocks)
end

---@param document Pandoc
---@return Pandoc
function element.RemoveMerges(document)
  return document:walk({
    ---@param d Div
    ---@return Div | Blocks
    Div = function(d)
      if isMerge(d) then
        return d.content
      end
      return d
    end,

    ---@param s Span
    ---@return Span | Inlines
    Span = function(s)
      if isMerge(s) then
        return s.content
      end
      return s
    end,
  })
end

---Creates redundant Divs and Spans.
---@param document Pandoc
---@return Pandoc
function element.RemoveSources(document)
  return document:walk({
    ---@param b Block
    ---@return Block
    Block = function(b)
      if b["attr"] ~= nil then
        removeSource(b)
      end
      return b
    end,

    ---@param i Inline
    ---@return Inline
    Inline = function(i)
      if i["attr"] ~= nil then
        removeSource(i)
      end
      return i
    end,
  })
end

---@param document Pandoc
---@return Pandoc
function element.SetWidths(document)
  return document:walk({
    ---@param b Block
    ---@return Block
    Block = function(b)
      if b["attr"] ~= nil then
        setWidth(b)
      end
      return b
    end,

    ---@param i Inline
    ---@return Inline
    Inline = function(i)
      if i["attr"] ~= nil then
        setWidth(i)
      end
      return i
    end,

    ---Sets widths for element components because they aren't covered by Block
    ---and Inline walkthroughs.
    ---@param t Table
    ---@return Table
    Table = function(t)
      ---@param rows List<Row>
      local setWidthsRows = function(rows)
        for _, r in ipairs(rows) do
          setWidth(r)
          for _, c in ipairs(r.cells) do
            setWidth(c)
          end
        end
      end

      setWidth(t.head)
      setWidthsRows(t.head.rows)
      for _, b in ipairs(t.bodies) do
        setWidth(b)
        setWidthsRows(b.head)
        setWidthsRows(b.body)
      end
      setWidth(t.foot)
      setWidthsRows(t.foot.rows)

      return t
    end,
  })
end

---@param document Pandoc
---@return Pandoc
function element.RemoveRedundants(document)
  return document:walk({
    ---@param d Div
    ---@return Div | Blocks
    Div = function(d)
      if isRedundant(d) then
        return d.content
      end
      return d
    end,

    ---@param s Span
    ---@return Span | Inlines
    Span = function(s)
      if isRedundant(s) then
        return s.content
      end
      return s
    end,
  })
end

return element
