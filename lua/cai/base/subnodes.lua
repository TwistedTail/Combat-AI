local format  = string.format
local Name    = "Subnode [%s][%s]"
local SubMeta = {}
local ObjMeta = { __index = SubMeta }

-- TODO: Add more subnode methods

function SubMeta:ToString()
	return format(Name, self.Node.Key, self.Key)
end

ObjMeta.__tostring = SubMeta.ToString

-------------------------------------------

local TraceHull  = util.TraceHull
local Globals    = CAI.Globals
local Subnodes   = CAI.Subnodes
local Utils      = CAI.Utilities
local SubSize    = Globals.SubnodeSize
local MaxSlope   = Globals.MaxSlope
local HalfWidth  = Globals.MaxWidth * 0.5
local MaxHeight  = Globals.MaxHeight
local MaxCrouch  = Globals.MaxCrouch
local MaxJump    = Globals.MaxJump
local HalfHeight = Vector(0, 0, MaxHeight * 0.5)
local UpNormal   = Vector(0, 0, 1)

local Trace = {
	start  = true,
	endpos = true,
	mask   = true,
	mins   = -Vector(HalfWidth, HalfWidth),
	maxs   = Vector(HalfWidth, HalfWidth),
}

local function CheckGround(Node)
	Trace.start  = Node.Pos + HalfHeight
	Trace.endpos = Node.Pos - HalfHeight
	Trace.mask   = MASK_PLAYERSOLID_BRUSHONLY

	local Ground = TraceHull(Trace)

	if Ground.StartSolid then return end
	if Ground.HitNotSolid then return end
	if Ground.Hit and UpNormal:Dot(Ground.HitNormal) < MaxSlope then return end

	return Ground
end

-- TODO: Properly check where the bottom and surface of water bodies are
local function CheckWater(Node, Ground)
	Trace.endpos = Ground.HitPos
	Trace.mask   = MASK_WATER

	local Water = TraceHull(Trace)

	-- Neither ground or water has been hit, this is in the air
	if not (Ground.Hit or Water.Hit) then return end

	Trace.mask = MASK_PLAYERSOLID_BRUSHONLY

	local Bottom = TraceHull(Trace)
	local HitPos = Bottom.HitPos

	if Water.Hit then -- Let's get wet
		local Depth = Water.HitPos.z - HitPos.z

		if Depth > MaxJump then -- If too deep, then we swimmin'
			Node.Swim = true
		else
			Node.Depth = Depth -- TODO: Instantly calculate the cost of this subnode
		end

		Node.Water = true
	end

	Node.FeetPos = Node.Swim and Water.HitPos or Ground.HitPos

	return true
end

local function CheckRoof(Node, Ground)
	local HitPos = Ground.HitPos

	Trace.start  = HitPos
	Trace.endpos = HitPos - Ground.Normal * MaxHeight

	local Roof = TraceHull(Trace)

	if Roof.Hit then -- Something above us
		if Roof.Fraction * MaxHeight < MaxCrouch then return end

		if not Node.Swim then -- We don't crouch while swimming
			Node.Crouch = true -- Bots will need to crouch here
		end
	end

	return true
end

local function IsValidNode(Node)
	local Ground = CheckGround(Node)

	if not Ground then return end
	if not CheckWater(Node, Ground) then return end
	if not CheckRoof(Node, Ground) then return end

	return true
end

function Subnodes.Create(Node, Coords)
	local Nodes = Node.Subnodes
	local Key   = Utils.VectorToKey(Coords)

	if Nodes[Key] then return end

	local New = {
		Key    = Key,
		Coords = Vector(Coords), -- Generating a copy
		Pos    = Node.Pos + SubSize * Coords,
		Node   = Node,
		Sides  = {},
	}

	if not IsValidNode(New) then return end

	setmetatable(New, ObjMeta)

	Nodes[Key] = New

	return New
end

function Subnodes.Remove(Node, Coords)
	local Nodes = Node.Subnodes
	local Key   = Utils.VectorToKey(Coords)

	if not Nodes[Key] then return end

	Nodes[Key] = nil
end
