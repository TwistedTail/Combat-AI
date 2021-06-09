local TraceLine    = util.TraceLine
local TraceHull    = util.TraceHull
local CAI          = CAI
local CNode        = CNode
local Globals      = CAI.Globals
local Nodes        = CAI.Nodes
local Utils        = CAI.Utilities
local MaxSlope     = Globals.MaxSlope
local HalfWidth    = Globals.MaxWidth * 0.5
local MaxHeight    = Globals.MaxHeight
local MaxCrouch    = Globals.MaxCrouch
local MaxJump      = Globals.MaxJump
local Grid         = CNode.GetGrid("human")
local HalfHeight   = Vector(0, 0, MaxHeight * 0.5)
local UpNormal     = Vector(0, 0, 1)
local NodeSize     = Vector(HalfWidth, HalfWidth)

local NodeTrace = {
	start  = true,
	endpos = true,
	mask   = true,
	mins   = true,
	maxs   = true,
}

local function CheckGround(Data, Traces)
	local Position = Data.Coordinates * Grid.NodeSize

	NodeTrace.start  = Position + HalfHeight
	NodeTrace.endpos = Position - HalfHeight
	NodeTrace.mask   = MASK_PLAYERSOLID_BRUSHONLY

	local Ground = TraceLine(NodeTrace)

	if Ground.StartSolid then return end
	if Ground.HitNotSolid then return end
	if Ground.Hit and UpNormal:Dot(Ground.HitNormal) < MaxSlope then return end

	Traces.Ground = Ground

	return true
end

local function CheckVertical(Data, Traces)
	local Ground = Traces.Ground.HitPos

	NodeTrace.start  = Ground + UpNormal * MaxJump
	NodeTrace.endpos = Ground + UpNormal * 55000
	NodeTrace.mins   = -NodeSize
	NodeTrace.maxs   = NodeSize

	local Sky    = TraceHull(NodeTrace)
	local HitPos = Sky.HitPos

	NodeTrace.start  = HitPos
	NodeTrace.endpos = HitPos + UpNormal * -55000

	local Spot    = TraceHull(NodeTrace)
	local Floor   = TraceLine(NodeTrace)
	local FootPos = Floor.HitPos

	if Data.Coordinates ~= CNode.GetCoordinates(Grid.Name, FootPos) then return end
	if Spot.HitPos.z - FootPos.z > MaxJump then return end

	local Height = HitPos.z - FootPos.z

	if Height < MaxHeight then
		if Height < MaxCrouch then return end

		Data.Crouch = true
	end

	Traces.Sky   = Sky
	Traces.Floor = Floor

	return true
end

local function CheckWater(Data, Traces)
	NodeTrace.mask = MASK_WATER

	local Water  = TraceLine(NodeTrace)
	local Floor  = Traces.Floor.HitPos
	local Depth  = Water.HitPos.z - Floor.z

	if Water.Hit and Depth > 0 then
		if Depth > MaxCrouch then return end

		if Data.Crouch and Depth > MaxJump then
			Data.Crouch = nil
		end

		Data.FootPos = Floor
		Data.Depth   = Depth
	else
		Data.FootPos = Floor
	end

	Traces.Water = Water

	return true
end

local function ComputeCost(Data, Traces)
	local Cost = Globals.Materials[Traces.Ground.MatType] or 1

	if Data.Crouch then
		Cost = Cost * 1.5
	elseif Data.Depth then
		local Mult = 1 + (Data.Depth / MaxCrouch) * 0.5

		Cost = Cost * Mult
	end

	Data.Cost = Cost
end

local function PerformCheck(Data)
	local Traces = { Ground = true, Sky = true, Floor = true, Water = true, }

	if not CheckGround(Data, Traces) then return end
	if not CheckVertical(Data, Traces) then return end
	if not CheckWater(Data, Traces) then return end

	ComputeCost(Data, Traces)

	return Data
end

function Nodes.CheckSpot(Pos)
	local Position = CNode.GetRoundedPos(Grid.Name, Pos)

	return PerformCheck({
		Coordinates = Utils.DivideVector(Position, Grid.NodeSize),
	})
end

function Nodes.CheckCoordinates(Coords)
	return PerformCheck({
		Coordinates = Coords,
	})
end

do -- Connection check
	local CrouchSize   = Vector(HalfWidth, HalfWidth, MaxCrouch - MaxJump)
	local CrouchOffset = Vector(0, 0, MaxJump + CrouchSize.z * 0.5)

	local MoveTrace = {
		start  = true,
		endpos = true,
		mins   = true,
		maxs   = true,
		mask   = MASK_PLAYERSOLID_BRUSHONLY,
	}

	local function CheckMidpoint(From, To)
		local Position = (From + To) * 0.5

		NodeTrace.start  = Position + HalfHeight
		NodeTrace.endpos = Position - HalfHeight
		NodeTrace.mask   = MASK_PLAYERSOLID_BRUSHONLY
		NodeTrace.mins   = -NodeSize
		NodeTrace.maxs   = NodeSize

		local Zone = TraceHull(NodeTrace)

		if Zone.StartSolid then return end
		if Zone.HitNotSolid then return end
		if Zone.Hit and UpNormal:Dot(Zone.HitNormal) < MaxSlope then return end

		NodeTrace.start  = Zone.HitPos
		NodeTrace.endpos = Zone.HitPos - UpNormal * 55000

		local Center = TraceLine(NodeTrace)

		return Center.HitPos
	end

	local function CheckMove(From, To)
		if To.z - From.z > MaxJump then return end

		MoveTrace.start  = From + CrouchOffset
		MoveTrace.endpos = To + CrouchOffset

		local Result = TraceHull(MoveTrace)

		return not Result.Hit
	end

	function Nodes.CanConnect(From, To)
		local Center = CheckMidpoint(From, To)

		if not Center then return end

		local First = CheckMidpoint(From, Center)
		local Second = CheckMidpoint(Center, To)

		if not First then return end
		if not Second then return end

		MoveTrace.mins = -CrouchSize
		MoveTrace.maxs = CrouchSize

		if not CheckMove(From, First) then return end
		if not CheckMove(First, Center) then return end
		if not CheckMove(Center, Second) then return end
		if not CheckMove(Second, To) then return end

		return true
	end
end
