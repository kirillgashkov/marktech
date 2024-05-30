local fun = require("internal.fun")
local log = require("internal.log")
local alignment = require("writer.internal.table.alignment")
local width = require("writer.internal.table.width")
local border = require("writer.internal.table.border")
local multirowcol = require("writer.internal.table.multirowcol")
local spec = require("writer.internal.table.spec")
local length = require("internal.length")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local table_ = {}

---@param pandocRows pandoc.List<pandoc.Row>
---@param rowCount integer
---@param colCount integer
---@param source string|nil
---@return pandoc.List<pandoc.List<contentCellWithContent | mergeCell>>
local function makeNewRows(pandocRows, rowCount, colCount, source)
  ---@type pandoc.List<pandoc.List<contentCellWithContent | mergeCell | nil>>
  local rows = pandoc.List({})
  for _ = 1, rowCount do
    ---@type pandoc.List<contentCellWithContent | mergeCell | nil>
    local r = pandoc.List({})
    for _ = 1, colCount do
      r:insert(nil)
    end
    rows:insert(r)
  end

  for y = 1, rowCount do
    local cellIndex = 1
    for x = 1, colCount do
      if rows[y][x] == nil then
        local cell = pandocRows[y].cells[cellIndex]

        for yOffset = 0, cell.row_span - 1 do
          for xOffset = 0, cell.col_span - 1 do
            if y + yOffset > rowCount then
              log.Error("the table has a cell that spans beyond the row count", source)
              assert(false)
            end
            if x + xOffset > colCount then
              log.Error("the table has a cell that spans beyond the column count", source)
              assert(false)
            end
            assert(rows[y + yOffset][x + xOffset] == nil)

            local c
            if yOffset == 0 and xOffset == 0 then
              local content = pandoc.utils.blocks_to_inlines(cell.contents, { pandoc.LineBreak() })
              ---@type contentCellWithContent
              c = {
                Type = "contentCell",
                Content = content,
                RowSpan = cell.row_span,
                ColSpan = cell.col_span,
              }
            else
              ---@type mergeCell
              c = { Type = "mergeCell", Of = { X = x, Y = y } }
            end
            rows[y + yOffset][x + xOffset] = c
          end
        end

        cellIndex = cellIndex + 1
      end
    end
  end

  for y = 1, rowCount do
    for x = 1, colCount do
      assert(rows[y][x] ~= nil)
    end
  end

  return rows --[[@as any]]
end

---@param rows pandoc.List<pandoc.List<contentCellWithContent | mergeCell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@param pandocRows pandoc.List<pandoc.Row> # Used to derive per-cell alignments.
---@return pandoc.List<pandoc.List<contentCellWithContentAlignment | mergeCell>>
local function setAlignments(rows, colAlignments, pandocRows)
  ---@cast rows pandoc.List<pandoc.List<contentCellWithContentAlignment | mergeCell>>

  for y = 1, #rows do
    local colIndex = 1
    for x = 1, #rows[y] do
      if rows[y][x].Type == "contentCell" then
        rows[y][x].Alignment = alignment.MakeCellAlignment(pandocRows[y].cells[colIndex], colAlignments[x])
        colIndex = colIndex + 1
      elseif rows[y][x].Type == "mergeCell" then
      else
        assert(false)
      end
    end
  end

  return rows
end

---@param rows pandoc.List<pandoc.List<contentCellWithContentAlignment | mergeCell>>
---@param colWidths pandoc.List<length | "max-content">
---@param colBorders pandoc.List<{ L: length, R: length }>
---@param source string|nil
---@return pandoc.List<pandoc.List<contentCellWithContentAlignmentWidth | mergeCell>>
local function setWidths(rows, colWidths, colBorders, source)
  ---@cast rows contentCellWithContentAlignmentWidth

  for y = 1, #rows do
    for x = 1, #rows[y] do
      if rows[y][x].Type == "contentCell" then
        local w = length.Zero()
        local anyMaxContentWidth = false
        local anyFixedWidth = false

        for i = 1, rows[y][x].ColSpan do
          local colBorder = colBorders[x + i - 1]
          w = length.Add(w, length.Add(colBorder.L, colBorder.R))

          local colWidth = colWidths[x + i - 1]
          if colWidth == "max-content" then
            anyMaxContentWidth = true
          elseif type(colWidth) == "table" then
            w = length.Add(w, colWidth)
            anyFixedWidth = true
          else
            assert(false)
          end
        end

        if anyMaxContentWidth and anyFixedWidth then
          log.Error("table has cell merging with a mix of fixed length and max-content columns", source)
          assert(false)
        elseif anyMaxContentWidth then
          rows[y][x].Width = "max-content"
        elseif anyFixedWidth then
          rows[y][x].Width = w
        else
          assert(false)
        end
      elseif rows[y][x].Type == "mergeCell" then
      else
        assert(false)
      end
    end
  end

  return rows
end

---@param rows pandoc.List<pandoc.List<contentCellWithContentAlignmentWidth | mergeCell>>
---@param rowBorders pandoc.List<{ T: length, B: length }>
---@param colBorders pandoc.List<{ L: length, R: length }>
---@return pandoc.List<pandoc.List<contentCellWithContentAlignmentWidthBorder | mergeCell>>
local function setBorders(rows, rowBorders, colBorders)
  ---@cast rows contentCellWithContentAlignmentWidthBorder

  for y = 1, #rows do
    for x = 1, #rows[y] do
      if rows[y][x].Type == "contentCell" then
        rows[y][x].Border = {
          T = rowBorders[y].T,
          B = rowBorders[y + rows[y][x].RowSpan - 1].B,
          L = colBorders[x].L,
          R = colBorders[x + rows[y][x].ColSpan - 1].R,
        }
      elseif rows[y][x].Type == "mergeCell" then
      else
        assert(false)
      end
    end
  end
  return rows
end

---@param pandocRows pandoc.List<pandoc.Row>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@param colWidths pandoc.List<length | "max-content">
---@param rowBorders pandoc.List<{ T: length, B: length }>
---@param colBorders pandoc.List<{ L: length, R: length }>
---@param source string|nil
---@return pandoc.List<pandoc.List<cell>>
local function makeRows(pandocRows, colAlignments, colWidths, rowBorders, colBorders, source)
  local rowCount = #pandocRows
  local colCount = #colAlignments

  local rows = makeNewRows(pandocRows, rowCount, colCount, source)
  rows = setAlignments(rows, colAlignments, pandocRows)
  rows = setWidths(rows, colWidths, colBorders, source)
  rows = setBorders(rows, rowBorders, colBorders)
  return rows
end

---@param c pandoc.Caption
---@param source string | nil
---@return pandoc.Inline | nil
local function getCaption(c, source)
  if c.short ~= nil and #c.short > 0 then
    log.Warning("table has a short caption, it is ignored", source)
  end
  local inlines = pandoc.utils.blocks_to_inlines(c.long, { pandoc.LineBreak() })
  return #inlines > 0 and merge(inlines) or nil
end

---@param x integer
---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@return pandoc.Inline
local function makeContentCellLatex(x, y, rows, colAlignments)
  local c = rows[y][x]
  assert(c.Type == "contentCell")
  ---@cast c contentCell

  local inline = merge(c.Content)

  if multirowcol.IsMultirow(c) then
    inline = multirowcol.MakeMultirowLatex(inline, c)
  end
  if multirowcol.IsMulticol(c, x, colAlignments) then
    inline = multirowcol.MakeMulticolLatex(inline, c)
  end

  return inline
end

---@param x integer
---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@return pandoc.Inline | nil
local function makeMergeCellLatex(x, y, rows, colAlignments)
  local c = rows[y][x]
  assert(c.Type == "mergeCell")
  ---@cast c mergeCell

  local ofC = rows[c.Of.Y][c.Of.X]
  assert(ofC.Type == "contentCell")
  ---@cast ofC contentCell

  if multirowcol.IsMultirow(ofC) and x == c.Of.X then
    local inline = merge({})

    if multirowcol.IsMulticol(ofC, c.Of.X, colAlignments) then
      inline = multirowcol.MakeMulticolLatex(inline, ofC)
    end

    return inline
  end

  return nil
end

---@param x integer
---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@return pandoc.Inline | nil
local function makeCellLatex(x, y, rows, colAlignments)
  local c = rows[y][x]

  if c.Type == "contentCell" then
    ---@cast c contentCell

    return makeContentCellLatex(x, y, rows, colAlignments)
  elseif c.Type == "mergeCell" then
    ---@cast c mergeCell

    return makeMergeCellLatex(x, y, rows, colAlignments)
  else
    assert(false)
  end
end

---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@return boolean
local function canRowPageBreak(y, rows)
  for x = 1, #rows[y] do
    local c = rows[y][x]

    if c.Type == "contentCell" then
      ---@cast c contentCell

      if multirowcol.IsMultirow(c) and y ~= y + c.RowSpan - 1 then
        return false
      end
    elseif c.Type == "mergeCell" then
      ---@cast c mergeCell

      local ofC = rows[c.Of.Y][c.Of.X]
      assert(ofC.Type == "contentCell")
      ---@cast ofC contentCell

      if multirowcol.IsMultirow(ofC) and y ~= c.Of.Y + ofC.RowSpan - 1 then
        return false
      end
    else
      assert(false)
    end
  end

  return true
end

---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@return { T: pandoc.Inline | nil, B: pandoc.Inline | nil }
local function makeRowBorderLatex(y, rows)
  local topWr = pandoc.List({})
  local bottomWr = pandoc.List({})

  for x = 1, #rows[y] do
    local c = rows[y][x]
    if c.Type == "contentCell" then
      ---@cast c contentCell
      topWr:insert(c.Border.T)
      bottomWr:insert(c.RowSpan == 1 and c.Border.B or length.Zero())
    elseif c.Type == "mergeCell" then
      ---@cast c mergeCell

      local ofC = rows[c.Of.Y][c.Of.X]
      assert(ofC.Type == "contentCell")
      ---@cast ofC contentCell

      topWr:insert(y == c.Of.Y and ofC.Border.T or length.Zero())
      bottomWr:insert(y == c.Of.Y + ofC.RowSpan - 1 and ofC.Border.B or length.Zero())
    else
      assert(false)
    end
  end

  return {
    T = border.MakeHorizontalLatex(topWr),
    B = border.MakeHorizontalLatex(bottomWr),
  }
end

---@param y integer
---@param rows pandoc.List<pandoc.List<cell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@param canPageBreak boolean
---@return pandoc.Inline
local function makeRowLatex(y, rows, canPageBreak, colAlignments)
  local cells = pandoc.Inlines({})
  for x = 1, #rows[y] do
    local c = makeCellLatex(x, y, rows, colAlignments)
    if c ~= nil then
      cells:insert(c)
    end
  end

  local rowBorder = makeRowBorderLatex(y, rows)
  local topBorder = rowBorder.T
  local bottomBorder = rowBorder.B

  return merge({
    topBorder ~= nil and merge({ topBorder, pandoc.Space() }) or merge({}),
    pandoc.Space(),
    merge(fun.Intersperse(cells, merge({ pandoc.Space(), raw([[&]]), pandoc.Space() }))),
    pandoc.Space(),
    canPageBreak and canRowPageBreak(y, rows) and raw([[\\]]) or raw([[\\*]]),
    bottomBorder ~= nil and merge({ pandoc.Space(), bottomBorder }) or merge({}),
  })
end

---@param rows pandoc.List<pandoc.List<cell>>
---@param colAlignments pandoc.List<"left" | "center" | "right">
---@param canPageBreak boolean
---@return pandoc.Inline | nil
local function makeRowsLatex(rows, colAlignments, canPageBreak)
  local inlines = pandoc.Inlines({})
  for y = 1, #rows do
    inlines:insert(makeRowLatex(y, rows, canPageBreak, colAlignments))
  end
  return #rows > 0 and merge(fun.Intersperse(inlines, raw("\n"))) or nil
end

---@param pandocTable pandoc.Table
---@param tableConfig tableConfig
---@return tbl
local function makeTable(pandocTable, tableConfig)
  local headPandocRows = pandocTable.head.rows
  local bodyPandocRows = fun.Flatten(pandocTable.bodies:map(function(b)
    if #b.head > 0 then
      log.Warning("table body has intermediate head, it is ignored", element.GetSource(b))
    end
    return b.body
  end))
  local footPandocRows = pandocTable.foot.rows

  local colAlignments = alignment.MakeColAlignments(pandocTable.colspecs)
  local colWidths = width.MakeColWidths(pandocTable.colspecs, element.GetSource(pandocTable))
  local colBorders = border.MakeColBorders(
    #pandocTable.colspecs,
    tableConfig.OuterBorderWidth,
    tableConfig.InnerBorderWidth,
    tableConfig.OuterBorderWidth
  )

  local headColAlignments = colAlignments:map(function(_)
    return "center"
  end)

  return {
    Id = pandocTable.attr.identifier,
    Caption = getCaption(pandocTable.caption, element.GetSource(pandocTable)),
    ColAlignments = colAlignments,
    ColWidths = colWidths,
    ColBorders = colBorders,
    FirstTopBorder = tableConfig.OuterBorderWidth,
    LastBottomBorder = length.Subtract(tableConfig.OuterBorderWidth, tableConfig.InnerBorderWidth),
    HeadRows = makeRows(
      headPandocRows,
      headColAlignments,
      colWidths,
      border.MakeRowBorders(
        #headPandocRows,
        length.Zero(),
        tableConfig.InnerBorderWidth,
        tableConfig.SeparateHead and tableConfig.OuterBorderWidth or tableConfig.InnerBorderWidth
      ),
      colBorders,
      element.GetSource(pandocTable)
    ),
    BodyRows = makeRows(
      bodyPandocRows,
      colAlignments,
      colWidths,
      border.MakeRowBorders(#bodyPandocRows, length.Zero(), tableConfig.InnerBorderWidth, tableConfig.InnerBorderWidth),
      colBorders,
      element.GetSource(pandocTable)
    ),
    FootRows = makeRows(
      footPandocRows,
      colAlignments,
      colWidths,
      border.MakeRowBorders(
        #footPandocRows,
        (
          tableConfig.SeparateFoot and length.Subtract(tableConfig.OuterBorderWidth, tableConfig.InnerBorderWidth)
          or length.Zero()
        ),
        tableConfig.InnerBorderWidth,
        tableConfig.InnerBorderWidth
      ),
      colBorders,
      element.GetSource(pandocTable)
    ),
  }
end

---@param id string
---@param caption pandoc.Inline | nil
---@return boolean
local function isNumberedCaption(id, caption)
  return id ~= "" or caption ~= nil
end

---@param id string
---@param caption pandoc.Inline | nil
---@return pandoc.Inline | nil
local function makeFirstHeadCaptionRowLatex(id, caption)
  if isNumberedCaption(id, caption) then
    return merge({
      raw([[\caption]]),
      raw([[{]]),
      caption ~= nil and caption or merge({}),
      raw([[}]]),
      (id ~= "" and merge({
        raw([[\label]]),
        raw([[{]]),
        pandoc.Str(id),
        raw([[}]]),
      }) or merge({})),
      pandoc.Space(),
      raw([[\\*]]),
    })
  else
    return nil
  end
end

---@param id string
---@param caption pandoc.Inline | nil
---@return pandoc.Inline
local function makeOtherHeadCaptionRowLatex(id, caption)
  if isNumberedCaption(id, caption) then
    return merge({
      raw([[\captionsetup{style=templateTableNumberedContinuation}]]),
      raw([[\caption[]{}]]),
      pandoc.Space(),
      raw([[\\*]]),
    })
  else
    return merge({
      raw([[\captionsetup{style=templateTableUnnumberedContinuation}]]),
      raw([[\caption*{}]]),
      pandoc.Space(),
      raw([[\\*]]),
    })
  end
end

---@param t tbl
---@param tableConfig tableConfig
local function makeTableLatex(t, tableConfig)
  local firstHeadCaptionRowLatex = makeFirstHeadCaptionRowLatex(t.Id, t.Caption)
  local otherHeadCaptionRowLatex = makeOtherHeadCaptionRowLatex(t.Id, t.Caption)
  local firstTopBorderLatex = border.MakeHorizontalLatex(pandoc.List({ t.FirstTopBorder }))
  local lastBottomBorderLatex = border.MakeHorizontalLatex(pandoc.List({ t.LastBottomBorder }))
  local headRowsLatex = makeRowsLatex(t.HeadRows, t.ColAlignments, false)
  local bodyRowsLatex = makeRowsLatex(t.BodyRows, t.ColAlignments, true)
  local footRowsLatex = makeRowsLatex(t.FootRows, t.ColAlignments, false)
  local hyphenateStartLatex = tableConfig.Hyphenate ~= nil
      and merge({
        raw([[\makeatletter]]),
        raw([[\template@hyphenation@save]]),
        tableConfig.Hyphenate and raw([[\template@hyphenation@enable]]) or raw([[\template@hyphenation@disable]]),
        raw([[\makeatother]]),
      })
    or nil
  local hyphenateEndLatex = tableConfig.Hyphenate ~= nil
      and merge({
        raw([[\makeatletter]]),
        raw([[\template@hyphenation@restore]]),
        raw([[\makeatother]]),
      })
    or nil

  return pandoc.Plain({
    hyphenateStartLatex ~= nil and merge({ hyphenateStartLatex, raw("\n") }) or merge({}),
    merge({
      raw([[\begin{longtable}]]),
      raw([[{]]),
      spec.MakeAllLatex(t.ColAlignments, t.ColWidths, t.ColBorders),
      raw([[}]]),
      raw("\n"),
    }),
    merge({ raw("\n") }),
    firstHeadCaptionRowLatex ~= nil and merge({ firstHeadCaptionRowLatex, raw("\n") }) or merge({}),
    firstTopBorderLatex ~= nil and merge({ firstTopBorderLatex, raw("\n") }) or merge({}),
    headRowsLatex ~= nil and merge({ headRowsLatex, raw("\n") }) or merge({}),
    merge({ raw([[\endfirsthead]]), raw("\n") }),
    merge({ raw("\n") }),
    merge({ otherHeadCaptionRowLatex, raw("\n") }),
    firstTopBorderLatex ~= nil and merge({ firstTopBorderLatex, raw("\n") }) or merge({}),
    (tableConfig.RepeatHead and headRowsLatex ~= nil) and merge({ headRowsLatex, raw("\n") }) or merge({}),
    merge({ raw([[\endhead]]), raw("\n") }),
    merge({ raw("\n") }),
    (tableConfig.RepeatFoot and footRowsLatex ~= nil) and merge({ footRowsLatex, raw("\n") }) or merge({}),
    lastBottomBorderLatex ~= nil and merge({ lastBottomBorderLatex, raw("\n") }) or merge({}),
    merge({ raw([[\endfoot]]), raw("\n") }),
    merge({ raw("\n") }),
    footRowsLatex ~= nil and merge({ footRowsLatex, raw("\n") }) or merge({}),
    lastBottomBorderLatex ~= nil and merge({ lastBottomBorderLatex, raw("\n") }) or merge({}),
    merge({ raw([[\endlastfoot]]), raw("\n") }),
    merge({ raw("\n") }),
    bodyRowsLatex ~= nil and merge({ bodyRowsLatex, raw("\n") }) or merge({}),
    merge({ raw("\n") }),
    merge({ raw([[\end{longtable}]]) }),
    hyphenateEndLatex ~= nil and merge({ hyphenateEndLatex, raw("\n") }) or merge({}),
  })
end

---@param t pandoc.Table
---@return tableConfig
local function makeTableConfig(t)
  local separateHead = false
  if t.attr.attributes["template-table-separate-head"] ~= nil then
    separateHead = t.attr.attributes["template-table-separate-head"] == "1"
  end
  local repeatHead = true
  if t.attr.attributes["template-table-repeat-head"] ~= nil then
    repeatHead = t.attr.attributes["template-table-repeat-head"] == "1"
  end
  local separateFoot = false
  if t.attr.attributes["template-table-separate-foot"] ~= nil then
    separateFoot = t.attr.attributes["template-table-separate-foot"] == "1"
  end
  local repeatFoot = false
  if t.attr.attributes["template-table-repeat-foot"] ~= nil then
    repeatFoot = t.attr.attributes["template-table-repeat-foot"] == "1"
  end
  local hyphenate = nil
  if t.attr.attributes["template-table-hyphenate"] ~= nil then
    hyphenate = t.attr.attributes["template-table-hyphenate"] == "1"
  end

  return {
    OuterBorderWidth = { pt = 1 },
    InnerBorderWidth = { pt = 0.5 },
    SeparateHead = separateHead,
    RepeatHead = repeatHead,
    SeparateFoot = separateFoot,
    RepeatFoot = repeatFoot,
    Hyphenate = hyphenate,
  }
end

---@param pandocTable pandoc.Table
---@return pandoc.Block
function table_.MakeLatex(pandocTable)
  local tableConfig = makeTableConfig(pandocTable)
  local t = makeTable(pandocTable, tableConfig)
  return makeTableLatex(t, tableConfig)
end

return table_
