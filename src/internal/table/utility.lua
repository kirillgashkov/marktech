local utility = {}

---@param w number
---@return string
function utility.MakeFixedWidthLatex(w)
	return string.format("%.4f", w) .. "pt"
end

---@param w number
---@return string
function utility.MakePercentWidthLatex(w)
	return "(" .. "\\real{" .. string.format("%.4f", w) .. "}" .. " * " .. "\\columnwidth" .. ")"
end

return utility
