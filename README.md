# Lua Macro Processor

## Overview

The script [bin/process.lua](bin/process.lua) is a file processor that evaluates macro commands embedded within a Lua file. It can be useful for projects that need to do build-time evaluation or code generation within Lua, such as creating templated functions, generating lookup tables, and unrolling loops.

Commands such as `eval()` and `expr()` will evaluate an expression and replace in-line, `do_()` and `end_()` provide macro blocks, and `post_process` provides a postprocess hook for modifying file contents. The API provided in [src/macro.lua](src/macro.lua) describes the commands and their inputs.

The macro commands are valid Lua so no additional IDE or language server support is needed. This processor is intentionally simple and uses a naive parser.


## Usage

### Manual Installation

* Manually copy the two files [src/macro.lua](src/macro.lua) and [bin/process.lua](bin/process.lua) into your project
* Require the macro file in any files you wish to process (`require 'macro'`)
* Run the script `lua process.lua <input_filename> <output_filename> [environment_table]` over each file

### Luarocks

[Luarocks](https://luarocks.org) can be used to install this script.

Example installation from Windows within a local directory:

* `luarocks install https://raw.githubusercontent.com/eigenbom/lua-macro/master/macro-dev-1.rockspec`
* Require the macro file in any files you wish to process (`require 'macro'`)
* Run the script `.\lua_modules\bin\process.lua.bat <input_filename> <output_filename> [environment_table]` over each file

## Examples

Here a two examples that demonstrates the basic process. For a complete example that covers all macro commands and more example use cases see [test/main.lua](test/main.lua) and [test/main.out.lua](test/main.out.lua).

### Hello, Pi

Running the processor with the command `process <input> <output> {N=2}` on an input file:

```lua
require 'macro'
local two_pi = macro.expr(N * math.pi)
```

Will create an output file containing:

```lua
local two_pi = 6.2831853071796
```

### Swizzle Maker

This example demonstrates generating 27 swizzle functions for all combinations of x, y, and z. When processing an input file:

```lua
require 'macro'
macro.do_()
local template = [[
---Swizzle function
local function swizzle_%s(v)
	return %s
end
]]
local coords = {'x', 'y', 'z'}
for i=1,3 do
	for j=1,3 do
		for k=1,3 do
			local ci, cj, ck = coords[i], coords[j], coords[k]
			local name = string.format("%s%s%s", ci, cj, ck)
			local values = string.format("v.%s, v.%s, v.%s", ci, cj, ck)
			print(string.format(template, name, values))
		end
	end
end
macro.end_()
```

The processor will output a file containing all the function variations:

```lua
---Swizzle function
local function swizzle_xxx(v)
	return v.x, v.x, v.x
end

--- ...

---Swizzle function
local function swizzle_xyz(v)
	return v.x, v.y, v.z
end

--- ...

---Swizzle function
local function swizzle_zzz(v)
	return v.z, v.z, v.z
end
```

# Tuple Time

The [test/tuple.lua](test/tuple.lua) examples demonstrates a simple compile-time tuple that wraps up multiple values into one variable. For input code like this:

```lua
local tuple_x = tuple3(1, 0, 0)
local tuple_y = tuple3(0, 1, 0)
local tuple_sum = vec3_add(tuple_x, tuple_y)
```

The script will unroll the tuples and output:

```lua
local x_1, x_2, x_3 = 1, 0, 0
local y_1, y_2, y_3 = 0, 1, 0
local sum_1, sum_2, sum_3 = vec3_add(x_1, x_2, x_3, y_1, y_2, y_3)
```