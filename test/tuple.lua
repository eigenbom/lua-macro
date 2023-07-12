-- Example of compile-time tuple type
-- that expands to multiple parameters and return values
require 'macro'

macro.do_()
function post_process(file_contents)
	local result = file_contents

	local function expand_index(a, index)
		return a .. "_" .. index
	end

	local function expand_tuple(a)
		return expand_index(a,1), expand_index(a,2), expand_index(a,3)
	end

	-- NB: We use tuple_ prefix to identify tuple types
	-- You could expand this to use a special character like $ if your language server allows it

	result = result:gsub("---@param tuple_(%w+) tuple3(%b<>)", function(a, b)
		local type = b:sub(2,-2)
		local a1, a2, a3 = expand_tuple(a)
		local p = "---@param %s " .. type .. "\n"
		return p:format(a1) .. p:format(a2) .. p:format(a3):sub(1,-2)
	end)

	result = result:gsub("tuple3(%b<>)", function(a)
		local type = a:sub(2,-2)
		return type .. ", " .. type .. ", " .. type
	end)

	result = result:gsub("tuple_(%w+)(%b[])", function(a,b)
		return expand_index(a, b:sub(2,-2))
	end)

	result = result:gsub("tuple_(%w+)", function(a)
		return table.concat({expand_tuple(a)}, ", ")
	end)

	result = result:gsub("tuple3(%b())", function(a)
		return a:sub(2,-2) .. " --[[ tuple ]]"
	end)

	return result
end

---Mock tuple3 type and constructor
-- used to satisfy lua IDE and type checking
-- but removed at build-time

---@alias tuple3<T> T[]

---@generic T
---@return tuple3<T>
local function tuple3(a,b,c)
	return {a, b, c}
end

macro.end_()

---@generic T
---@param tuple_a tuple3<T>
---@param tuple_b tuple3<T>
---@return tuple3<T>
local function vec3_add(tuple_a, tuple_b)
	return tuple3(tuple_a[1] + tuple_b[1], tuple_a[2] + tuple_b[2], tuple_a[3] + tuple_b[3])
end

local tuple_x = tuple3(1, 0, 0)
local tuple_y = tuple3(0, 1, 0)
local tuple_sum = vec3_add(tuple_x, tuple_y)

print("sum: ", tuple_sum)