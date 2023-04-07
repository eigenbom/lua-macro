-------------------------------------------------------------
-- Macro processor
-- Copyright (c) 2023 Benjamin Porter
--
-- API declarations for macro processing functions
--------------------------------------------------------------

macro = {}

--- Evaluates the lua expression
---
--- Example: 
--- `macro.expr(2*5)` is replaced with `10`
---@param expr any
---@return any
function macro.expr(expr) end

--- Evaluates the string
---
--- Example:
--- `macro.eval[[2*5]]` is replaced with `10`
---@param str string
---@return any
function macro.eval(str) end

--- Starts a macro block
---
--- Example:
--- `macro.do_() print("x = 3") macro.end_()` is replaced with `x = 3`
function macro.do_() end

--- Conditionally starts a macro block
---
--- Example:
--- `macro.if_(FEATURE) print("-- FEATURE ENABLED") macro.end_()`
function macro.if_(expr) end

--- Ends a macro block
---
--- Example:
--- `macro.do_() print("x = 3") macro.end_()` is replaced with `x = 3`
function macro.end_() end

--- A function that will be called after macro processing is complete
---@type fun(file_contents:string):string
macro.post_process = nil