local file = require("internal.file")
local fun = require("internal.fun")
local log = require("internal.log")
local alignment = require("internal.table.alignment")
local width = require("internal.table.width")
local border = require("internal.table.border")
local multirowcol = require("internal.table.multirowcol")
local spec = require("internal.table.spec")
local element = require("internal.element")
local length = require("internal.table.length")

local merge = element.Merge
local mergeBlock = element.MergeBlock
local raw = element.Raw
local md = element.Md

local table_ = {}

---@param pandocRows List<Row>
---@param rowCount integer
---@param colCount integer
---@param source string|nil
---@return List<List<contentCellWithContent | mergeCell>>
local function makeNewRows(pandocRows, rowCount, colCount, source)
  ---@type List<List<contentCellWithContent | mergeCell | nil>>
  local rows = pandoc.List({})
  for _ = 1, rowCount do
    ---@type List<contentCellWithContent | mergeCell | nil>
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

        for y_offset = 0, cell.row_span do
          for x_offset = 0, cell.col_span do
            if y + y_offset > rowCount then
              log.Error("the table has a cell that spans beyond the row count", source)
              assert(false)
            end
            if x + x_offset > colCount then
              log.Error("the table has a cell that spans beyond the column count", source)
              assert(false)
            end
            assert(rows[y + y_offset][x + x_offset] == nil)

            local c
            if y_offset == 0 and x_offset == 0 then
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
            rows[y + y_offset][x + x_offset] = c
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

---@param rows List<List<contentCellWithContent | mergeCell>>
---@param colAlignments List<"left" | "center" | "right">
---@param pandocRows List<Row> # Used to derive per-cell alignments.
---@return List<List<contentCellWithContentAlignment | mergeCell>>
local function setAlignments(rows, colAlignments, pandocRows)
  ---@cast rows List<List<contentCellWithContentAlignment | mergeCell>>

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

---@param rows List<List<contentCellWithContentAlignment | mergeCell>>
---@param colWidths List<length | nil>
---@param colBorders List<{ L: length, R: length }>
---@param source string|nil
---@return List<List<contentCellWithContentAlignmentWidth | mergeCell>>
local function setWidths(rows, colWidths, colBorders, source)
  ---@cast rows contentCellWithContentAlignmentWidth

  for y = 1, #rows do
    for x = 1, #rows[y] do
      if rows[y][x].Type == "contentCell" then
        local w = length.Zero()
        local anyMaxWidth = false
        local anyFixedWidth = false

        for i = 1, rows[y][x].ColSpan do
          local colBorder = colBorders[x + i - 1]
          w = length.Add(w, length.Add(colBorder.L, colBorder.R))

          local colWidth = colWidths[x + i - 1]
          if colWidth == nil then
            anyMaxWidth = true
          elseif type(colWidth) == "table" then
            w = length.Add(w, colWidth)
            anyFixedWidth = true
          else
            assert(false)
          end
        end

        if anyMaxWidth and anyFixedWidth then
          log.Error("the table has cell merging with a mix of fixed and max-width columns", source)
          assert(false)
        elseif anyMaxWidth then
          rows[y][x].Width = nil
        elseif anyFixedWidth then
          rows[y][x].Width = width
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

---@param rows List<List<contentCellWithContentAlignmentWidth | mergeCell>>
---@param rowBorders List<{ T: length, B: length }>
---@param colBorders List<{ L: length, R: length }>
---@return List<List<contentCellWithContentAlignmentWidthBorder | mergeCell>>
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

---@param pandocRows List<Row>
---@param colAlignments List<"left" | "center" | "right">
---@param colWidths List<length | nil>
---@param rowBorders List<{ T: length, B: length }>
---@param colBorders List<{ L: length, R: length }>
---@param source string|nil
---@return List<List<cell>>
local function makeRows(pandocRows, colAlignments, colWidths, rowBorders, colBorders, source)
  local rowCount = #pandocRows
  local colCount = #colAlignments

  local rows = makeNewRows(pandocRows, rowCount, colCount, source)
  rows = setAlignments(rows, colAlignments, pandocRows)
  rows = setWidths(rows, colWidths, colBorders, source)
  rows = setBorders(rows, rowBorders, colBorders)
  return rows
end

---@param c Caption
---@param source string | nil
---@return Inline | nil
local function getCaption(c, source)
  if c.short ~= nil and #c.short > 0 then
    log.Warning("table has a short caption, it is ignored", source)
  end
  local inlines = pandoc.utils.blocks_to_inlines(c.long, { pandoc.LineBreak() })
  return #inlines > 0 and merge(inlines) or nil
end

---@param x integer
---@param y integer
---@param rows List<List<cell>>
---@param colAlignments List<"left" | "center" | "right">
---@param config config
---@return Inline
local function makeContentCellLatex(x, y, rows, colAlignments, config)
  local c = rows[y][x]
  assert(c.Type == "contentCell")
  ---@cast c contentCell

  local inlines = c.Content

  if multirowcol.IsMultirow(c) then
    inlines = multirowcol.MakeMultirowLatex(inlines, c)
  end
  if multirowcol.IsMulticol(c, x, colAlignments) then
    inlines = multirowcol.MakeMulticolLatex(inlines, c, config)
  end

  return merge(inlines)
end

---@param x integer
---@param y integer
---@param rows List<List<cell>>
---@param colAlignments List<"left" | "center" | "right">
---@param config config
---@return Inline | nil
local function makeMergeCellLatex(x, y, rows, colAlignments, config)
  local c = rows[y][x]
  assert(c.Type == "mergeCell")
  ---@cast c mergeCell

  local ofC = rows[c.Of.Y][c.Of.X]
  assert(ofC.Type == "contentCell")
  ---@cast ofC contentCell

  if multirowcol.IsMultirow(ofC) and x == c.Of.X then
    local inlines = pandoc.Inlines({})

    if multirowcol.IsMulticol(ofC, c.Of.X, colAlignments) then
      inlines = multirowcol.MakeMulticolLatex(inlines, ofC, config)
    end

    return merge(inlines)
  end

  return nil
end

---@param x integer
---@param y integer
---@param rows List<List<cell>>
---@param colAlignments List<"left" | "center" | "right">
---@param config config
---@return Inline | nil
local function makeCellLatex(x, y, rows, colAlignments, config)
  local c = rows[y][x]

  if c.Type == "contentCell" then
    ---@cast c contentCell

    return makeContentCellLatex(x, y, rows, colAlignments, config)
  elseif c.Type == "mergeCell" then
    ---@cast c mergeCell

    return makeMergeCellLatex(x, y, rows, colAlignments, config)
  else
    assert(false)
  end
end

---@param y integer
---@param rows List<List<cell>>
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
---@param rows List<List<cell>>
---@param config config
---@return { T: Inline, B: Inline }
local function makeRowBorderLatex(y, rows, config)
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
    T = border.MakeHorizontalLatex(topWr, config),
    B = border.MakeHorizontalLatex(bottomWr, config),
  }
end

---@param y integer
---@param rows List<List<cell>>
---@param colAlignments List<"left" | "center" | "right">
---@param canPageBreak boolean
---@param config config
---@return Inline
local function makeRowLatex(y, rows, canPageBreak, colAlignments, config)
  local cells = pandoc.Inlines({})
  for x = 1, #rows[y] do
    local c = makeCellLatex(x, y, rows, colAlignments, config)
    if c ~= nil then
      cells:insert(c)
    end
  end

  local rowBorder = makeRowBorderLatex(y, rows, config)
  local topBorder = rowBorder.T
  local bottomBorder = rowBorder.B

  return merge({
    topBorder,
    pandoc.Space(),
    merge(fun.Intersperse(cells, merge({ pandoc.Space(), element.raw([[&]]), pandoc.Space() }))),
    pandoc.Space(),
    canPageBreak and canRowPageBreak(y, rows) and element.raw([[\\]]) or element.raw([[\\*]]),
    pandoc.Space(),
    bottomBorder,
  })
end

---@param rows List<List<cell>>
---@param colAlignments List<"left" | "center" | "right">
---@param canPageBreak boolean
---@param config config
---@return Inline
local function makeRowsLatex(rows, colAlignments, canPageBreak, config)
  local inlines = pandoc.Inlines({})
  for y = 1, #rows do
    inlines:insert(makeRowLatex(y, rows, canPageBreak, colAlignments, config))
  end
  return merge(fun.Intersperse(inlines, element.raw("\n")))
end

---@param pandocTable Table
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
  local colWidths = width.MakeColWidths(pandocTable.colspecs)
  local colBorders = border.MakeColBorders(
    #pandocTable.colspecs,
    tableConfig.OuterBorderWidth,
    tableConfig.InnerBorderWidth,
    tableConfig.OuterBorderWidth
  )

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
      colAlignments,
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
---@param caption Inline | nil
---@return boolean
local function isNumberedCaption(id, caption)
  return id ~= "" or caption ~= nil
end

---@param id string
---@param caption Inline | nil
---@return Inline | nil
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
---@param caption Inline | nil
---@return Inline
local function makeOtherHeadCaptionRowLatex(id, caption)
  if isNumberedCaption(id, caption) then
    return merge({
      raw([[\captionsetup{style=customNumberedTableContinuation}]]),
      raw([[\caption[]{}]]),
      pandoc.Space(),
      raw([[\\*]]),
    })
  else
    return merge({
      raw([[\captionsetup{style=customUnnumberedTableContinuation}]]),
      raw([[\caption*{}]]),
      pandoc.Space(),
      raw([[\\*]]),
    })
  end
end

---@param t tbl
---@param tableConfig tableConfig
---@param config config
local function makeTableLatex(t, tableConfig, config)
  local firstHeadCaptionRowLatex = makeFirstHeadCaptionRowLatex(t.Id, t.Caption)
  local otherHeadCaptionRowLatex = makeOtherHeadCaptionRowLatex(t.Id, t.Caption)
  local firstTopBorderLatex = border.MakeHorizontalLatex(pandoc.List({ t.FirstTopBorder }), config)
  local lastBottomBorderLatex = border.MakeHorizontalLatex(pandoc.List({ t.LastBottomBorder }), config)
  local headRowsLatex = makeRowsLatex(t.HeadRows, t.ColAlignments, false, config)
  local bodyRowsLatex = makeRowsLatex(t.HeadRows, t.ColAlignments, true, config)
  local footRowsLatex = makeRowsLatex(t.HeadRows, t.ColAlignments, false, config)

  return pandoc.Plain({
    merge({
      raw([[\begin{longtable}]]),
      raw([[{]]),
      spec.MakeAllLatex(t.ColAlignments, t.ColWidths, t.ColBorders, config),
      raw([[}]]),
      raw("\n"),
    }),
    merge({ raw("\n") }),
    firstHeadCaptionRowLatex ~= nil and merge({ firstHeadCaptionRowLatex, raw("\n") }) or merge({}),
    merge({ firstTopBorderLatex, raw("\n") }),
    merge({ headRowsLatex, raw("\n") }),
    merge({ raw([[\endfirsthead]]), raw("\n") }),
    merge({ otherHeadCaptionRowLatex, raw("\n") }),
    merge({ firstTopBorderLatex, raw("\n") }),
    tableConfig.RepeatHead and merge({ headRowsLatex, raw("\n") }) or merge({}),
    merge({ raw([[\endhead]]), raw("\n") }),
    tableConfig.RepeatFoot and merge({ footRowsLatex, raw("\n") }) or merge({}),
    merge({ lastBottomBorderLatex, raw("\n") }),
    merge({ raw([[\endfoot]]), raw("\n") }),
    merge({ footRowsLatex, raw("\n") }),
    merge({ lastBottomBorderLatex, raw("\n") }),
    merge({ raw([[\endlastfoot]]), raw("\n") }),
    merge({ raw("\n") }),
    merge({ bodyRowsLatex, raw("\n") }),
    merge({ raw("\n") }),
    merge({ raw([[\end{longtable}]]) }),
  })
end

---@param t Table
---@return Block
function table_.MakeLatex(t)
  local tableConfig = {
    OuterBorderWidth = { Pt = 1 },
    InnerBorderWidth = { Pt = 0.5 },
    SeparateHead = false,
    RepeatHead = false,
    SeparateFoot = false,
    RepeatFoot = false,
  }
  local table = makeTable(t, tableConfig)
  local config = {
    ArrayRuleWidth = { Pt = 0.4 },
  }
  return makeTableLatex(table, tableConfig, config)
end

return table_
