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

	print("Created new node at ", Data.Position)
end)

concommand.Add("cai_clear", function(Player)
	if not CNode then return end
	if IsValid(Player) and not Player:IsSuperAdmin() then return end

	local Count = CNode.RemoveAllNodes()

	print("Removed " .. Count .. " nodes.")
end)

do -- Node generation
	local Utils  = CAI.Utilities
	local Unused = {}

	local function GetOrAddNode(Position)
		if CNode.HasNode(Position) then
			return CNode.GetNode(Position)
		end

		local Coords = CNode.GetCoordinates(Position)
		local Key    = Utils.VectorToKey(Coords)
		local Data   = Unused[Key] or Nodes.CheckCoordinates(Coords)

		if not Data then return end

		CNode.AddNode(Position, Data.FootPos)

		return Data, Key
	end

	local function ExploreSides(Center, FootPos)
		local SizeX, SizeY, SizeZ = CNode.NodeSize:Unpack()
		local PosX, PosY, PosZ = Center:Unpack()
		local Current = Vector()

		for X = -1, 1 do
			Current.x = PosX + SizeX * X

			for Y = -1, 1 do
				Current.y = PosY + SizeY * Y

				for Z = -1, 1 do
					Current.z = PosZ + SizeZ * Z

					local Data, Key = GetOrAddNode(Current)

					if not Data then continue end
					if Data.Position == Center then continue end
					if not Nodes.CanConnect(FootPos, Data.FootPos) then continue end
					if Key then Unused[Key] = nil end

					CNode.ConnectNodes(Center, Data.Position)
				end
			end
		end
	end

	concommand.Add("cai_gen", function(Player)
		if not CNode then return end
		if not IsValid(Player) then return end
		if not Player:IsSuperAdmin() then return end

		local Position  = Player:GetEyeTrace().HitPos
		local Data, Key = GetOrAddNode(Position)

		if not Data then print("Couldn't generate grid from ", Position) end
		if Key then Unused[Key] = nil end

		ExploreSides(Data.Position, Data.FootPos)

		print("Generated " .. CNode.GetNodeCount() .. " nodes.")
	end)
end
