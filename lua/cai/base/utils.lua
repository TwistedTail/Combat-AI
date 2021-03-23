-- Utility functions
local Utils = CAI.Utilities
local Key   = "%i %i %i"

function Utils.VectorToKey(Vector)
	return Key:format(Vector:Unpack())
end

function Utils.AxisesToKey(X, Y, Z)
	return Key:format(X, Y, Z)
end

-- Thank you Garry
function Utils.DivideVector(A, B)
	return Vector(A.x / B.x, A.y / B.y, A.z / B.z)
end
