local Globals = CAI.Globals
local Meta    = CAI.Squadrons.GetMeta()

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

	local View = self.View

	self.Leader = Entity

	Entity.IsLeader = true

	if Entity.OnPromoted then
		Entity:OnPromoted(self)
	end

	if not IsValid(View) then
		self.View = CAI.CreateViewTrigger(self, Entity.MaxViewRange)
	else
		View.Leader = Entity

		View:UpdateRadius(Entity.MaxViewRange)
	end

	return true
end

function Meta:GetLeader()
	return self.Leader
end
