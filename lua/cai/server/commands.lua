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
	local Sides  = {}
	local Unused = {}

	do -- Populating the sides table
		local Entry = Vector()
		local Zero  = Vector()
		local Count = 0

		for X = -1, 1 do
			Entry.x = X

			for Y = -1, 1 do
				Entry.y = Y

				for Z = -1, 1 do
					Entry.z = Z

					if Entry == Zero then continue end

					Count = Count + 1

					Sides[Count] = Vector(Entry) -- Pushing a copy
				end
			end
		end
	end

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
		local Size = CNode.NodeSize

		for I = #Sides, 1, -1 do
			local Current = Center + Sides[I] * Size

			local Data, Key = GetOrAddNode(Current)

			if not Data then continue end
			if not Nodes.CanConnect(FootPos, Data.FootPos) then
				if Key then Unused[Key] = Data end

				continue
			end

			CNode.ConnectNodes(Center, Data.Position)

			if Key then Unused[Key] = nil end
		end
	end

	concommand.Add("cai_gen", function(Player)
		if not CNode then return end
		if not IsValid(Player) then return end
		if not Player:IsSuperAdmin() then return end

		local Position  = Player:GetEyeTrace().HitPos
		local Current   = CNode.GetNodeCount()
		local Data, Key = GetOrAddNode(Position)

		if not Data then return print("Couldn't generate grid on ", Position) end
		if Key then Unused[Key] = nil end

		ExploreSides(Data.Position, Data.FootPos)

		print("Generated " .. (CNode.GetNodeCount() - Current) .. " new nodes.")
	end)
end
