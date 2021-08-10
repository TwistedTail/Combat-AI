AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- NOTE: OnEntitySight and OnEntityLostSight don't work with players and non-nextbot NPCs

local util     = util
local CNode    = CNode
local isvector = isvector
local isstring = isstring
local Utils    = CAI.Utilities
local Globals  = CAI.Globals
local Tick     = 0.105 -- Nextbot tickrate, can it be changed?
local NoBrain  = GetConVar("ai_disabled")

ENT.GridName     = "human" -- Name of the grid used by the bot
ENT.MaxHealth    = 100
ENT.MaxViewRange = 7500
ENT.FieldOfView  = 120
ENT.MinApproach  = 2500
ENT.JumpOffset   = Vector(0, 0, Globals.MaxJump)
ENT.WalkSpeed    = 200 -- Temp
ENT.WalkAccel    = 400 -- Temp
ENT.RunSpeed     = 400 -- Temp
ENT.RunAccel     = 800 -- Temp

ENT.DefaultHoldType = "normal"
ENT.DefaultEmotion  = "Calm"
ENT.DefaultMovement = "Idle"
ENT.DefaultStance   = "Normal"

ENT.MoveTypes = {
	Idle = {
		MaxSpeed     = 0,
		Acceleration = 0,
	},
	Walk = {
		MaxSpeed     = 200,
		Acceleration = 400,
	},
	Run = {
		MaxSpeed     = 400,
		Acceleration = 800,
	},
}

ENT.HoldTypes = {
	normal = {
		Calm = {
			Idle = {
				Normal = {
					"idle_subtle",
					"idle_angry",
					"LineIdle01",
					"LineIdle03",
				},
				Crouch = "Crouch_idleD", -- NOTE: Look for a better one.
			},
			Walk = {
				Normal = {
					"walk_all_Moderate",
					"walk_all",
				},
				Crouch = "Crouch_walk_all",
			},
			Run = {
				Normal = "run_all", -- NOTE: sprint_all was too exaggerated in my opinion
				Crouch = "CrouchRUNALL1",
			},
		},
	},
	ar2 = {
		Calm = {
			Idle = {
				Normal = {
					"Idle_Alert_AR2_1",
					"Idle_Alert_AR2_2",
					"Idle_Alert_AR2_3",
					"Idle_Alert_AR2_4",
					"Idle_Alert_AR2_5",
					"Idle_Alert_AR2_6",
					"Idle_Alert_AR2_7",
					"Idle_Alert_AR2_8",
					"Idle_Alert_AR2_9",
					"idle_angry_Ar2",
				},
				Crouch = "Crouch_idleD",
			},
			Walk = {
				Normal = {
					"walkHOLDALL1_ar2",
					"walkAlertHOLD_AR2_ALL1",
				},
				Crouch = "Crouch_walk_holding_all",
			},
			Run = {
				Normal = {
					"run_holding_ar2_all",
					"run_alert_holding_ar2_all",
				},
				Crouch = "crouchRUNHOLDINGALL1",
			},
		},
		Combat = {
			Idle = {
				Normal = "idle_ar2_aim",
				Crouch = "crouch_aim_smg1",
			},
			Walk = {
				Normal = "walkAIMALL1_ar2",
				Crouch = "Crouch_walk_aiming_all",
			},
			Run = {
				Normal = "run_aiming_ar2_all",
				Crouch = "crouchRUNAIMINGALL1",
			},
		},
	}
}

function ENT:Initialize()
	self:SetMaxHealth(self.MaxHealth)
	self:SetHealth(self.MaxHealth)
	self:AddFlags(FL_OBJECT)
	self:SetupModel()

	self.Grid      = CNode.GetGrid(self.GridName)
	self.UID       = Utils.GetUID(self.GridName .. self:EntIndex())
	self.Filter    = { self }
	self.Targets   = {}
	self.EyesIndex = self:LookupAttachment("eyes")

	self.Paths = {
		Route    = { Entries = {}, Receiver = self.SetRoutePath },
		Approach = { Entries = {}, Receiver = self.SetApproachPath },
		Sector   = { Entries = {}, Receiver = self.SetSectorPath },
	}

	self:SetHoldType("normal") -- Initializing sequences and movement speed
	self:UpdatePosition()
	self:OnInitialized()
end

function ENT:OnRemove()
	if self.OnGrid then
		CNode.UnlockNode(self.GridName, self.Position) -- NOTE: Might want to check the coordinates before unlocking a node
	end

	self:OnRemoved()
end

function ENT:SetupModel()
	self:SetModel("models/humans/group03/male_09.mdl")
end

function ENT:OnInitialized()
	self:JoinOrCreateSquad()
	self:GiveWeapon("rifle")
end

function ENT:OnRemoved()
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

		self:SetHoldType(Weapon.HoldType)

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

do -- World and grid position functions
	function ENT:UpdatePosition(Position)
		if not Position then Position = self:GetPos() end
		if Position == self.Position then return end

		local Grid    = self.GridName
		local LastPos = self.Position
		local Current = self.Coordinates
		local OnGrid  = CNode.HasNode(Grid, Position)

		self.Position = Position

		if Current then
			if not OnGrid then
				self.OnGrid      = nil
				self.Coordinates = nil

				CNode.UnlockNode(Grid, LastPos) -- NOTE: Might want to check the coordinates before unlocking a node

				self:OnLeftGrid(Current)
			else
				local New = CNode.GetCoordinates(Grid, Position)

				if Current == New then return end -- We're still on the same spot

				self.Coordinates = New

				CNode.UnlockNode(Grid, LastPos) -- NOTE: Might want to check the coordinates before unlocking a node
				CNode.LockNode(Grid, Position)

				self:OnChangedCoords(Current, New)
			end
		elseif OnGrid then
			local New = CNode.GetCoordinates(Grid, Position)

			self.OnGrid      = true
			self.Coordinates = New

			CNode.LockNode(Grid, Position)

			self:OnEnteredGrid(New)
		end
	end

	function ENT:OnEnteredGrid(Coordinates)
		print(self, "OnEnteredGrid", Coordinates)
	end

	function ENT:OnChangedCoords(Old, New)
		print(self, "OnChangedCoords", Old, New)
	end

	function ENT:OnLeftGrid(Coordinates)
		print(self, "OnLeftGrid", Coordinates)
	end
end

do -- Sequence functions
	function ENT:SetHoldType(HoldType)
		if not isstring(HoldType) then return end

		local Data = self.HoldTypes[HoldType]

		if not Data then return end
		if Data == self.HoldData then return end

		self.HoldType = HoldType
		self.HoldData = Data

		return self:UpdateSequence(1)
	end

	function ENT:SetEmotion(Emotion)
		if not isstring(Emotion) then return end

		if self.HoldType then
			local Data = self.HoldData[Emotion]

			if not Data then return end
			if Data == self.EmotionData then return end

			self.Emotion     = Emotion
			self.EmotionData = Data
		end

		return self:UpdateSequence(2)
	end

	function ENT:SetMovement(Movement)
		if not isstring(Movement) then return end

		if self.Emotion then
			local Data = self.EmotionData[Movement]

			if not Data then return end
			if Data == self.MoveData then return end

			local Types = self.MoveTypes
			local Move  = Types[Movement] or Types.Idle

			self.Movement = Movement
			self.MoveData = Data
			self.MaxSpeed = Move.MaxSpeed
			self.Accel    = Move.Acceleration
		end

		return self:UpdateSequence(3)
	end

	function ENT:SetStance(Stance)
		if not isstring(Stance) then return end

		if self.Movement then
			local Data = self.MoveData[Stance]

			if not Data then return end
			if Data == self.StanceData then return end

			self.Stance     = Stance
			self.LastStance = self.StanceData
			self.StanceData = Data
		end

		return self:UpdateSequence(4)
	end

	function ENT:UpdateSequence(Level)
		if not isnumber(Level) then return end
		if Level < 1 then self:SetHoldType(self.HoldType or self.DefaultHoldType) end
		if Level < 2 then self:SetEmotion(self.Emotion or self.DefaultEmotion) end
		if Level < 3 then self:SetMovement(self.Movement or self.DefaultMovement) end
		if Level < 4 then self:SetStance(self.Stance or self.DefaultStance) end
		if self.StanceData == self.LastStance then return false end

		local Data = self.StanceData

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
		local New  = Squads.Create(Name)

		New:AddMember(self)
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

	function ENT:OnEnemySighted(Entity, Index)
		print(self, "OnEnemySighted", Entity, Index)
	end

	function ENT:OnLostEnemySight(Entity)
		print(self, "OnLostEnemySight", Entity)
	end
end

do -- Visibility functions
	local Trace = { start = true, endpos = true, filter = true, mask = MASK_BLOCKLOS }
	local Bones = {
		"ValveBiped.Bip01_Head1",
		"ValveBiped.Bip01_Spine4",
		"ValveBiped.Bip01_Spine2",
		"ValveBiped.Bip01_Pelvis",
	}

	local function CanSeePos(Entity, Position)
		Trace.endpos = Position

		local Result = util.TraceLine(Trace)

		return Result.Entity == Entity or not Result.Hit, Result
	end

	function ENT:CanSee(Target)
		if not IsValid(Target) then return end
		if not self:TestPVS(Target) then return end

		Trace.start  = self:GetShootPos()
		Trace.filter = self.Filter

		for I = 1, #Bones do
			local Index = Target:LookupBone(Bones[I])

			if not Index then continue end

			local Hit, Result = CanSeePos(Target, Target:GetBonePosition(Index))

			if Hit then return true, Result end
		end

		local Hit, Result = CanSeePos(Target, Target:EyePos())

		if Hit then return true, Result end
	end

	function ENT:CanSeePos(Target)
		if not isvector(Target) then return end
		if not self:TestPVS(Target) then return end

		Trace.start  = self:GetShootPos()
		Trace.filter = self.Filter

		local Hit, Result = CanSeePos(nil, Target)

		if Hit then return true, Result end
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

do -- Waypoint and path functions
	local Paths = CAI.Paths

	-- Types:
	-- Route: Between current position and any destination on the grid
	-- Approach: Between current position and the closest waypoint of the route path
	-- Sector: Between current position and next waypoint
	-- Return: Between current position and closest grid position
	-- Cover: Between the current position and the closest hide spot
	function ENT:RequestPath(Goal, UseLocked, Type)
		if NoBrain:GetBool() then return end
		if not isvector(Goal) then return end

		Paths.Request(self, self.GridName, self.Position, Goal, UseLocked, Type)
	end

	function ENT:ReceivePath(Path, Type)
		if NoBrain:GetBool() then return end
		if not Type then return end

		local Data = self.Paths[Type]

		if Data then
			Data.Receiver(self, Path)
		end
	end

	function ENT:ResetAllPaths()
		for _, Path in pairs(self.Paths) do
			local Entries = Path.Entries

			for K in pairs(Entries) do Entries[K] = nil end
		end
	end

	function ENT:ResetPaths(...)
		local List = istable(...) and ... or { ... }

		for I = 1, #List do
			local Path = self.Paths[List[I]]

			if Path then
				local Entries = Path.Entries

				for K in pairs(Entries) do Entries[K] = nil end
			end
		end
	end

	function ENT:SetRoutePath(Path)
		if not istable(Path) then return end

		local First = Path[1]

		self:ResetAllPaths()

		if not First then return print("Got empty route path") end -- NOTE: Maybe tell it to hide?

		local Entries = self.Paths.Route.Entries
		local Grid    = self.GridName
		local Type

		for I = 1, #Path do
			local Position = Path[I]

			Entries[I] = {
				Coordinates = CNode.GetCoordinates(Grid, Position),
				Position = Position,
			}
		end

		if self.IsLeader then
			Type = "Sector"
		else
			local Limit    = self.MinApproach * self.MinApproach
			local Distance = First:DistToSqr(self.Position)

			Type = Distance < Limit and "Sector" or "Approach"
		end

		self.CurrentPath = "Route"

		self:RequestPath(First, Type == "Sector", Type)

		if Type ~= "Sector" then
			-- TODO: Tell the bot to look for a hiding spot in the meantime
		end
	end

	function ENT:SetApproachPath(Path)
		if not istable(Path) then return end

		local First = Path[1]

		self:ResetPaths("Approach", "Sector")

		if not First then return print("Got empty approach path") end -- NOTE: What now?

		local Entries = self.Paths.Approach.Entries
		local Grid    = self.GridName

		for I = 1, #Path do
			local Position = Path[I]

			Entries[I] = {
				Coordinates = CNode.GetCoordinates(Grid, Position),
				Position = Position,
			}
		end

		self.CurrentPath = "Approach"

		self:RequestPath(First, false, "Sector")
	end

	function ENT:SetSectorPath(Path)
		if not istable(Path) then return end

		local First = Path[1]

		if not First then return print("Got empty sector path") end -- NOTE: What now?

		local Entries = self.Paths.Sector.Entries
		local Grid    = self.GridName

		self:ResetPaths("Sector")

		for I = 1, #Path do
			local Position = Path[I]

			Entries[I] = {
				Coordinates = CNode.GetCoordinates(Grid, Position),
				Position = Position,
			}
		end
	end

	function ENT:GetWaypoint()
		if not self.CurrentPath then return end

		return self.Paths.Sector.Entries[1]
	end

	function ENT:UpdateWaypoint(Waypoint)
		if not self.CurrentPath then return end

		local Coordinates = self.Coordinates

		if Coordinates ~= Waypoint.Coordinates then return end

		local Sector   = self.Paths.Sector.Entries
		local PathName = self.CurrentPath
		local Entries  = self.Paths[PathName].Entries
		local Current  = Entries[1]

		table.remove(Sector, 1)

		if Coordinates == Current.Coordinates then
			table.remove(Entries, 1)

			local Next = Entries[1]

			if Next then
				self:RequestPath(Next.Position, true, "Sector")
			else
				self.CurrentPath = nil

				self:OnReachedDestiny(PathName, Waypoint.Position, Waypoint.Coordinates)
			end
		end
	end

	function ENT:OnReachedDestiny(PathName, Position, Coordinates)
		print(self, "OnReachedDestiny", PathName, Position, Coordinates)
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

	function ENT:MoveInPath()
		if self.Halted then return self:SetMovement("Idle") end

		local Waypoint = self:GetWaypoint()

		if not Waypoint then return self:SetMovement("Idle") end

		self:SetMovement("Run")

		while Waypoint and self.MaxMove > 0 do
			local Position = self:MoveTowards(Waypoint.Position)

			self:UpdateWaypoint(Waypoint)
			self:UpdatePosition(Position)

			Waypoint = self:GetWaypoint()
		end
	end
end

do -- NextBot hooks
	function ENT:RunBehaviour()
		while true do
			if NoBrain:GetBool() then
				self:SetEmotion("Calm")
				self:SetMovement("Idle")
				self:SetStance("Normal")
			else
				self.MaxMove = self.MaxSpeed * Tick

				self:MoveInPath()
			end

			coroutine.yield()
		end
	end

	function ENT:Think()
		local Eyes   = self:GetAttachment(self.EyesIndex)
		local View   = self.View
		local Weapon = self.Weapon

		self.ShootPos = Eyes.Pos
		self.ShootDir = Eyes.Ang:Forward()

		self:UpdatePosition()

		if self.OnFire then
			if self:IsOnFire() then
				self:OnBurned()
			else
				self.OnFire = nil

				self:OnExtinguished()
			end
		end

		if View then
			View:UpdatePos()
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

		self:OnIgnited()
	end

	function ENT:OnIgnited()
		print(self, "OnIgnited")
	end

	function ENT:OnBurned()
		print(self, "OnBurned")
	end

	function ENT:OnExtinguished()
		print(self, "OnExtinguished")
	end

	function ENT:OnOtherKilled(Entity)
		if self.IsLeader then
			self.Squadron:ForgetRelation(Entity)
		end

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

		if self.OnGrid then
			CNode.UnlockNode(self.GridName, self.Position) -- NOTE: Might want to check the coordinates before unlocking a node
		end

		self:OnRemoved()

		local Ragdoll = self:BecomeRagdoll(DamageInfo)

		if IsValid(Ragdoll) then
			self:OnRagdollDeath(Ragdoll, DamageInfo)
		end
	end

	function ENT:OnRagdollDeath(Ragdoll, DamageInfo)
		print(self, "OnRagdollDeath", Ragdoll, DamageInfo)
	end
end
