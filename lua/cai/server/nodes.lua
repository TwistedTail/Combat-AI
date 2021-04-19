local TraceHull    = util.TraceHull
local HookRun      = hook.Run
local Globals      = CAI.Globals
local Nodes        = CAI.Nodes
local Utils        = CAI.Utilities
local MaxSlope     = Globals.MaxSlope
local HalfWidth    = Globals.MaxWidth * 0.5
local MaxHeight    = Globals.MaxHeight
local MaxCrouch    = Globals.MaxCrouch
local MaxJump      = Globals.MaxJump
local HalfHeight   = Vector(0, 0, MaxHeight * 0.5)
local UpNormal     = Vector(0, 0, 1)
local WalkSize     = Vector(HalfWidth, HalfWidth, MaxHeight - MaxJump)
local CrouchSize   = Vector(HalfWidth, HalfWidth, MaxCrouch - MaxJump)
local WalkOffset   = Vector(0,0, MaxJump + MaxHeight * 0.5)
local CrouchOffset = Vector(0,0, MaxJump + MaxCrouch * 0.5)

local NodeTrace = {
	start  = true,
	endpos = true,
	mask   = true,
	mins   = -Vector(HalfWidth, HalfWidth),
	maxs   = Vector(HalfWidth, HalfWidth),
}

local WalkTrace = {
	start  = true,
	endpos = true,
	mins   = true,
	maxs   = true,
	mask   = MASK_PLAYERSOLID_BRUSHONLY,
}

local function CheckGround(Data, Traces)
	local Position = Data.Position

	NodeTrace.start  = Position + HalfHeight
	NodeTrace.endpos = Position - HalfHeight
	NodeTrace.mask   = MASK_PLAYERSOLID_BRUSHONLY

	local Ground = TraceHull(NodeTrace)

	if Ground.StartSolid then return end
	if Ground.HitNotSolid then return end
	if Ground.Hit and UpNormal:Dot(Ground.HitNormal) < MaxSlope then return end

	Traces.Ground = Ground

	return true
end

local function CheckVertical(Data, Traces)
	local Ground = Traces.Ground.HitPos

	NodeTrace.start  = Ground
	NodeTrace.endpos = Ground + UpNormal * 55000

	local Sky    = TraceHull(NodeTrace)
	local HitPos = Sky.HitPos

	NodeTrace.start  = HitPos
	NodeTrace.endpos = HitPos + UpNormal * -55000

	local Floor = TraceHull(NodeTrace)
	local Height = (HitPos - Floor.HitPos):Length()

	if Height < MaxHeight then
		if Height < MaxCrouch then return end

		Data.Crouch = true
	end

	Traces.Sky    = Sky
	Traces.Floor = Floor

	return true
end

local function CheckWater(Data, Traces)
	NodeTrace.mask = MASK_WATER

	local Water  = TraceHull(NodeTrace)
	local Coords = Data.Coordinates
	local Floor  = Traces.Floor.HitPos

	if Water.Hit then
		local WaterPos = Water.HitPos
		local Depth    = WaterPos.z - Floor.z

		if Depth > MaxCrouch then
			if Coords ~= CNode.GetCoordinates(WaterPos) then return end

			Data.FootPos = WaterPos
			Data.Swim    = true
			Data.Crouch  = nil
		else
			if Coords ~= CNode.GetCoordinates(Floor) then return end

			if Data.Crouch and Depth > MaxJump then
				Data.Crouch = nil
			end

			Data.FootPos = Floor
			Data.Depth   = Depth
		end
	else
		if Coords ~= CNode.GetCoordinates(Floor) then return end

		Data.FootPos = Floor
	end

	Traces.Water = Water

	return true
end

local function PerformCheck(Data)
	local Traces = { Ground = true, Sky = true, Floor = true, Water = true, }

	if not CheckGround(Data, Traces) then return end
	if not CheckVertical(Data, Traces) then return end
	if not CheckWater(Data, Traces) then return end

	HookRun("CAI_CheckPosition", Data, Traces)

	return Data
end

function Nodes.CheckSpot(Pos)
	local Position = CNode.GetRoundedPos(Pos)

	return PerformCheck({
		Coordinates = Utils.DivideVector(Position, CNode.NodeSize),
		Position    = Position,
	})
end

function Nodes.CheckCoordinates(Coords)
	return PerformCheck({
		Coordinates = Coords,
		Position    = Coords * CNode.NodeSize,
	})
end

-- TODO: Add a middle check to make sure the connection is walkable
-- TODO: Add a slope check to replace that height difference bullshit
function Nodes.CanConnect(From, To)
	if math.abs(From.z - To.z) > MaxCrouch then return end -- NOTE: I don't trust this one

	WalkTrace.start  = From + WalkOffset
	WalkTrace.endpos = To + WalkOffset
	WalkTrace.mins   = -WalkSize
	WalkTrace.maxs   = WalkSize

	local Standing = TraceHull(WalkTrace)

	if not Standing.Hit then return true end -- Path is clear

	WalkTrace.start  = From + CrouchOffset
	WalkTrace.endpos = To + CrouchOffset
	WalkTrace.mins   = -CrouchSize
	WalkTrace.maxs   = CrouchSize

	return not TraceHull(WalkTrace).Hit, true
end
