---@param sources pandoc.Sources
---@param options pandoc.ReaderOptions
---@return Pandoc
function Reader(sources, options)
	local d = pandoc.read(sources, {
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
		},
	}, options)

	return d
end
