-----------------------------------------------------------
-- File generated on Sat Jul 15 15:57:43 2023
-----------------------------------------------------------
-- This file was processed with N = 2

local COMPILED_N = 2

local two_pi = 6.2831853071796

-- M == 3, so this comment should exist in the output file

---@param m number
local function print_sequence(m)
	print(3*m)
	print(6*m)
end

print_sequence(2)

-- Lookup tables that span [-math.pi, math.pi]
local LOOKUP_ABS = { 3.142, 2.945, 2.749, 2.553, 2.356, 2.160, 1.963, 1.767, 1.571, 1.374, 1.178, 0.982, 0.785, 0.589, 0.393, 0.196, 0.000, 0.196, 0.393, 0.589, 0.785, 0.982, 1.178, 1.374, 1.571, 1.767, 1.963, 2.160, 2.356, 2.553, 2.749, 2.945, 3.142 }
local LOOKUP_SIN = { -0.000, -0.195, -0.383, -0.556, -0.707, -0.831, -0.924, -0.981, -1.000, -0.981, -0.924, -0.831, -0.707, -0.556, -0.383, -0.195, 0.000, 0.195, 0.383, 0.556, 0.707, 0.831, 0.924, 0.981, 1.000, 0.981, 0.924, 0.831, 0.707, 0.556, 0.383, 0.195, 0.000 }
local LOOKUP_COS = { -1.000, -0.981, -0.924, -0.831, -0.707, -0.556, -0.383, -0.195, 0.000, 0.195, 0.383, 0.556, 0.707, 0.831, 0.924, 0.981, 1.000, 0.981, 0.924, 0.831, 0.707, 0.556, 0.383, 0.195, 0.000, -0.195, -0.383, -0.556, -0.707, -0.831, -0.924, -0.981, -1.000 }

-- Number type aliases
---@alias number_type "u8" | "i8" | "u16" | "i16" | "f32"

---unsigned 8-bit integer
---@alias u8 number

---signed 8-bit integer
---@alias i8 number

---unsigned 16-bit integer
---@alias u16 number

---signed 16-bit integer
---@alias i16 number

---32-bit floating point number
---@alias f32 number

---Swizzle function
local function swizzle_xx(v)
	return v.x, v.x
end

---Swizzle function
local function swizzle_xy(v)
	return v.x, v.y
end

---Swizzle function
local function swizzle_yx(v)
	return v.y, v.x
end

---Swizzle function
local function swizzle_yy(v)
	return v.y, v.y
end

