AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate    = true

local Globals  = CAI.Globals
local Size     = Globals.NodeSize
local Utils    = CAI.Utilities
local Nodes    = CAI.Nodes
local Subnodes = CAI.Subnodes
local Model    = "models/props_junk/watermelon01.mdl" --"models/editor/ground_node.mdl"

function CAI.CreateNode(Position)
	local Node = ents.Create("cai_node")

	if not IsValid(Node) then return end

	local Coords = Utils.DivideVector(Position, Size)

	Node:SetPos(Position)
	Node:SetModel(Model)
	Node:PhysicsInit(SOLID_OBB)
	Node:SetMoveType(MOVETYPE_NONE)
	Node:SetSolidFlags(FSOLID_NOT_SOLID + FSOLID_TRIGGER)
	Node:Spawn()

	Node:SetTrigger(true)
	Node:SetCollisionBounds(Size * -0.5, Size * 0.5)

	Node.Key      = Utils.VectorToKey(Coords)
	Node.Coords   = Coords
	Node.Pos      = Position
	Node.Sides    = {}
	Node.Subnodes = {}

	Node:CreateSubnodes()

	return Node
end

function ENT:StartTouch(Entity)
	print(self, "start touch", Entity)
end

function ENT:EndTouch(Entity)
	print(self, "end touch", Entity)
end

do -- Subnode creation
	local Grid    = Globals.NodeGrid
	local BoundsX = math.floor(Grid.x * 0.5)
	local BoundsY = math.floor(Grid.y * 0.5)
	local BoundsZ = math.floor(Grid.z * 0.5)

	function ENT:CreateSubnodes()
		--local Init   = SysTime()
		local Coords = Vector()

		for X = -BoundsX, BoundsX do
			Coords.x = X

			for Y = -BoundsY, BoundsY do
				Coords.y = Y

				for Z = -BoundsZ, BoundsZ do
					Coords.z = Z

					Subnodes.Create(self, Coords)
				end
			end
		end

		--print(SysTime() - Init)
	end
end


function ENT:OnRemove()
	Nodes.Remove(self.Coords)
end
