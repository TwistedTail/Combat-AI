local Meta  = CAI.Squadrons.GetMeta()
local Paths = CAI.Paths

function Meta:RequestPath(Goal, UseLocked)
	if not isvector(Goal) then return end
	if not IsValid(self.Leader) then return end

	local Leader = self.Leader

	Paths.Request(self, Leader.GridName, Leader.Position, Goal, UseLocked)
end

function Meta:ReceivePath(Path)
	for Member in pairs(self.Members) do
		Member:ReceivePath(Path, "Route")
	end
end
