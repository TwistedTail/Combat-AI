local CNode    = CNode
local Paths    = CAI.Paths
local Utils    = CAI.Utilities
local Requests = Paths.Requests
local Format   = "%s-%s"

function Paths.Request(Requester, Grid, Start, Goal, UseLocked, Type)
	if not IsValid(Requester) then return end
	if not isstring(Grid) then return end
	if not isvector(Start) then return end
	if not isvector(Goal) then return end

	local Name = string.format(Format, Requester.UID, Type or "Unknown")
	local UID = Utils.GetUID(Name)

	if not CNode.QueuePath(Grid, UID, Start, Goal, UseLocked) then
		return print("Couldn't request path.")
	end

	Requests[UID] = {
		Requester = Requester,
		Type = Type
	}

	return true
end

hook.Add("Tick", "CAI Pathfinding Result", function()
	local Results = CNode.GetPaths()

	if not Results then return end

	for UID, Path in pairs(Results) do
		local Data = Requests[UID]

		if not Data then print("no data for path", UID) continue end

		local Requester = Data.Requester

		if IsValid(Requester) then
			Requester:ReceivePath(Path, Data.Type)
		end

		Requests[UID] = nil
	end
end)
