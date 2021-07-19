local Squads = CAI.Squadrons
local Meta   = Squads.GetMeta()
local format = string.format
local Name   = "CAI Squadron %s"

function Meta:IsValid()
	return not self.Disbanded
end

function Meta:ToString()
	return format(Name, self.UID)
end

Meta.__tostring = Meta.ToString

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

function Meta:Think()
	if not IsValid(self.View) then return end

	self.View:UpdatePos()
end

function Meta:Disband()
	if self.Disbanded then return end

	self.Disbanded = true

	local View = self.View

	if IsValid(View) then
		View:Remove()
	end

	for Member in pairs(self.Members) do
		self:RemoveMember(Member)
	end

	for Entity in pairs(self.Relations.Entities) do
		self:ForgetRelation(Entity)
	end

	Squads.Remove(self.Name)
end
