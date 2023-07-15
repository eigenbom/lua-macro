--##
-- Example of compile-time tuple type
-- that expands to multiple parameters and return values

---@generic T
---@param a_1 T
---@param a_2 T
---@param a_3 T
---@param b_1 T
---@param b_2 T
---@param b_3 T
---@return T, T, T
local function vec3_add(a_1, a_2, a_3, b_1, b_2, b_3)
	return a_1 + b_1, a_2 + b_2, a_3 + b_3 --[[ tuple ]]
end

local x_1, x_2, x_3, y_1, y_2, y_3 = 1, 0, 0 --[[ tuple ]], 0, 1, 0 --[[ tuple ]]
local sum_1, sum_2, sum_3 = vec3_add(x_1, x_2, x_3, y_1, y_2, y_3)

print("sum: ", sum_1, sum_2, sum_3)