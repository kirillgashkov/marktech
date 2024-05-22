local M = {}

---@generic T
---@param f function
---@param iterable any[]
---@param initial T
---@return T
function M.reduce(f, iterable, initial)
	local reduced = initial
	for _, v in ipairs(iterable) do
		reduced = f(reduced, v)
	end
	return reduced
end

return M
