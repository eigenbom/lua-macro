--##
-- Example of compile-time tuple type
-- that expands to multiple parameters and return values
require 'macro'

macro.do_()
function post_process(file_contents)
	local result = file_contents

	local function expand_index(a, index)
		return a .. "_" .. index
	end

	local function expand_tuple(a, size)
		local args = {}
		for i=1,size do
			args[i] = expand_index(a, i)
		end
		return args
	end

	result = result:gsub("---@param $(%w+) tuple(%b<>)", function(a, b)
		local tuple_param = b:sub(2,-2) --[[@as string]]
		-- split tuple_param by comma
		local comma = tuple_param:find(",")
		local type, size = tuple_param:sub(1, comma-1), tuple_param:sub(comma+1)
		local args = expand_tuple(a, size)
		local p = "---@param %s " .. type .. "\n"
		for i=1,#args do
			args[i] = p:format(args[i])
		end
		return table.concat(args):sub(1,-2)
	end)

	result = result:gsub("tuple(%b<>)", function(a)
		local tuple_param = a:sub(2,-2)
		local comma = tuple_param:find(",")
		local type, size = tuple_param:sub(1, comma-1), tuple_param:sub(comma+1)
		return string.rep(type, size, ", ")
	end)

	result = result:gsub("$(%w+)(%b[])", function(a,b)
		return expand_index(a, b:sub(2,-2))
	end)

	result = result:gsub("$(%w+)", function(a)
		return table.concat(expand_tuple(a, 3), ", ")
	end)

	result = result:gsub("tuple3(%b())", function(a)
		return a:sub(2,-2) .. " --[[ tuple ]]"
	end)

	return result
end

---Mock tuple3 type and constructor
-- used to satisfy lua IDE and type checking
-- but removed at build-time

---@alias tuple<T,N> T[]

---@generic T
---@param a T
---@param b T
---@param c T
---@return tuple<T,3>
local function tuple3(a,b,c)
	return {a, b, c}
end

macro.end_()

---@generic T
---@param $a tuple<T,3>
---@param $b tuple<T,3>
---@return tuple<T,3>
local function vec3_add($a, $b) -- TODO: Would need to tag with tuple size
	return tuple3($a[1] + $b[1], $a[2] + $b[2], $a[3] + $b[3])
end

-- To support generic size would need to tag name with tuple size, e.g.,
-- macro.expr(set_tuple_size(3))
local $x, $y = tuple3(1, 0, 0), tuple3(0, 1, 0)
local $sum = vec3_add($x, $y)

print("sum: ", $sum)