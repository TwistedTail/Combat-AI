local CAI   = CAI
local CNode = CNode
local Nodes = CAI.Nodes
local Grid  = CNode.GetGrid("human")
local print = print

concommand.Add("cai_node", function(Player)
	if not IsValid(Player) then return end
	if not Player:IsSuperAdmin() then return end

	local Position = Player:GetEyeTrace().HitPos

	if CNode.HasNode(Grid.Name, Position) then return end

	local Node = Nodes.CheckSpot(Position)

	if not Node then return end

	CNode.AddNode(Grid.Name, Position, Node.FootPos)

	print("Created new node at ", Node.Position)
end)

concommand.Add("cai_clear", function(Player)
	if IsValid(Player) and not Player:IsSuperAdmin() then return end

	local Count = CNode.ClearNodes(Grid.Name)

	print("Removed " .. Count .. " nodes.")
end)

do -- Node generation
	local Utils   = CAI.Utilities
	local Result  = "%s node generation after %s seconds (%s iterations).\nPurged %s unused nodes.\nGenerated %s walkable nodes."
	local Sides   = {}
	local Found   = {}
	local List    = {}
	local MaxStep = 66
	local Count   = 0
	local Iter    = 0
	local Active, Start

	do -- Populating the sides table
		local Entry = Vector()
		local Zero  = Vector()
		local Index = 0

		for X = -1, 1 do
			Entry.x = X

			for Y = -1, 1 do
				Entry.y = Y

				for Z = -1, 1 do
					Entry.z = Z

					if Entry == Zero then continue end

					Index = Index + 1

					Sides[Index] = Vector(Entry) -- Pushing a copy
				end
			end
		end
	end

	local function GetOrAddNode(Position)
		if CNode.HasNode(Grid.Name, Position) then
			return CNode.GetNode(Grid.Name, Position)
		end

		local Coords = CNode.GetCoordinates(Grid.Name, Position)
		local Key    = Utils.VectorToKey(Coords)
		local Node   = Nodes.CheckCoordinates(Coords)

		if not Node then return end
		if not CNode.AddNode(Grid.Name, Position, Node.FootPos) then return end

		return Node, Key
	end

	local function ExploreSides(Coordinates, FootPos)
		local Added = {}
		local Size  = Grid.NodeSize

		for I = #Sides, 1, -1 do
			local Current   = (Coordinates + Sides[I]) * Size
			local Node, Key = GetOrAddNode(Current)

			if not Node then continue end

			if Nodes.CanConnect(FootPos, Node.FootPos) then
				CNode.ConnectTo(Grid.Name, FootPos, Node.FootPos)
			end

			if Key then
				Added[Key] = Node
			end
		end

		return Added
	end

	local function Search()
		for _ = 1, math.min(Count, MaxStep) do
			local Key  = table.remove(List)
			local Node = Found[Key]

			Count = Count - 1

			Found[Key] = nil

			local Added = ExploreSides(Node.Coordinates, Node.FootPos)

			for K, V in pairs(Added) do
				Count = Count + 1

				List[Count] = K
				Found[K]    = V
			end
		end

		if Count == 0 then
			hook.Remove("Tick", "CAI NodeGen")

			print(Result:format("Finished", os.time() - Start, Iter, CNode.PurgeUnused(Grid.Name), CNode.GetNodeCount(Grid.Name)))

			Active = nil
			Iter   = 0
		else
			Iter = Iter + 1
		end
	end

	concommand.Add("cai_begin", function(Player)
		if not IsValid(Player) then return end
		if not Player:IsSuperAdmin() then return end
		if Active then return print("Already generating") end

		local Position  = Player:GetEyeTrace().HitPos
		local Node, Key = GetOrAddNode(Position)

		if not Node then return print("Couldn't generate grid on ", Position) end
		if not Key then return print("Don't forget to clear the grid before generating a new one") end

		Active = true
		Start  = os.time()
		Count  = Count + 1

		List[Count] = Key
		Found[Key] = Node

		hook.Add("Tick", "CAI NodeGen", Search)
	end)

	concommand.Add("cai_stop", function(Player)
		if IsValid(Player) and not Player:IsSuperAdmin() then return end
		if not Active then return print("No generation is running") end

		print(Result:format("Cancelled", os.time() - Start, Iter, CNode.PurgeUnused(Grid.Name), CNode.GetNodeCount(Grid.Name)))

		Active = nil
		Start  = nil
		Count  = 0
		Iter   = 0

		for I = #List, 1, -1 do
			local K = List[I]

			Found[K] = nil
			List[I]  = nil
		end

		hook.Remove("Tick", "CAI NodeGen")
	end)
end

do -- Node saving and loading
	local Globals  = CAI.Globals
	local MapPath  = Globals.MapPath
	local FilePath = Globals.FilePath

	concommand.Add("cai_save", function(Player)
		if IsValid(Player) and not Player:IsSuperAdmin() then return end

		local JSON = CNode.SerializeGrid(Grid.Name)

		if not JSON then return print("Grid hasn't been created") end

		local Map    = game.GetMap()
		local Folder = MapPath:format(Map)
		local File   = FilePath:format(Map, Grid.Name)

		if not file.Exists(Folder, "DATA") then
			file.CreateDir(Folder)
		end

		file.Write(File, JSON)

		print("Grid saved successfully!")

		JSON = nil

		collectgarbage()
	end)

	concommand.Add("cai_load", function(Player)
		if IsValid(Player) and not Player:IsSuperAdmin() then return end

		local Map  = game.GetMap()
		local File = FilePath:format(Map, Grid.Name)

		if not file.Exists(File, "DATA") then
			return print("There's no grid saves for this map.")
		end

		local JSON   = file.Read(File, "DATA")
		local Result = CNode.DeserializeGrid(JSON)

		print(Result and "Success!" or "Couldn't load grid.")

		JSON = nil

		collectgarbage()
	end)
end