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

---@generic T
---@param iterable any[][]
---@return any[]
function M.flatten(iterable)
	return M.reduce(function(flattened, a)
		for _, v in ipairs(a) do
			table.insert(flattened, v)
		end
		return flattened
	end, iterable, {})
end

return M
