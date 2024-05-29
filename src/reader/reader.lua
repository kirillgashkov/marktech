---@param options pandoc.ReaderOptions
---@return { read: fun(input: (string | pandoc.Sources)): pandoc.Pandoc }
local function makeMarkdownReader(options)
  return {
    ---@param input string | pandoc.Sources
    ---@return pandoc.Pandoc
    read = function(input)
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
    end,
  }
end

---@param options pandoc.ReaderOptions
---@return { read: fun(input: (string | pandoc.Sources)): pandoc.Pandoc }
local function makeHtmlReader(options)
  return {
    ---@param input string | pandoc.Sources
    ---@return pandoc.Pandoc
    read = function(input)
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
    end,
  }
end

---@param sources pandoc.Sources
---@param options pandoc.ReaderOptions
---@return pandoc.Pandoc
function Reader(sources, options)
  local reader = makeMarkdownReader(options)
  local htmlReader = makeHtmlReader(options)

  local d = reader.read(sources)

  d = d:walk({
    ---@param e pandoc.RawBlock
    ---@return pandoc.Blocks | pandoc.RawBlock
    RawBlock = function(e)
      return require("reader.internal.rawblock.rawblock").EmbedHtml(e, htmlReader)
    end,
    ---@param e pandoc.RawInline
    ---@return pandoc.RawInline | pandoc.Inlines
    RawInline = function(e)
      return require("reader.internal.rawinline.rawinline").EmbedHtml(e, htmlReader)
    end,
  })

  d = require("reader.internal.document.document").SetWidths(d)

  local table_ = require("reader.internal.table.table")
  d = d:walk({
    Table = function(t)
      t = table_.SetConfig(t)
      t = table_.SetCaption(t, reader)
      t = table_.SetColSpecs(t)
      return t
    end,
  })

  return d
end
