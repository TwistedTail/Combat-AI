AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- Note: OnEntitySight and OnEntityLostSight don't work with players and non-nextbot NPCs

local util    = util
local CNode   = CNode
local Utils   = CAI.Utilities
local Globals = CAI.Globals
local Tick    = 0.105 -- Nextbot tickrate, can it be changed?

ENT.EyesName     = "eyes" -- Name of the eyes attachment
ENT.GridName     = "human"
ENT.MaxHealth    = 100
ENT.MaxViewRange = 10000
ENT.FieldOfView  = 120
ENT.JumpOffset   = Vector(0, 0, Globals.MaxJump)
ENT.WalkSpeed    = 200 -- Temp
ENT.WalkAccel    = 400 -- Temp
ENT.RunSpeed     = 400 -- Temp
ENT.RunAccel     = 800 -- Temp
ENT.SwimSpeed    = 100 -- Temp
ENT.SwimAccel    = 200 -- Temp

function ENT:Initialize()
	self:SetModel("models/humans/group03/male_09.mdl")
	self:SetMaxHealth(self.MaxHealth)
	self:SetHealth(self.MaxHealth)

	self:SetMaxVisionRange(self.MaxViewRange)
	self:SetFOV(self.FieldOfView)
	self:AddFlags(FL_OBJECT)

	self.Grid      = CNode.GetGrid(self.GridName)
	self.UID       = Utils.GetUID(self.GridName .. self:EntIndex())
	self.Waypoints = {}
	self.Targets   = {}
	self.MaxSpeed  = self.RunSpeed
	self.Accel     = self.RunAccel
	self.EyesIndex = self:LookupAttachment(self.EyesName)

	-- Model has no eyes attachment
	if self.EyesIndex < 1 then
		self.GetShootPos = self.EyePos
		self.EyesIndex   = nil
	end
end

function ENT:GetShootPos()
	local Data = self:GetAttachment(self.EyesIndex)

	return Data.Pos
end

do -- Get/Set Target
	function ENT:SetTarget(Entity)
		if not IsValid(Entity) then return false end

		self.Target = Entity

		return true
	end

	function ENT:GetTarget()
		return self.Target
	end
end

do -- Waypoint functions
	local table    = table
	local isvector = isvector

	-- Returns the first waypoint and removes it from the list
	function ENT:ShiftWaypoint()
		return table.remove(self.Waypoints, 1)
	end

	-- Returns the last waypoint and removes it from the list
	function ENT:PopWaypoint()
		return table.remove(self.Waypoints)
	end

	-- Inserts a waypoint at the top of the list and shifts the rest
	function ENT:UnshiftWaypoint(Position)
		if not isvector(Position) then return false end
		if not CNode.HasGrid(self.GridName, Position) then return false end

		table.insert(self.Waypoints, 1, Position)

		return true
	end

	-- Inserts a waypoint at the end of the list
	function ENT:PushWaypoint(Position)
		if not isvector(Position) then return false end
		if not CNode.HasGrid(self.GridName, Position) then return false end

		local Points = self.Waypoints

		Points[#Points + 1] = Position

		return true
	end
end

do -- Movement functions
	local Trace = { start = true, endpos = true, mins = true, maxs = true, filter = true }

	function ENT:GetGroundPos(Position)
		Trace.start  = Position
		Trace.endpos = Position - Vector(0, 0, 55000)
		Trace.filter = { self }

		return util.TraceLine(Trace).HitPos
	end

	function ENT:GetMovePos(Desired)
		local Min, Max = self:OBBMins(), self:OBBMaxs()

		Min.z = 0
		Max.z = 0

		Trace.start  = self.Position + self.JumpOffset
		Trace.endpos = Desired + self.JumpOffset
		Trace.filter = { self }
		Trace.mins   = Min
		Trace.maxs   = Max

		return self:GetGroundPos(util.TraceHull(Trace).HitPos)
	end

	-- NOTE: Very slow movement after climbing something, why?
	function ENT:MoveToPos(Position)
		local Delta   = Position - self.Position
		local Target  = math.Round(Delta:Length())
		local Max     = math.min(self.MaxSpeed * Tick, Target)
		local Desired = self:GetGroundPos(self.Position + Delta:GetNormalized() * Max)
		local Result  = self:GetMovePos(Desired)

		self.loco:FaceTowards(Result)
		self:SetPos(Result)

		return Result
	end

	function ENT:HasDestiny()
		if self.Destiny then return true end
		if not next(self.Waypoints) then
			self:StartActivity(ACT_IDLE)

			return false
		end

		self.Destiny = self:ShiftWaypoint()

		if self.Destiny then
			self:StartActivity(ACT_RUN)
		end

		return true
	end

	function ENT:IsOnDestiny(Position)
		if not Position:IsEqualTol(self.Destiny, 1) then return false end

		self.Destiny = self:ShiftWaypoint()

		return true
	end

	function ENT:MoveToDestiny()
		if self.Halted then return end
		if not self:HasDestiny() then return end

		local NewPos = self:MoveToPos(self.Destiny)

		if self:IsOnDestiny(NewPos) then
			if not self.Destiny then
				print("Arrived")
			else
				print("Moved to next waypoint")
			end
		elseif self.Position == NewPos then
			self.Destiny = self:ShiftWaypoint()

			print("Stuck")
		end
	end
end

do -- NextBot hooks
	function ENT:RunBehaviour()
		self.Speed = 0

		self:StartActivity(ACT_IDLE)

		while true do
			self:MoveToDestiny()

			coroutine.yield()
		end
	end

	function ENT:Think()
		if self.OnFire and not self:IsOnFire() then
			self.OnFire = nil

			self:OnExtinguished()
		end

		self.Position = self:GetPos()
	end

	function ENT:OnIgnite()
		if self.OnFire then return end

		self.OnFire = true

		print(self, "OnIgnite")
	end

	function ENT:OnExtinguished()
		print(self, "OnExtinguished")
	end

	function ENT:OnEntitySight(Entity)
		if Entity:IsPlayer() then return end -- Ignore players, broken

		print(self, "OnEntitySight", Entity)
	end

	function ENT:OnEntitySightLost(Entity)
		if Entity:IsPlayer() then return end -- Ignore players, broken

		print(self, "OnEntitySightLost", Entity)
	end

	function ENT:OnOtherKilled(Entity)
		print(self, "OnOtherKilled", Entity)
	end

	function ENT:OnInjured(DamageInfo)
		print(self, "OnInjured", DamageInfo:GetAttacker(), DamageInfo:GetInflictor())
	end

	function ENT:OnKilled(DamageInfo)
		hook.Run("OnNPCKilled", self, DamageInfo:GetAttacker(), DamageInfo:GetInflictor())

		if self.OnFire then
			self:SetModel("models/player/charple.mdl")
		end

		local Ragdoll = self:BecomeRagdoll(DamageInfo)

		if IsValid(Ragdoll) then
			self:OnRagdollDeath(Ragdoll, DamageInfo)
		end
	end

	function ENT:OnRagdollDeath(Ragdoll, DamageInfo)
		print(self, "OnRagdollDeath", Ragdoll, DamageInfo)
	end
end
