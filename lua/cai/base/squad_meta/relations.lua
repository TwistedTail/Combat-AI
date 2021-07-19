local Meta = CAI.Squadrons.GetMeta()

local ValidRelations = {
	Friend = D_LI,
	Foe = D_HT,
	Neutral = D_NU,
}

local function IsPawn(Entity)
	if not IsValid(Entity) then return false end
	if Entity:IsNextBot() then return true end
	if Entity:IsPlayer() then return true end

	return Entity:IsNPC()
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

	local Disposition = Entity:IsNPC() and ValidRelations[Relation]

	if Disposition then
		for Bot in pairs(self.Members) do
			Entity:AddEntityRelationship(Bot, Disposition, 99)
		end
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

hook.Add("CAI_GetEntityRelation", "Test", function(Squadron, Entity)
	if Entity:IsPlayer() then return "Foe" end
	if not Entity.Squadron then return end

	return Entity.Squadron == Squadron and "Friend" or "Foe"
end)
