local Squads  = CAI.Squadrons
local Utils   = CAI.Utilities
local Objects = Squads.Objects
local Meta    = {}

Meta.__index = Meta

function Squads.GetMeta()
	return Meta
end

function Squads.Create(Name)
	if not isstring(Name) then return end
	if Objects[Name] then return end

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

hook.Add("Tick", "CAI Squadron Think", function()
	for _, Squad in pairs(Objects) do
		Squad:Think()
	end
end)
