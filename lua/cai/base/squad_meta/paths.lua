local Meta    = CAI.Squadrons.GetMeta()
local Paths   = CAI.Paths
local NoBrain = GetConVar("ai_disabled")

function Meta:RequestPath(Goal, UseLocked, Type)
	if NoBrain:GetBool() then return end
	if not isvector(Goal) then return end
	if not IsValid(self.Leader) then return end

	local Leader = self.Leader

	if not Paths.Request(self, Leader.GridName, Leader.Position, Goal, UseLocked) then
		return print(self, "Couldn't request path")
	end

	if not Type then return end

	for Member in pairs(self.Members) do
		local Data = Member.Paths[Type]

		if Data and Data.OnRequest then
			Data.OnRequest(Member, Goal, UseLocked)
		end
	end
end

function Meta:ReceivePath(Path)
	if NoBrain:GetBool() then return end

	for Member in pairs(self.Members) do
		Member:ReceivePath(Path, "Route")
	end
end
