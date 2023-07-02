--|---------------------------------------------------------
--| Macro / processing lua demo
--|
--| To run this example run the macro process script. 
--| For example:
--| > lua process.lua .\test\main.lua .\test\main.out.lua "{N=2}"
--|
--| Note: process <input> <output> <global table>
--| 
--| Note: Comments starting with --| will be stripped out 
--| in the custom post_process function defined below
--|---------------------------------------------------------

--| Every file that uses the macro processor must "require 'macro'"
require 'macro'

--| Code within do_() and end_() will execute at processing time
--| Any print statements will be printed into the output file
macro.do_()
-- Can require other files within a macro block
-- NB: Make it global to access outside of this block
common = require 'test.macro_common'

-- Declare a variable that will be available to all other macro blocks
local M = 0

-- Declare a global variable or use from <global table> supplied on command line
N = N or 0

-- Print a comment into the output file
local template = "-- This file was processed with N = %d"
print(string.format(template, N))
macro.end_()

--| Evaluate an expression and replace with the results
--| This will output "local COMPILED_N = 2" if processed with N = 2
local COMPILED_N = macro.expr(N)

--| Evaluate the string
--| This will set the macro variable M to 3 for blocks below
--| And will be removed in the output file
macro.eval [[M = 3]]

macro.if_(M == 4)
-- This code won't be executed at processing time
print("-- M ~= 4, so this comment shouldn't exist in the output file")
macro.end_()

local two_pi = macro.expr(2 * math.pi)

macro.if_(M == 3)
-- This code will be executed at processing time
print("-- M == 3, so this comment should exist in the output file")
macro.end_()

--| Usage Examples

--| The contents of this function are generated
--| M is evaluated during processing and replaced with a constant in target code
--| N is evaluated during processing to unroll a for loop
--| my_math_function is a global macro function defined in macro_common.lua
---@param m number
local function print_sequence(m)
	macro.do_()
	for i=1,N do
		print(string.format('\tprint(%d*m)', my_math_function(i, M)))
	end
	macro.end_()
end

--| Run-time lua code, ignore by the macro processor
print_sequence(2)

--| Example: generating look-up tables
-- Lookup tables that span [-math.pi, math.pi]
macro.do_()
local functions = {
	SIN = math.sin,
	COS = math.cos,
	ABS = math.abs,
}
for k, fun in pairs(functions) do
	local samples = {}
	local N = 33 -- Odd number of samples to get x=0
	for i=1,N do
		local i_norm = (i-1) / (N-1) --> [0,1]
		local x = 2 * (i_norm - 0.5) * math.pi
		samples[i] = string.format("%.3f", fun(x))
	end
	print(string.format("local LOOKUP_%s = { %s }", k, table.concat(samples, ", ")))
end
macro.end_()


--| Example: generating aliases and functions for type annotations
-- Number type aliases
macro.do_()
local types = {
	{"u8", 8, "unsigned 8-bit integer"},
	{"i8", 8, "signed 8-bit integer"},
	{"u16", 16, "unsigned 16-bit integer"},
	{"i16", 16, "signed 16-bit integer"},
	{"f32", 32, "32-bit floating point number"},
	-- etc
}

local aliases = {}
for _, type_ in ipairs(types) do
	aliases[#aliases+1] = '"' .. type_[1] .. '"'
end
print(string.format("---@alias number_type %s", table.concat(aliases, " | ")))
print()

for _, type_ in ipairs(types) do
	local alias, bits, doc = type_[1], type_[2], type_[3]
	print(string.format("---%s", doc))
	print(string.format("---@alias %s number", alias))
	print()
	print()
end
macro.end_()

--| A post_process function can be used to modify the output file
--| post_process can also exist as a function within a macro block
macro.post_process = function(file_contents)
	local result = file_contents;

	-- Example: remove all comments in this file that begin with "--|"
	-- As they are only used to describe macro functionality
	result = result:gsub('[ \t]*%-%-|[^\n]*', 'REMOVE_LINE')

	-- remove all lines that contain REMOVE_LINE
	result = result:gsub("REMOVE_LINE\n", '')

	-- Example prettifier: remove double empty lines
	result = result:gsub('\n\n+', '\n\n')

	-- Example: add header from another macro file common.lua
	result = common.header() .. result

	return result
end

macro.do_()
local template = [[
---Swizzle function
local function swizzle_%s(v)
	return %s
end
]]
local coords = {'x', 'y'}
for i=1,2 do
	for j=1,2 do
		local ci, cj = coords[i], coords[j]
		local name = string.format("%s%s", ci, cj)
		local values = string.format("v.%s, v.%s", ci, cj)
		print(string.format(template, name, values))
	end
end
macro.end_()