local Globals = CAI.Globals
local Squads  = CAI.Squadrons
local Utils   = CAI.Utilities
local Objects = Squads.Objects
local Meta    = {}

do -- Squadron object methods
	local format = string.format
	local Name   = "CAI Squadron %s"

	local ValidRelations = {
		Friend = true,
		Foe = true,
		Neutral = true,
	}

	local function IsPawn(Entity)
		if not IsValid(Entity) then return false end
		if Entity:IsNextBot() then return true end
		if Entity:IsPlayer() then return true end

		return Entity:IsBot()
	end

	function Meta:Lock()
		self.Locked = true
	end

	function Meta:Unlock()
		self.Locked = nil
	end

	function Meta:SetLock(Value)
		self.Locked = tobool(Value)
	end

	function Meta:IsLocked()
		return self.Locked or false
	end

	function Meta:CanAddMember(Entity)
		if self.Locked then return false end
		if not IsValid(Entity) then return false end
		if not Entity.IsCAIBot then return false end
		if self:IsFoe(Entity) then return false end

		return self.Size < Globals.SquadSize
	end

	function Meta:AddMember(Entity)
		if not self:CanAddMember(Entity) then return end
		if self.Members[Entity] then return end

		local OldSquad = Entity.Squadron

		self.Members[Entity] = true
		self.Size = self.Size + 1

		if OldSquad then
			OldSquad:RemoveMember(Entity)
		end

		self:SetRelation(Entity, "Friend")

		if Entity.OnJoinedSquad then
			Entity.Squadron = self

			Entity:OnJoinedSquad(self)
		end

		if not IsValid(self.Leader) then
			self:SetLeader(Entity)
		end

		return true
	end

	function Meta:RemoveMember(Entity)
		if not IsValid(Entity) then return end
		if not Entity.IsCAIBot then return end
		if not self.Members[Entity] then return end

		self.Members[Entity] = nil
		self.Size = self.Size - 1

		if Entity.OnLeftSquad then
			Entity.Squadron = nil

			Entity:OnLeftSquad(self)
		end

		local Leader = next(self.Members)

		if not Leader then
			self:Disband()
		elseif self.Leader == Entity then
			self:SetLeader(Leader)
		end

		return true
	end

	function Meta:GetMembers()
		local Result = {}

		for Member in pairs(self.Members) do
			Result[Member] = true
		end

		return Result
	end

	function Meta:ListMembers()
		local Result = {}
		local Index  = 0

		for Member in pairs(self.Members) do
			Index = Index + 1

			Result[Index] = Member
		end

		return Result
	end

	function Meta:SetLeader(Entity)
		if not IsValid(Entity) then return end
		if not Entity.IsCAIBot then return end
		if not self.Members[Entity] then return end

		self.Leader = Entity

		Entity.IsLeader = true

		if Entity.OnPromoted then
			Entity:OnPromoted(self)
		end

		return true
	end

	function Meta:GetLeader()
		return self.Leader
	end

	function Meta:FindRelation(Entity)
		local Result = hook.Run("CAI_GetEntityRelation", self, Entity)

		if not (Result and ValidRelations[Result]) then
			Result = "Neutral"
		end

		self:SetRelation(Entity, Result)

		return Result
	end

	function Meta:HasRelation(Entity)
		if not IsValid(Entity) then return false end

		local Relations = self.Relations

		return Relations.Entities[Entity] and true or false
	end

	function Meta:GetRelation(Entity)
		if not IsPawn(Entity) then return end

		local Relations = self.Relations
		local Relation  = Relations.Entities[Entity]

		return Relation or self:FindRelation(Entity)
	end

	function Meta:SetRelation(Entity, Relation)
		if not IsPawn(Entity) then return end
		if not ValidRelations[Relation] then return end

		local Relations = self.Relations
		local Previous  = Relations.Entities[Entity]

		if Relation == Previous then return end

		Relations.Entities[Entity]  = Relation
		Relations[Relation][Entity] = true

		if Previous then
			Relations[Previous][Entity] = nil
		else
			Entity:CallOnRemove("CAI Squad Relation " .. self.UID, function()
				if not IsValid(self) then return end

				self:ForgetRelation(Entity)
			end)
		end

		for Bot in pairs(self.Members) do
			Bot:OnSetRelation(Entity, Previous, Relation)
		end

		return true
	end

	function Meta:ForgetRelation(Entity)
		if not IsValid(Entity) then return end

		local Relations = self.Relations
		local Relation  = Relations.Entities[Entity]

		if not Relation then return end

		Entity:RemoveCallOnRemove("CAI Squad Relation " .. self.UID)

		Relations[Relation][Entity] = nil
		Relations.Entities[Entity]  = nil

		for Bot in pairs(self.Members) do
			Bot:OnForgetRelation(Entity, Relation)
		end

		return true
	end

	function Meta:GetRelations()
		local Result = {}

		for Entity, Relation in pairs(self.Relations.Entities) do
			Result[Entity] = Relation
		end

		return Result
	end

	function Meta:GetFriends()
		local Result = {}

		for Entity in pairs(self.Relations.Friend) do
			Result[Entity] = true
		end

		return Result
	end

	function Meta:GetFoes()
		local Result = {}

		for Entity in pairs(self.Relations.Friend) do
			Result[Entity] = true
		end

		return Result
	end

	function Meta:GetNeutral()
		local Result = {}

		for Entity in pairs(self.Relations.Neutral) do
			Result[Entity] = true
		end

		return Result
	end

	function Meta:IsFriend(Entity)
		return self:GetRelation(Entity) == "Friend"
	end

	function Meta:IsFoe(Entity)
		return self:GetRelation(Entity) == "Foe"
	end

	function Meta:IsNeutral(Entity)
		return self:GetRelation(Entity) == "Neutral"
	end

	function Meta:Disband()
		if self.Disbanded then return end

		self.Disbanded = true

		for Member in pairs(self.Members) do
			self:RemoveMember(Member)
		end

		Squads.Remove(self.Name)
	end

	function Meta:RequestPath(Goal, Type)
		for Member in pairs(self.Members) do
			Member:RequestPath(Goal, Type)
		end
	end

	function Meta:IsValid()
		return not self.Disbanded
	end

	function Meta:ToString()
		return format(Name, self.UID)
	end

	Meta.__index = Meta
	Meta.__tostring = Meta.ToString
end

function Squads.Create(Name, Settings)
	if not isstring(Name) then return end
	if Objects[Name] then return end
	if not istable(Settings) then Settings = {} end

	local Object = {
		IsSquadron = true,
		UID        = Utils.GetUID(Name),
		Name       = Name,
		Members    = {},
		Size       = 0,
		Relations = {
			Entities = {},
			Friend = {},
			Foe = {},
			Neutral = {}
		}
	}

	setmetatable(Object, Meta)

	Objects[Name] = Object

	return Object
end

function Squads.Get(Name)
	if not isstring(Name) then return end

	return Objects[Name]
end

function Squads.GetAll()
	local Result = {}

	for _, Squad in pairs(Objects) do
		Result[Squad] = true
	end

	return Result
end

function Squads.Remove(Name)
	if not isstring(Name) then return end

	Objects[Name] = nil
end
