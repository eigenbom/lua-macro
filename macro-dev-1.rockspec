---@diagnostic disable: lowercase-global
package = "macro"
version = "dev-1"
rockspec_format = "3.0"
source = {
   url = "."
}
description = {
   summary = "Lua Macro Processor",
   author = "Benjamin Porter",
   detailed = [[
      This is a file processor that evaluates macro commands within a Lua file and generates an output Lua file.
      
      To use the processor:
      * Require the macro file in any files you wish to process (`require 'macro'`)
      * Run the script `lua process.lua <input_filename> <output_filename> [environment_table]` over each file
   ]],
   license = "MIT",
   homepage = "https://github.com/eigenbom/lua-macro"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      macro = "src/macro.lua"
   },
   copy_directories = { "bin" }
}
