local Globals = CAI.Globals
local Squads  = CAI.Squadrons
local Utils   = CAI.Utilities
local Objects = Squads.Objects
local Meta    = {}

do -- Squadron object methods
	local format = string.format
	local Name   = "CAI Squadron %s"

	function Meta:CanBeJoined()
		return self.Size < Globals.SquadSize
	end

	function Meta:AddMember(Entity)
		if not self:CanBeJoined() then return end
		if not IsValid(Entity) then return end
		if not Entity.IsCAIBot then return end

		if self.Members[Entity] then return end

		local OldSquad = Entity.Squadron

		self.Members[Entity] = true
		self.Size = self.Size + 1

		if OldSquad then
			OldSquad:RemoveMember(Entity)
		end

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

		self.Leader = Entity

		if Entity.OnPromoted then
			Entity:OnPromoted(self)
		end

		return true
	end

	function Meta:GetLeader()
		return self.Leader
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
		UID = Utils.GetUID(Name),
		Name = Name,
		Members = {},
		Size = 0,
		IsSquadron = true,
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
