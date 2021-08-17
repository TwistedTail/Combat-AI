
ENT.Base      = "base_nextbot"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.IsCAIBot  = true

function ENT:GetShootPos()
	return Vector(self.ShootPos) -- Return a copy of it
end

function ENT:GetAimVector()
	return Vector(self.ShootDir) -- Return a copy of it
end
