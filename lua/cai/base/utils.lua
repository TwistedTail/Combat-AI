-- Utility functions
local Utils  = CAI.Utilities
local format = string.format
local Key    = "%i %i %i"

function Utils.VectorToKey(Vector)
	return format(Key, Vector:Unpack())
end

function Utils.AxisesToKey(X, Y, Z)
	return format(Key, X, Y, Z)
end

-- Thank you Garry
function Utils.DivideVector(A, B)
	return Vector(A.x / B.x, A.y / B.y, A.z / B.z)
end

if SERVER then return end

hook.Add("InitPostEntity", "CAI EyePos Stuff", function()
	local Player = LocalPlayer()

	Utils.EyePos = Player:EyePos()

	hook.Add("Think", "CAI EyePos Stuff", function()
		Utils.EyePos = Player:EyePos()
	end)

	hook.Remove("InitPostEntity", "CAI EyePos Stuff")
end)