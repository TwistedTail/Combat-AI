AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate    = true
ENT.ViewChecks        = 2

local util      = util
local CAI       = CAI
local Detection = CAI.Detection
local Utils     = CAI.Utilities
local Result    = {}
local Trace     = { start = true, endpos = true, filter = true, mask = MASK_BLOCKLOS, output = Result }
local Bones     = {
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_Spine4",
	"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Pelvis",
}

local function OnEntityRemoved(Entity, View)
	if not IsValid(View) then return end

	View:IgnoreEntity(Entity)
end

function CAI.CreateViewTrigger(Squadron, Radius)
	local Trigger = ents.Create("cai_view_trigger")

	if not IsValid(Trigger) then return end

	local Leader   = Squadron.Leader
	local Position = Leader.Position or Leader:GetPos()

	Trigger:SetPos(Position)
	Trigger:SetModel("models/props_junk/watermelon01.mdl")
	Trigger:PhysicsInit(SOLID_OBB)
	Trigger:SetMoveType(MOVETYPE_NONE)
	Trigger:SetSolidFlags(FSOLID_NOT_SOLID + FSOLID_TRIGGER)
	Trigger:Spawn()

	Trigger:SetTrigger(true)
	Trigger:DrawShadow(false)
	Trigger:UpdateRadius(Radius)

	Trigger.Position = Position
	Trigger.Squadron = Squadron
	Trigger.Leader   = Leader
	Trigger.Members  = Squadron.Members
	Trigger.Filter   = {}
	Trigger.Entities = {}
	Trigger.Check    = {}

	return Trigger
end

function ENT:UpdatePos()
	local Leader   = self.Leader
	local Position = Leader.Position or Leader:GetPos()

	self.Position = Position

	self:SetPos(Position)
end

function ENT:UpdateRadius(Radius)
	if self.Radius == Radius then return end

	local Size = Vector(Radius, Radius, Radius)

	self:SetCollisionBounds(-Size, Size)
	self:SetNWFloat("Radius", Radius)

	self.Radius   = Radius
	self.MaxRange = Radius * Radius
end

function ENT:GetNextWatcher()
	local Members = self.Members
	local Watcher = next(Members, self.Watcher) or next(Members)

	self.Watcher = Watcher

	return Watcher
end

function ENT:IgnoreEntity(Entity)
	local Squad = self.Squadron
	local UID   = Squad.UID

	if self.Check[Entity] then
		self.Check[Entity] = nil
	else
		local Data = self.Entities[Entity]

		if Data then
			self.Entities[Entity] = nil

			if Data.State == "Spotted" then
				Squad:OnLostSight(Entity, Data)
			end
		end
	end

	Entity:RemoveCallOnRemove("CAI Squad Sight " .. UID)
end

function ENT:CheckRelation(Entity, Previous, Relation)
	if Previous == "Foe" then
		self:IgnoreEntity(Entity)
	elseif Relation == "Foe" then
		local UID = self.Squadron.UID

		self.Check[Entity] = Utils.CurTime + 0.1

		Entity:CallOnRemove("CAI Squad Sight " .. UID, OnEntityRemoved, self)
	end
end

function ENT:IsInRange(Entity)
	if not IsValid(Entity) then return false end

	local Position = Entity.Position or Entity:GetPos()

	return self.Position:DistToSqr(Position) <= self.MaxRange
end

function ENT:CanSee(Entity, Watcher)
	if not IsValid(Entity) then return false end
	if not IsValid(Watcher) then Watcher = self:GetNextWatcher() end
	if not Watcher:TestPVS(Entity) then return false end

	Trace.start  = Watcher.ShootPos
	Trace.filter = self.Filter

	for I = 1, #Bones do
		local Index = Entity:LookupBone(Bones[I])

		if Index then
			Trace.endpos = Entity:GetBonePosition(Index)

			util.TraceLine(Trace)

			if not Result.Hit or Result.Entity == Entity then
				return true, Index
			end
		end
	end

	Trace.endpos = Entity:EyePos()

	util.TraceLine(Trace)

	return not Result.Hit or Result.Entity == Entity
end

local Checks = {
	Outside = function(View, Entity, Data)
		if not View:IsInRange(Entity) then return end

		local CanSee, Bone = View:CanSee(Entity)

		if CanSee then
			Data.State   = "Spotted"
			Data.Bone    = Bone
			Data.Watcher = View.Watcher

			View.Squadron:OnGainedSight(Entity, Data)
		else
			Data.State = "Outside"
		end
	end,
	Unseen = function(View, Entity, Data)
		if not View:IsInRange(Entity) then
			Data.State = "Outside"

			return
		end

		local CanSee, Bone = View:CanSee(Entity)

		if CanSee then
			Data.State   = "Spotted"
			Data.Bone    = Bone
			Data.Watcher = View.Watcher

			View.Squadron:OnGainedSight(Entity, Data)
		end
	end,
	Spotted = function(View, Entity, Data)
		local Squad = View.Squadron

		if not View:IsInRange(Entity) then
			Data.State   = "Outside"
			Data.Bone    = nil
			Data.Watcher = nil

			Squad:OnLostSight(Entity, Data)

			return
		end

		local Watcher = IsValid(Data.Watcher) and Data.Watcher or View:GetNextWatcher()
		local CanSee, Bone = View:CanSee(Entity, Watcher)

		if CanSee then
			-- NOTE: Watcher changes here, notify it

			Data.Bone    = Bone
			Data.Watcher = Watcher
		else
			Data.State   = "Unseen"
			Data.Bone    = nil
			Data.Watcher = nil

			Squad:OnLostSight(Entity, Data)
		end
	end,
}

function ENT:Think()
	for Entity, Data in pairs(self.Entities) do
		local Check = Checks[Data.State]

		Check(self, Entity, Data)
	end

	self:NextThink(Utils.CurTime + 0.1)

	return true
end

function ENT:StartTouch(Entity)
	if not Detection.IsDetectable(Entity) then return end
	if not self.Squadron:IsFoe(Entity) then return end

	local UID  = self.Squadron.UID
	local Data = {}

	Checks.Outside(self, Entity, Data)

	if not Data.State then
		Data.State = "Outside"
	end

	self.Entities[Entity] = Data

	Entity:CallOnRemove("CAI Squad Sight " .. UID, OnEntityRemoved, self)
end

function ENT:Touch(Entity)
	local Death = self.Check[Entity]

	if not Death then return end
	if Death < Utils.CurTime then
		local Data = {}

		Checks.Outside(self, Entity, Data)

		if not Data.State then
			Data.State = "Outside"
		end

		self.Entities[Entity] = Data
	end

	self.Check[Entity] = nil
end

function ENT:EndTouch(Entity)
	self:IgnoreEntity(Entity)
end

function ENT:OnRemove()
	local Name = "CAI Squad Sight " .. self.Squadron.UID

	for Entity in pairs(self.Check) do
		Entity:RemoveCallOnRemove(Name)

		self.Check[Entity] = nil
	end

	for Entity in pairs(self.Entities) do
		Entity:RemoveCallOnRemove(Name)

		self.Entities[Entity] = nil
	end
end
