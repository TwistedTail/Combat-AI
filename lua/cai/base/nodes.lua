-- Map nodes
local CAI     = CAI
local Nodes   = CAI.Nodes
local Objects = Nodes.Objects
local Globals = CAI.Globals
local Size    = Globals.NodeSize
local X, Y, Z = Size:Unpack()
local Round   = math.Round
local Utils   = CAI.Utilities

local function GetCoordinates(Pos)
	return Vector(
		Round(Pos.x / X),
		Round(Pos.y / Y),
		Round(Pos.z / Z)
	)
end

local function RoundPosition(Pos)
	return Vector(
		Round(Pos.x / X) * X,
		Round(Pos.y / Y) * Y,
		Round(Pos.z / Z) * Z
	)
end

Nodes.GetCoordinates = GetCoordinates
Nodes.RoundPosition  = RoundPosition

function Nodes.Get(Key)
	return Objects[Key]
end

-- NOTE: What would be the reason for this to exist?
function Nodes.GetAll()
	local Result = {}

	for K, V in pairs(Objects) do
		Result[K] = V
	end

	return Result
end

function Nodes.Find(Pos)
	local Coords = GetCoordinates(Pos)

	return Objects[Utils.VectorToKey(Coords)]
end

-- Only server can create and remove nodes
if CLIENT then return end

function Nodes.Create(Coords)
	local Key = Utils.VectorToKey(Coords)

	if IsValid(Objects[Key]) then return end

	local Node = CAI.CreateNode(Coords * Size)

	Objects[Key] = Node

	return Node
end

function Nodes.Remove(Coords)
	local Key  = Utils.VectorToKey(Coords)
	local Node = Objects[Key]

	if not Node then return end

	if IsValid(Node) then
		Node:Remove()
	end

	Objects[Key] = nil
end
