-- Utility functions
local Utils  = CAI.Utilities
local format = string.format
local Key    = "%i %i %i"
local UID    = "%s-%i"

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

do -- CAI CurTime and DeltaTime
	Utils.CurTime   = CurTime()
	Utils.DeltaTime = 0

	hook.Add("Tick", "CAI CurTime/DeltaTime", function()
		local Time = CurTime()

		Utils.DeltaTime = Time - Utils.CurTime
		Utils.CurTime   = Time
	end)

	function Utils.GetUID(Name)
		return format(UID, Name, Utils.CurTime)
	end
end
