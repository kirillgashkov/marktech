assert(tostring(PANDOC_API_VERSION) == "1.23.1", "Unsupported Pandoc API")

local file = require("internal.file")
local element = require("internal.element")
local table_ = require("internal.table.table")

---@param d Pandoc
---@param options WriterOptions
---@return string
function Writer(d, options)
	d = d:walk({
		---@param t Table
		---@return Block
		Table = function(t)
			return table_.MakeLatex(t)
		end,
	})
	d = element.RemoveMerges(d)

	if options.variables["template_debug"] ~= nil and options.variables["template_debug"]:render() == "1" then
		io.stderr:write(pandoc.write(d, "native", options))
	end
	return pandoc.write(d, "latex", options)
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
