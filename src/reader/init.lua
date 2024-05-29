local log = require("internal.log")
local length = require("internal.length")
local element = require("internal.element")

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
local function read(input, options)
  return pandoc.read(input, {
    format = "commonmark",
    extensions = {
      -- GFM extensions.
      autolink_bare_uris = true, -- https://github.github.com/gfm/#autolinks-extension-
      footnotes = true, -- https://github.blog/changelog/2021-09-30-footnotes-now-supported-in-markdown-fields/
      pipe_tables = true, -- https://github.github.com/gfm/#tables-extension-
      strikeout = true, -- https://github.github.com/gfm/#strikethrough-extension-
      task_lists = true, -- https://github.github.com/gfm/#task-list-items-extension-
      -- Must-have extensions.
      attributes = true,
      tex_math_dollars = true,
      -- Handy extensions.
      fenced_divs = true,
      bracketed_spans = true,
      implicit_figures = true, -- TODO: Replace with a custom filter.
      smart = true,
      sourcepos = true,
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

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
local function readHtml(input, options)
  return pandoc.read(input, {
    format = "html",
    extensions = {
      auto_identifiers = false,
      empty_paragraphs = true,
      line_blocks = false,
      smart = true,
      task_lists = true,
      tex_math_dollars = true,
    },
  }, options)
end

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Blocks
local function readHtmlBlocks(input, options)
  return readHtml(input, options).blocks
end

---@param input string | pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Inlines
local function readHtmlInlines(input, options)
  return pandoc.utils.blocks_to_inlines(readHtmlBlocks(input, options))
end

---@param sources pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
function Reader(sources, options)
  local d = read(sources, options)

  d = d:walk({
    ---@param b RawBlock
    ---@return RawBlock | Blocks
    RawBlock = function(b)
      if b.format == "html" then
        return readHtmlBlocks(b.text, options)
      end
      return b
    end,
    ---@param i RawInline
    ---@return RawInline | Inlines
    RawInline = function(i)
      if i.format == "html" then
        return readHtmlInlines(i.text, options)
      end
      return i
    end,
  })

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

  -- hyphenate
  -- no-hyphenate
  d = d:walk({
    ---@param t Table
    ---@return Table
    Table = function(t)
      local flags = { "hyphenate", "repeat-head", "repeat-foot", "separate-head", "separate-foot" }
      local flagToValue = {}

      for _, c in ipairs(t.attr.classes) do
        for _, flag in ipairs(flags) do
          if c == flag then
            flagToValue[flag] = true
          elseif c == "no-" .. flag then
            flagToValue[flag] = false
          end
        end
      end

      for flag, value in pairs(flagToValue) do
        t.attr.attributes["template-table-" .. flag] = value and "1" or "0"
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

          local cellWidthString = c.attr.attributes["width"]

          ---@type Plain | nil
          local p = (
            #c.contents == 1
            and (c.contents[1] --[[@as Plain | Block]]).tag == "Plain"
            and c.contents[1] --[[@as Plain]]
          ) or nil

          ---@type Span | nil
          local s = (
            p ~= nil
            and #p.content == 1
            and (p.content[1] --[[@as Span | Inline]]).tag == "Span"
            and p.content[1] --[[@as Span]]
          ) or nil

          local spanWidthString = s and s.attr.attributes["width"] or nil

          local colWidthString
          if cellWidthString and cellWidthString ~= nil and spanWidthString and spanWidthString ~= nil then
            log.Warning(
              "table column has width specified in the head cell and the head cell's span, only the head cell one is used",
              element.GetSource(t)
            )
            colWidthString = cellWidthString
          elseif cellWidthString and cellWidthString ~= nil then
            colWidthString = cellWidthString
          elseif spanWidthString and spanWidthString ~= nil then
            colWidthString = spanWidthString
          else
            goto continue
          end
          assert(type(colWidthString) == "string")

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
