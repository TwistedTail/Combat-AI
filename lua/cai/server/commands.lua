local CAI   = CAI
local Nodes = CAI.Nodes

concommand.Add("cai_node", function(Player)
	if not IsValid(Player) then return end
	if not Player:IsSuperAdmin() then return end

	local Position = Player:GetEyeTrace().HitPos
	local Coords   = Nodes.GetCoordinates(Position)

	Nodes.Create(Coords)

	print("Created new node at ", Coords)
end)

concommand.Add("cai_clear", function(Player)
	if IsValid(Player) and not Player:IsSuperAdmin() then return end

	for K in pairs(Nodes.Objects) do
		Nodes.Remove(Vector(K))
	end

	print("Removed all nodes.")
end)
