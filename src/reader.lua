local log = require("internal.log")
local element = require("internal.element")
local length = require("internal.table.length")

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
local function read(input, options)
  return pandoc.read(input, {
    format = "commonmark",
    extensions = {
      -- GFM extensions.
      "autolink_bare_uris", -- https://github.github.com/gfm/#autolinks-extension-
      "footnotes", -- https://github.blog/changelog/2021-09-30-footnotes-now-supported-in-markdown-fields/
      "pipe_tables", -- https://github.github.com/gfm/#tables-extension-
      "strikeout", -- https://github.github.com/gfm/#strikethrough-extension-
      "task_lists", -- https://github.github.com/gfm/#task-list-items-extension-
      -- Must-have extensions.
      "attributes",
      "tex_math_dollars",
      -- Handy extensions.
      "fenced_divs",
      "bracketed_spans",
      "implicit_figures", -- TODO: Replace with a custom filter.
      "smart",
      "sourcepos",
    },
  }, options)
end

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Blocks
local function readBlocks(input, options)
  return read(input, options).blocks
end

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Inlines
local function readInlines(input, options)
  return pandoc.utils.blocks_to_inlines(readBlocks(input, options))
end

---@param sources pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
function Reader(sources, options)
  local d = read(sources, options)

  d = element.SetWidths(d)
  d = d:walk({
    ---@param t Table
    ---@return Table
    Table = function(t)
      local captionString = t.attr.attributes["caption"] or ""

      if captionString ~= "" then
        if #t.caption.long > 0 or t.caption.short ~= nil and #t.caption.short > 0 then
          log.Warning("table already has a caption, the caption attribute will take precedence", element.GetSource(t))
        end

        t.caption = { long = readBlocks(captionString, options), short = pandoc.Inlines({}) }
      end

      return t
    end,
  })
  d = d:walk({
    ---@param t Table
    ---@return Table
    Table = function(t)
      if t.attr.attributes["width"] and t.attr.attributes["width"] ~= "" then
        log.Warning("table width is ignored", element.GetSource(t))
        log.Note("use column widths instead", element.GetSource(t))
      end

      -- Resets the column widths to be equal and in sum amount to 80%. The
      -- default reader infers the column widths from the source with the
      -- --columns option taken into account. This is not as deterministic as we
      -- would like, so we perform a reset.
      for i = 1, #t.colspecs do
        t.colspecs[i][2] = 0.8 / #t.colspecs
      end

      ---@type List<List<number | "max-content">>
      local colToWidthsFromHead = pandoc.List({})
      for _ = 1, #t.colspecs do
        colToWidthsFromHead:insert(pandoc.List({}))
      end

      for rowIndex = 1, #t.head.rows do
        local r = t.head.rows[rowIndex]
        local colIndexStart = 0
        local colIndexEnd = 0
        for cellIndex = 1, #r.cells do
          local c = r.cells[cellIndex]
          colIndexStart = colIndexEnd + 1
          colIndexEnd = colIndexStart + c.col_span - 1

          if #c.contents ~= 1 then
            goto continue
          end

          ---@type Plain | Block
          local p = c.contents[1]
          if p.tag ~= "Plain" then
            goto continue
          end
          ---@cast p Plain

          if #p.content ~= 1 then
            goto continue
          end

          ---@type Span | Inline
          local s = p.content[1]
          if s.tag ~= "Span" then
            goto continue
          end
          ---@cast s Span

          if not s.attr.attributes["width"] or s.attr.attributes["width"] == "" then
            goto continue
          end
          local colWidthString = s.attr.attributes["width"]

          -- It would be better to use number | nil here but when subColWidth is
          -- nil, colToWidthsFromHead[i]:insert(subColWidth) from below won't
          -- insert anything.
          ---@type number | "max-content"
          local subColWidth
          if colWidthString == "max-content" then
            subColWidth = "max-content"
          else
            local parsedColWidth = length.Parse(colWidthString)
            if parsedColWidth ~= nil then
              for u, v in pairs(parsedColWidth) do
                if u == "%" then
                  subColWidth = v / (colIndexStart - colIndexEnd + 1) / 100
                else
                  log.Warning("table column has width unit other than %, it is ignored", element.GetSource(t))
                  break
                end
              end
            else
              log.Warning("table column has invalid width, it is ignored", element.GetSource(t))
              break
            end
          end

          for i = colIndexStart, colIndexEnd do
            colToWidthsFromHead[i]:insert(subColWidth)
          end

          ::continue::
        end
      end

      for i = 1, #t.colspecs do
        local widths = colToWidthsFromHead[i]
        if #widths == 0 then
          goto continue
        end
        if #widths > 1 then
          log.Warning(
            "table column has multiple widths specified in the head, only the first one is used",
            element.GetSource(t)
          )
        end

        local w = widths[1]
        if type(w) == "number" then
          ---@cast w number
          t.colspecs[i][2] = w
        elseif w == "max-content" then
          t.colspecs[i][2] = nil
        else
          assert(false)
        end

        ::continue::
      end

      return t
    end,
  })

  return d
end
