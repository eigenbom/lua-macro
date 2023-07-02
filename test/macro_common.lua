-- Global function example
function my_math_function(a, b)
	return a * b
end

-- Module example
local M = {}

function M.header()
	local header =
[[-----------------------------------------------------------
-- File generated on %s
-----------------------------------------------------------]]
	return string.format(header, os.date('%c'))
end

return M