
ENT.Base      = "base_nextbot"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:GetShootPos()
	return Vector(self.ShootPos) -- Return a copy of it
end

list.Set("NPC", "cai_base", {
	Name = "Combat AI Base",
	Class = "cai_base",
	Category = "Nextbot"
})
