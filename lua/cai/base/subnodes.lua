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
local ToKey      = Utils.VectorToKey
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

local function CheckWater(Node, Ground)
	local HitPos = Ground.HitPos

	Trace.endpos = HitPos
	Trace.mask   = MASK_WATER

	local Water = TraceHull(Trace)

	-- Neither ground or water has been hit, this is in the air
	if not (Ground.Hit or Water.Hit) then return end

	if Water.Hit then -- Let's get wet
		local Depth = Water.HitPos.z - HitPos.z

		if Depth > MaxJump then -- If too deep, then we swimmin'
			Node.Swim = true
		else
			Node.Depth = Depth -- TODO: Instantly calculate the cost of this subnode
		end

		Node.Water = true
	end

	return true
end

local function CheckRoof(Node, Ground)
	local HitPos = Ground.HitPos

	Trace.start  = HitPos
	Trace.endpos = HitPos - Ground.Normal * MaxHeight
	Trace.mask   = MASK_PLAYERSOLID_BRUSHONLY

	local Roof = TraceHull(Trace)

	if Roof.Hit then -- Something above us
		if Roof.Fraction * MaxHeight < MaxCrouch then return end

		if not Node.Swim then -- We don't crouch while swimming
			Node.Crouch = true -- Bots will need to crouch here
		end
	end
end

local function IsValidNode(Node)
	local Ground = CheckGround(Node)

	if not Ground then return end
	if not CheckWater(Node, Ground) then return end

	CheckRoof(Node, Ground) -- This one doesn't fail, should it?

	return true
end

function Subnodes.Create(Node, Coords)
	local Nodes = Node.Subnodes
	local Key   = ToKey(Coords)

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
	local Key   = ToKey(Coords)

	if not Nodes[Key] then return end

	Nodes[Key] = nil
end
