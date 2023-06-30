# Lua Macro Processor

## Overview

The script [bin/process.lua](bin/process.lua) is a file processor that evaluates macro commands embedded within a Lua file. It can be useful for projects that need to do build-time evaluation or code generation within Lua, such as creating templated functions, generating lookup tables, and unrolling loops.

Commands such as `eval()` and `expr()` will evaluate an expression and replace in-line, `do_()` and `end_()` provide macro blocks, and `post_process` provides a postprocess hook for modifying file contents. The API provided in [src/macro.lua](src/macro.lua) describes the commands and their inputs.

The macro commands are valid Lua so no additional IDE or language server support is needed. This processor is intentionally simple and uses a naive parser.

## Example: Hello, Pi

Here is a simple example that demonstrates the basic process. For a complete example that covers all macro commands and some example use cases see [test/main.lua](test/main.lua) and [test/main.out.lua](test/main.out.lua).

Running the processor with the command `process <input> <output> {N=2}` on an input file:

```lua
require 'macro'
local two_pi = macro.expr(N * math.pi)
```

Will create an output file containing:

```lua
local two_pi = 6.2831853071796
```

## Example: Swizzle Maker

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

## Usage

Two files are needed from this repository: [src/macro.lua](src/macro.lua) and [bin/process.lua](bin/process.lua). You can manually copy them into your project or use [luarocks].

To use the processor:
* Require the macro file in any files you wish to process (`require 'macro'`)
* Run the script `lua process.lua <input_filename> <output_filename> [environment_table]` over each file
