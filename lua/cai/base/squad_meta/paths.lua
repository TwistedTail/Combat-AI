local Meta    = CAI.Squadrons.GetMeta()
local Paths   = CAI.Paths
local NoBrain = GetConVar("ai_disabled")

function Meta:RequestPath(Goal, UseLocked)
	if NoBrain:GetBool() then return end
	if not isvector(Goal) then return end
	if not IsValid(self.Leader) then return end

	local Leader = self.Leader

	Paths.Request(self, Leader.GridName, Leader.Position, Goal, UseLocked)
end

function Meta:ReceivePath(Path)
	if NoBrain:GetBool() then return end

	for Member in pairs(self.Members) do
		Member:ReceivePath(Path, "Route")
	end
end
