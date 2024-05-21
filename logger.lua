M = {}

---@param source string
---@param type "error" | "warning" | "note"
---@param message string
---@param code? string|nil
---@param format? "text"|"json"
function M.log(source, type, message, code, format)
	if format == "json" then
		io.stderr:write(pandoc.json.encode({ source = source, type = type, message = message, code = code }) .. "\n")
		return
	end

	local reset_color = "\27[0m"
	local code_color = "\27[35m"
	local type_color
	if type == "note" then
		type_color = "\27[34m\27[1m"
	elseif type == "warning" then
		type_color = "\27[33m\27[1m"
	elseif type == "error" then
		type_color = "\27[31m\27[1m"
	else
		assert(false)
	end

	local m = source .. ": " .. type_color .. type .. ": " .. reset_color .. message
	if code ~= nil then
		m = m .. " " .. code_color .. "[" .. code .. "]" .. reset_color .. "\n"
	end
	m = m .. "\n"

	io.stderr:write(m)
end

return M
