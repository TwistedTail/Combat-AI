local CAI   = CAI
local Nodes = CAI.Nodes

concommand.Add("cai_node", function(Player)
	if not CNode then return end
	if not IsValid(Player) then return end
	if not Player:IsSuperAdmin() then return end

	local Position = Player:GetEyeTrace().HitPos

	if CNode.HasNode(Position) then return end

	local Data = Nodes.CheckSpot(Position)

	if not Data then return end

	CNode.AddNode(Position, Data.FootPos)

	print("Created new node at ", Data.Pos)
end)

concommand.Add("cai_clear", function(Player)
	if not CNode then return end
	if IsValid(Player) and not Player:IsSuperAdmin() then return end

	local Count = CNode.RemoveAllNodes()

	print("Removed " .. Count .. " nodes.")
end)
