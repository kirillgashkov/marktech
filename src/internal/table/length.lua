local log = require("internal.log")

local length = {}

---@param a length
---@param b length
---@return length
function length.Add(a, b)
	local c = a
	for u, v in pairs(b) do
		c[u] = (c[u] or 0) + v
	end
	return c
end

---@param a length
---@param b length
---@return length
function length.Subtract(a, b)
	local c = a
	for u, v in pairs(b) do
		c[u] = (c[u] or 0) - v
	end
	return c
end

---@param a length
---@param b length
---@return boolean
function length.IsEqual(a, b)
	local units = {}
	for u, _ in pairs(a) do
		units[u] = true
	end
	for u, _ in pairs(b) do
		units[u] = true
	end
	for u, _ in pairs(units) do
		local av = a[u] or 0
		local bv = b[u] or 0
		if av ~= bv then
			return false
		end
	end
	return true
end

---@return length
function length.Zero()
	return {}
end

---@param l length
---@return boolean
function length.IsZero(l)
	return length.IsEqual(l, length.Zero())
end

---@param l length
---@return string
function length.MakeWidthLatex(l)
	-- Every value is enclosed in parentheses to avoid issues with negative values.
	local values = {}
	for u, v in pairs(l) do
		if u == "pt" then
			table.insert(values, "(" .. string.format("%.4f", v) .. "pt" .. ")")
		elseif u == "%" then
			table.insert(values, "(" .. "\\real{" .. string.format("%.4f", v) .. "}" .. " * " .. "\\textwidth" .. ")")
		else
			log.Error("unsupported width unit: " .. u)
			assert(false)
		end
	end
	return #values == 0 and "0pt" or table.concat(values, " + ")
end

---@param l length
---@return string
function length.MakeHeightLatex(l)
	local values = {}
	for u, v in pairs(l) do
		if u == "pt" then
			table.insert(values, string.format("%.4f", v) .. "pt")
		else
			log.Error("unsupported height unit: " .. u)
			assert(false)
		end
	end
	return table.concat(values, " + ")
end

---@param l length
---@return string
function length.MakeLengthLatex(l)
	local values = {}
	for u, v in pairs(l) do
		if u == "pt" then
			table.insert(values, string.format("%.4f", v) .. "pt")
		else
			log.Error("unsupported length unit: " .. u)
			assert(false)
		end
	end
	return table.concat(values, " + ")
end

return length
