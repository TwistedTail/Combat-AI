AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- Note: OnEntitySight and OnEntityLostSight don't work with players and non-nextbot NPCs

local util    = util
local CNode   = CNode
local Utils   = CAI.Utilities
local Globals = CAI.Globals
local Tick    = 0.105 -- Nextbot tickrate, can it be changed?
local NoBrain = GetConVar("ai_disabled")

ENT.GridName     = "human" -- Name of the grid used by the bot
ENT.MaxHealth    = 100
ENT.MaxViewRange = 10000
ENT.FieldOfView  = 120
ENT.JumpOffset   = Vector(0, 0, Globals.MaxJump)
ENT.WalkSpeed    = 200 -- Temp
ENT.WalkAccel    = 400 -- Temp
ENT.RunSpeed     = 400 -- Temp
ENT.RunAccel     = 800 -- Temp

function ENT:Initialize()
	self:SetModel("models/humans/group03/male_09.mdl")
	self:SetMaxHealth(self.MaxHealth)
	self:SetHealth(self.MaxHealth)

	self:SetMaxVisionRange(self.MaxViewRange)
	self:SetFOV(self.FieldOfView)
	self:AddFlags(FL_OBJECT)

	self.Grid      = CNode.GetGrid(self.GridName)
	self.UID       = Utils.GetUID(self.GridName .. self:EntIndex())
	self.Filter    = { self }
	self.Sequences = {}
	self.Waypoints = {}
	self.Targets   = {}
	self.MaxSpeed  = self.RunSpeed
	self.Accel     = self.RunAccel
	self.EyesIndex = self:LookupAttachment("eyes")

	self:OnInitialized()
end

function ENT:OnInitialized()
	self:JoinOrCreateSquad()
	self:GiveWeapon("rifle")
end

function ENT:OnRemove()
	local Weapon = self.Weapon

	self:LeaveSquad()

	if Weapon then
		Weapon:Remove()
	end
end

do -- Weaponry functions
	local Weaponry = CAI.Weaponry

	function ENT:GiveWeapon(Name)
		if not isstring(Name) then return end

		local Weapon = Weaponry.Give(Name, self)

		if not Weapon then return end

		self:SetSequences(Weapon.Sequences)

		self.Weapon = Weapon

		return true
	end

	function ENT:Attack(Entity)
		if not self.Weapon then return end
		if not IsValid(Entity) then return end

		local Position = Entity:EyePos()

		self.loco:FaceTowards(Position)
		self.Weapon:Shoot(Position)
	end

	function ENT:AttackPos(Position)
		if not self.Weapon then return end
		if not isvector(Position) then return end

		self.loco:FaceTowards(Position)
		self.Weapon:Shoot(Position)
	end
end

do -- Sequence functions
	function ENT:SetSequences(Sequences)
		if not istable(Sequences) then return end

		for K in pairs(self.Sequences) do
			self.Sequences[K] = nil
		end

		for K, V in pairs(Sequences) do
			self.Sequences[K] = V
		end
	end

	function ENT:ChangeSequence(Name)
		if not isstring(Name) then return end

		local Data = self.Sequences[Name]

		if not Data then return end

		if istable(Data) then
			local Index = math.random(#Data)

			self:SetSequence(Data[Index])
		else
			self:SetSequence(Data)
		end

		self:ResetSequenceInfo()

		return true
	end
end

do -- Squadron functions and hooks
	local Squads = CAI.Squadrons

	function ENT:JoinOrCreateSquad()
		if self.Squadron then return end

		for Squad in pairs(Squads.GetAll()) do
			if Squad:AddMember(self) then return end
		end

		local Name = Utils.GetUID(self.GridName)
		local New = Squads.Create(Name)

		New:AddMember(self)
	end

	function ENT:HasRelation(Entity)
		if not self.Squadron then return end

		return self.Squadron:HasRelation(Entity)
	end

	function ENT:GetRelation(Entity)
		if not self.Squadron then return end

		return self.Squadron:GetRelation(Entity)
	end

	function ENT:ForgetRelation(Entity)
		if not self.Squadron then return end

		return self.Squadron:ForgetRelation(Entity)
	end

	function ENT:LeaveSquad()
		if not self.Squadron then return end

		self.Squadron:RemoveMember(self)
	end

	-- Hooks

	function ENT:OnJoinedSquad(Squad)
		print(self, "OnJoinedSquad", Squad)
	end

	function ENT:OnLeftSquad(Squad)
		print(self, "OnLeftSquad", Squad)
	end

	function ENT:OnSetRelation(Entity, Previous, Relation)
		print(self, "OnSetRelation", Entity, Previous, Relation)
	end

	function ENT:OnForgetRelation(Entity, Relation)
		print(self, "OnForgetRelation", Entity, Relation)
	end
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

do -- Path functions
	local Paths = CAI.Paths

	function ENT:RequestPath(Goal, Type)
		if not isvector(Goal) then return end

		Paths.Request(self, self.GridName, self.Position, Goal, Type)
	end

	function ENT:ReceivePath(Path, Type)
		print(self, " received path ", Type or "Unknown")

		for I = 1, #Path do
			self:PushWaypoint(Path[I])
		end
	end
end

do -- Aim pose functions. NOTE: These seem to require a specific sequence/activity to work.
	function ENT:UpdateAimPose()
		if not self.AimPos then return end

		local Direction = (self.AimPos - self.ShootPos):GetNormalized()
		local ViewAng   = self:WorldToLocalAngles(Direction:Angle())

		ViewAng:Normalize()

		self:SetPoseParameter("aim_pitch", ViewAng.p)
		self:SetPoseParameter("aim_yaw", ViewAng.y)
	end

	function ENT:AimToPos(Position)
		if not isvector(Position) then return end

		self.AimPos = Position
	end

	function ENT:StopAiming()
		self.AimPos = nil

		self:SetPoseParameter("aim_pitch", 0)
		self:SetPoseParameter("aim_yaw", 0)
	end
end

do -- Head pose functions
	function ENT:UpdateHeadPose()
		if not self.LookPos then return end

		local Direction = (self.LookPos - self.ShootPos):GetNormalized()
		local LookAng   = self:WorldToLocalAngles(Direction:Angle())

		LookAng:Normalize()

		self:SetPoseParameter("head_pitch", LookAng.p)
		self:SetPoseParameter("head_yaw", LookAng.y)
	end

	function ENT:LookAtPos(Position)
		if not isvector(Position) then return end

		self.LookPos = Position
	end

	function ENT:StopLooking()
		self.LookPos = nil

		self:SetPoseParameter("head_pitch", 0)
		self:SetPoseParameter("head_yaw", 0)
	end
end

do -- Movement functions
	local Trace = { start = true, endpos = true, mins = true, maxs = true, filter = true }
	local Down  = Vector(0, 0, -55000)

	function ENT:GetGroundPos(Position)
		Trace.start  = Position
		Trace.endpos = Position + Down
		Trace.filter = self.Filter

		return util.TraceLine(Trace).HitPos
	end

	function ENT:CalculateMove(Desired)
		local Min, Max = self:OBBMins(), self:OBBMaxs()
		local Start    = self.Position + self.JumpOffset

		Trace.start  = Start
		Trace.endpos = Start + Desired
		Trace.filter = self.Filter
		Trace.mins   = Min
		Trace.maxs   = Max

		Min.z = 0
		Max.z = 0

		return self:GetGroundPos(util.TraceHull(Trace).HitPos)
	end

	function ENT:MoveTowards(Position)
		local Delta    = self:GetGroundPos(Position) - self.Position
		local Target   = math.Round(Delta:Length())
		local Possible = math.min(self.MaxMove, Target)
		local Result   = self:CalculateMove(Delta:GetNormalized() * Possible)

		self.MaxMove = self.MaxMove - Possible

		self.loco:FaceTowards(Result)
		self:SetPos(Result)

		return Result
	end

	function ENT:HasDestiny()
		if self.Destiny then return true end
		if not next(self.Waypoints) then
			self:ChangeSequence("aim_idle")

			return false
		end

		self.Destiny = self:ShiftWaypoint()

		if self.Destiny then
			self:ChangeSequence("aim_run")
		end

		return true
	end

	function ENT:MoveToDestiny()
		if self.Halted then return end
		if not self:HasDestiny() then return end

		while self.Destiny and self.MaxMove > 0 do
			local Position = self:MoveTowards(self.Destiny)

			if Position == self.Destiny or Position:IsEqualTol(self.Position, 0.001) then
				self.Destiny = self:ShiftWaypoint()

				if not self.Destiny then
					print("Arrived")
				else
					print("Moved to next waypoint")
				end
			end

			self.Position = Position
		end
	end
end

do -- NextBot hooks
	function ENT:RunBehaviour()
		while true do
			if not NoBrain:GetBool() then
				self.MaxMove = self.MaxSpeed * Tick

				self:MoveToDestiny()
			end

			coroutine.yield()
		end
	end

	function ENT:Think()
		local Eyes   = self:GetAttachment(self.EyesIndex)
		local Weapon = self.Weapon

		self.Position = self:GetPos()
		self.ShootPos = Eyes.Pos

		if self.OnFire then
			if self:IsOnFire() then
				self:OnBurned()
			else
				self.OnFire = nil

				self:OnExtinguished()
			end
		end

		if Weapon then
			Weapon:Think()
		end

		self:UpdateHeadPose()
		self:UpdateAimPose()
	end

	function ENT:OnIgnite()
		if self.OnFire then return end

		self.OnFire = true

		print(self, "OnIgnite")
	end

	function ENT:OnBurned()
		print(self, "OnBurned")
	end

	function ENT:OnExtinguished()
		print(self, "OnExtinguished")
	end

	-- Broken, June 2021 update seems to have capped MaxViewRange to 320 units
	--[[
	function ENT:OnEntitySight(Entity)
		if Entity:IsPlayer() then return end -- Ignore players, broken

		if not self:HasRelation(Entity) then
			self:GetRelation(Entity)
		end

		print(self, "OnEntitySight", Entity)
	end

	function ENT:OnEntitySightLost(Entity)
		if Entity:IsPlayer() then return end -- Ignore players, broken

		print(self, "OnEntitySightLost", Entity)
	end
	]]

	function ENT:OnOtherKilled(Entity)
		if self.IsLeader then
			self:ForgetRelation(Entity)
		end

		print(self, "OnOtherKilled", Entity)
	end

	function ENT:OnInjured(DamageInfo)
		print(self, "OnInjured", DamageInfo:GetAttacker(), DamageInfo:GetInflictor())
	end

	function ENT:OnKilled(DamageInfo)
		local Weapon = self.Weapon

		hook.Run("OnNPCKilled", self, DamageInfo:GetAttacker(), DamageInfo:GetInflictor())

		self:LeaveSquad()

		if Weapon then
			Weapon:Remove()
		end

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
