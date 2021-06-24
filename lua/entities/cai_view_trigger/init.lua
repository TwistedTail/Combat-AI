AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate    = true

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

function CAI.CreateViewTrigger(Parent, Radius)
	if not IsValid(Parent) then return end

	local Trigger = ents.Create("cai_view_trigger")

	if not IsValid(Trigger) then return end

	local Position = Parent.Position or Parent:GetPos()
	local Size     = Vector(Radius, Radius, Radius)

	Trigger:SetPos(Position)
	Trigger:SetModel("models/props_junk/watermelon01.mdl")
	Trigger:PhysicsInit(SOLID_OBB)
	Trigger:SetMoveType(MOVETYPE_NONE)
	Trigger:SetSolidFlags(FSOLID_NOT_SOLID + FSOLID_TRIGGER)
	Trigger:Spawn()

	Trigger:SetTrigger(true)
	Trigger:SetCollisionBounds(-Size, Size)
	Trigger:DrawShadow(false)

	Trigger:SetNWFloat("Radius", Radius)

	Trigger.Position = Position
	Trigger.Parent   = Parent
	Trigger.MaxRange = Radius * Radius
	Trigger.Filter   = { Trigger, Parent }
	Trigger.Check    = {}
	Trigger.Touched  = {}
	Trigger.Spotted  = {}
	Trigger.Unseen   = {}
	Trigger.Outside  = {}

	Parent:DeleteOnRemove(Trigger)

	Parent.View = Trigger

	return Trigger
end

function ENT:UpdatePos()
	local Position = self.Parent.Position

	self.Position = Position

	self:SetPos(Position)
end

function ENT:CheckRelation(Entity, Previous, Relation)
	if Previous == "Foe" then
		self:IgnoreEntity(Entity)
	elseif Relation == "Foe" then
		self.Check[Entity] = Utils.CurTime + 0.1
	end
end

function ENT:IgnoreEntity(Entity)
	local Touched = self.Touched
	local Entry   = Touched[Entity]

	if Entry then
		self[Entry][Entity] = nil
		Touched[Entity]     = nil

		if Entry == "Spotted" then
			self:ReportLostSight(Entity)
		end
	elseif self.Check[Entity] then
		self.Check[Entity] = nil
	end
end

function ENT:AddOutsider(Entity)
	self.Touched[Entity] = "Outside"
	self.Outside[Entity] = true
end

function ENT:AddUnseen(Entity)
	self.Touched[Entity] = "Unseen"
	self.Unseen[Entity]  = true
end

function ENT:AddSpotted(Entity, Index)
	self.Touched[Entity] = "Spotted"
	self.Spotted[Entity] = Index or -1
end

function ENT:ReportSight(Entity, Index)
	if not self.Spotted[Entity] then return end

	self.Parent:OnEnemySighted(Entity, Index)
end

function ENT:ReportLostSight(Entity)
	if self.Spotted[Entity] then return end

	self.Parent:OnLostEnemySight(Entity)
end

function ENT:IsInRange(Entity)
	if not IsValid(Entity) then return false end

	local Position = Entity.Position or Entity:GetPos()

	return self.Position:DistToSqr(Position) <= self.MaxRange
end

function ENT:CanSee(Entity)
	if not IsValid(Entity) then return false end
	if not self.Parent:TestPVS(Entity) then return false end

	Trace.start  = self.Parent.ShootPos
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

function ENT:CheckOutsiders(Checked)
	for Entity in pairs(self.Outside) do
		if Checked[Entity] then continue end

		if self:IsInRange(Entity) then
			self.Outside[Entity] = nil

			local CanSee, Index = self:CanSee(Entity)

			if CanSee then
				self:AddSpotted(Entity, Index)
				self:ReportSight(Entity, Index)
			else
				self:AddUnseen(Entity)
			end
		end

		Checked[Entity] = true
	end
end

function ENT:CheckUnseen(Checked)
	for Entity in pairs(self.Unseen) do
		if Checked[Entity] then continue end

		if not self:IsInRange(Entity) then
			self.Unseen[Entity] = nil

			self:AddOutsider(Entity)
		else
			local CanSee, Index = self:CanSee(Entity)

			if CanSee then
				self.Unseen[Entity] = nil

				self:AddSpotted(Entity, Index)
				self:ReportSight(Entity, Index)
			end
		end

		Checked[Entity] = true
	end
end

function ENT:CheckSpotted(Checked)
	for Entity in pairs(self.Spotted) do
		if Checked[Entity] then continue end

		if not self:IsInRange(Entity) then
			self.Spotted[Entity] = nil

			self:AddOutsider(Entity)
			self:ReportLostSight(Entity)
		elseif not self:CanSee(Entity) then
			self.Spotted[Entity] = nil

			self:AddUnseen(Entity)
			self:ReportLostSight(Entity)
		end

		Checked[Entity] = true
	end
end

function ENT:StartTouch(Entity)
	if not Detection.IsDetectable(Entity) then return end
	if self.Parent == Entity then return end

	if self:IsInRange(Entity) then
		local CanSee, Index = self:CanSee(Entity)

		if CanSee then
			self:AddSpotted(Entity, Index)
			self:ReportSight(Entity, Index)
		else
			self:AddUnseen(Entity)
		end
	else
		self:AddOutsider(Entity)
	end
end

function ENT:Touch(Entity)
	if not self.Check[Entity] then return end

	if self:IsInRange(Entity) then
		local CanSee, Index = self:CanSee(Entity)

		if CanSee then
			self:AddSpotted(Entity, Index)
			self:ReportSight(Entity, Index)
		else
			self:AddUnseen(Entity)
		end
	else
		self:AddOutsider(Entity)
	end

	self.Check[Entity] = nil
end

function ENT:EndTouch(Entity)
	self:IgnoreEntity(Entity)
end

function ENT:Think()
	local Checked = {}
	local Time    = Utils.CurTime

	for Entity, Limit in pairs(self.Check) do
		if Time >= Limit then
			self.Check[Entity] = nil
		end
	end

	self:CheckOutsiders(Checked)
	self:CheckUnseen(Checked)
	self:CheckSpotted(Checked)

	self:NextThink(Time + 0.1)

	return true
end
