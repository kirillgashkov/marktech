local log = require("internal.log")
local element = require("internal.element")

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

  return d
end
