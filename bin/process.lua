-------------------------------------------------------------
-- Macro processor
-- Copyright (c) 2023 Benjamin Porter
--
-- Usage: 
-- lua process.lua input_filename output_filename environment
--
-- Example:
-- lua process.lua .\test\main.lua .\test\main.out.lua "{N=2}"
--------------------------------------------------------------

local input_filename = arg[1]
local output_filename = arg[2]
local environment = arg[3] or "{}"
local has_macro_require = false
local read_macro_eval_token = false
local read_macro_do_token = false
local read_macro_pp_token = false
local read_macro_expr_token = false
local read_macro_if_token = false
local token_start_cursor --[[@type integer]]
local macro_contents_start_cursor --[[@type integer]]
local macro_exp_parent_count = 0 --[[@type integer]]
local macro_pp_function = nil
local macro_exec_block = true

local replacement_strings = {} ---@type {start:integer, finish:integer, str:string}
local debug_print = function(...) end

if not loadstring then
	-- lua 5.4 compatibility
	loadstring = load
end

local env = assert(loadstring("return " .. environment)())
for k, v in pairs(_G) do
	env[k] = v
end
env._G = env

local input_file = assert(io.open(input_filename, "r"))
local file_contents = input_file:read("*a") --[[@as string]]
local cursor = 1
local line_number = 1

local function print_code(code, line_number)
	-- split code by line and print each line indented with line number
	local lines = {}
	for line in code:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	print("source: ")
	for i, line in ipairs(lines) do
		print(string.format("        %d    \"%s\"", line_number + i - 1, line))
	end
end

---@param code string
local function process_macro(code, options)
	options = options or {}

	local macro_output = {}
	env.print = function(...)
		local arg_table = {...}
		table.insert(macro_output, table.concat(arg_table, "\t"))
	end
	local macro_fun, error_msg = load(code, input_filename, "t", env)
	local is_expr = false
	if not macro_fun then
		if options.to_expression then
			macro_fun, _ = load("return " .. code .. "", input_filename, "t", env)
			return macro_fun
		else
			-- error running code, try again wrapped print statement
			macro_fun, _ = load("print(tostring(" .. code .. "))", input_filename, "t", env)
			is_expr = true
		end
	end
	if macro_fun then
		if options.post_process then
			return macro_fun
		else
			-- pcall function macro_fun and print error message if any
			local success, pcall_error = pcall(macro_fun)
			if not success then
				if pcall_error then
					pcall_error = pcall_error:gsub("%[string .*%]:%d*", input_filename .. ":" .. line_number)
				else
					pcall_error = "unknown error"
				end
				print("macro processing failed!")
				print("error: " .. pcall_error)
				print_code(code, line_number)
				os.exit(false)
			end
			if #macro_output > 0 then
				return table.concat(macro_output, "\n") .. (is_expr and "" or "\n")
			end
		end
	else
		if error_msg then
			error_msg = error_msg:gsub("%[string .*%]:%d*", input_filename .. ":" .. line_number)
		else
			error_msg = "unknown error"
		end
		print("macro processing failed!")
		print("error: " .. error_msg)
		print_code(code, line_number)
		os.exit(false)
	end
end


---@param token string
local function read_token(token)
	if file_contents:sub(cursor, cursor+token:len()-1) == token then
		cursor = cursor + token:len()
		return true
	end
end

local function advance_cursor()
	if cursor <= #file_contents and file_contents:sub(cursor, cursor) == "\n" then
		line_number = line_number + 1
	end
	cursor = cursor + 1
end

local function advance_cursor_to_newline()
	while cursor <= #file_contents do
		if file_contents:sub(cursor, cursor+1) == "\r\n" then
			advance_cursor()
			advance_cursor()
			return
		elseif file_contents:sub(cursor, cursor) == "\n" then
			advance_cursor()
			return
		elseif file_contents:sub(cursor, cursor) == " " then
			advance_cursor()
		else
			return
		end
	end
end


while cursor <= file_contents:len() do
	local prev_cursor = cursor

	if read_macro_do_token then
		if read_token("macro.end_()") then
			read_macro_do_token = false
			advance_cursor_to_newline()

			table.insert(replacement_strings,
				{
					start = token_start_cursor,
					finish = cursor-1,
					str = macro_exec_block and process_macro(file_contents:sub(macro_contents_start_cursor, prev_cursor-1)) or nil
				}
			)

			macro_exec_block = true
		else
			advance_cursor()
		end
	elseif read_macro_eval_token then
		if read_token("]]") then
			read_macro_eval_token = false
			advance_cursor_to_newline()
			table.insert(replacement_strings,
				{
					start = token_start_cursor,
					finish = cursor-1,
					str = process_macro(file_contents:sub(macro_contents_start_cursor, prev_cursor-1))
				}
			)
		else
			advance_cursor()
		end
	elseif read_macro_pp_token then
		if read_token("end") then
			read_macro_pp_token = false
			macro_pp_function = process_macro("return " .. file_contents:sub(macro_contents_start_cursor, cursor), {post_process = true})
			advance_cursor_to_newline()
			table.insert(replacement_strings,
				{
					start = token_start_cursor,
					finish = cursor-1,
					str = nil
				}
			)
		else
			advance_cursor()
		end
	elseif read_macro_expr_token then
		if read_token("(") then
			macro_exp_parent_count = macro_exp_parent_count + 1
		elseif read_token(")") then
			macro_exp_parent_count = macro_exp_parent_count - 1
			if macro_exp_parent_count == 0 then
				read_macro_expr_token = false

				table.insert(replacement_strings,
					{
						start = token_start_cursor,
						finish = cursor-1,
						str = process_macro(file_contents:sub(macro_contents_start_cursor, prev_cursor-1))
					}
				)
			end
		else
			advance_cursor()
		end
	elseif read_macro_if_token then
		if read_token("(") then
			macro_exp_parent_count = macro_exp_parent_count + 1
		elseif read_token(")") then
			macro_exp_parent_count = macro_exp_parent_count - 1
			if macro_exp_parent_count == 0 then
				read_macro_if_token = false

				local macro_if_expr = file_contents:sub(macro_contents_start_cursor, prev_cursor-1)
				local expr = process_macro(macro_if_expr, {to_expression = true})
				---@cast expr function
				local success, result = pcall(expr)
				if not success then
					pcall_error = result
					if pcall_error then
						pcall_error = pcall_error:gsub("%[string .*%]:%d*", input_filename .. ":" .. line_number)
					else
						pcall_error = "unknown error"
					end
					print("macro processing failed!")
					print("error: " .. pcall_error)
					print_code(macro_if_expr, line_number)
					os.exit(false)
				end
				macro_exec_block = result

				table.insert(replacement_strings,
					{
						start = token_start_cursor,
						finish = cursor-1,
						str = nil
					}
				)

				read_macro_do_token = true
				token_start_cursor = cursor
				macro_contents_start_cursor = cursor
			end
		else
			advance_cursor()
		end
	else
		if read_token("require 'macro'") or read_token("require \"macro\"") 
		or read_token("require(\"macro\")") or read_token("require( \"macro\" )")
		or read_token("require(\'macro\')") or read_token("require( \'macro\' )")
		then
			has_macro_require = true
			advance_cursor_to_newline()
			table.insert(replacement_strings,
				{
					start = prev_cursor,
					finish = cursor,
					str = nil
				}
			)
		elseif has_macro_require then
			if (read_token("macro.eval [[") or read_token("macro.eval[[")) then
				read_macro_eval_token = true
				if prev_cursor > 1 then
					-- eat tab whitespace preceding macro
					while file_contents:sub(prev_cursor-1, prev_cursor-1) == "\t" do
						prev_cursor = prev_cursor - 1
					end
				end
				token_start_cursor = prev_cursor
				macro_contents_start_cursor = cursor
			elseif read_token("macro.expr (") or read_token("macro.expr(") then
				read_macro_expr_token = true
				macro_exp_parent_count = 1
				if prev_cursor > 1 then
					-- eat tab whitespace preceding macro
					while file_contents:sub(prev_cursor-1, prev_cursor-1) == "\t" do
						prev_cursor = prev_cursor - 1
					end
				end
				token_start_cursor = prev_cursor
				macro_contents_start_cursor = cursor
			elseif read_token("macro.if_(") then
				read_macro_if_token = true
				macro_exp_parent_count = 1
				macro_if_parent_count = 1
				if prev_cursor > 1 then
					-- eat tab whitespace preceding macro
					while file_contents:sub(prev_cursor-1, prev_cursor-1) == "\t" do
						prev_cursor = prev_cursor - 1
					end
				end
				token_start_cursor = prev_cursor
				macro_contents_start_cursor = cursor
			elseif read_token("macro.do_()") then
				read_macro_do_token = true
				if prev_cursor > 1 then
					-- eat tab whitespace preceding macro
					while file_contents:sub(prev_cursor-1, prev_cursor-1) == "\t" do
						prev_cursor = prev_cursor - 1
					end
				end
				token_start_cursor = prev_cursor
				macro_contents_start_cursor = cursor
			elseif read_token("macro.post_process =") or read_token("macro.post_process=") then
				read_macro_pp_token = true
				if prev_cursor > 1 then
					-- eat tab whitespace preceding macro
					while file_contents:sub(prev_cursor-1, prev_cursor-1) == "\t" do
						prev_cursor = prev_cursor - 1
					end
				end
				token_start_cursor = prev_cursor
				macro_contents_start_cursor = cursor
			else
				advance_cursor()
			end
		else
			advance_cursor()
		end
	end
end

do
	for _, r in ipairs(replacement_strings) do
		debug_print(r.start, r.finish, r.str, file_contents:sub(r.start, r.finish))
	end

	-- print output file
	local output_file = io.open(output_filename, "wb")
	assert(output_file)
	if #replacement_strings>0 then
		local new_file_contents = {}
		local prev_cursor = 1

		for _, r in ipairs(replacement_strings) do
			if prev_cursor < r.start then
				-- add preceding part of file
				new_file_contents[#new_file_contents+1] = file_contents:sub(prev_cursor, r.start-1)
			end
			if r.str then
				new_file_contents[#new_file_contents+1] = r.str
			end

			prev_cursor = r.finish+1
		end

		if prev_cursor < file_contents:len() then
			-- Add final section of file
			new_file_contents[#new_file_contents+1] = file_contents:sub(prev_cursor, file_contents:len())
		end

		for _, part in ipairs(new_file_contents) do
			debug_print('"' .. part .. '"')
		end

		file_contents = table.concat(new_file_contents)
	end

	if macro_pp_function then
		file_contents = macro_pp_function()(file_contents)
	elseif env.post_process then
		file_contents = env.post_process(file_contents)
	end
	output_file:write(file_contents)
end
