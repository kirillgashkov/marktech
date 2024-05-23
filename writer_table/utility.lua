local utility = {}

---@param w number
---@return string
function utility.MakeFixedWidthLatexString(w)
	return string.format("%.4f", w) .. "pt"
end

return utility
