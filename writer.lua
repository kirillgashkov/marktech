local file = require("file")
local log = require("log")

assert(tostring(PANDOC_API_VERSION) == "1.23.1", "Unsupported Pandoc API")

local filter = {}

---@param t Table
filter.Table = function(t)
	return t
end

---@param doc Pandoc
---@param opts WriterOptions
---@return string
function Writer(doc, opts)
	return pandoc.write(doc:walk(filter), "latex", opts)
end

---@return string
function Template()
	local scriptDir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
	local templateFile = pandoc.path.join({ scriptDir, "template.tex" })
	local template = file.Read(templateFile)
	assert(template ~= nil)
	return template
end

---@type { [string]: boolean }
Extensions = {}
