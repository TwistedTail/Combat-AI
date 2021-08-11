local CAI       = CAI
local Detection = CAI.Detection
local Entities  = Detection.Entities

function Detection.GetEntities()
	local Result = {}

	for Entity in pairs(Entities) do
		Result[Entity] = true
	end

	return Result
end

function Detection.GetEntityList()
	local Result = {}
	local Count  = 0

	for Entity in pairs(Entities) do
		Count = Count + 1

		Result[Count] = Entity
	end

	return Result
end

function Detection.IsDetectable(Entity)
	if not IsValid(Entity) then return false end

	return Entities[Entity] or false
end

do -- Entry updating
	local function Add(Entity)
		if Entities[Entity] then return end

		Entities[Entity] = true

		hook.Run("CAI_OnAddDetectable", Entity)
	end

	local function Remove(Entity)
		if not Entities[Entity] then return end

		Entities[Entity] = nil

		hook.Run("CAI_OnRemoveDetectable", Entity)
	end

	-- Player hooks
	hook.Add("PlayerSpawn", "CAI Player Detection", Add)
	hook.Add("PlayerSpawnAsSpectator", "CAI Player Detection", Remove)
	hook.Add("PlayerDeath", "CAI Player Detection", Remove)
	hook.Add("PlayerDisconnected", "CAI Player Detection", Remove)

	-- NPC/NextBot hooks
	hook.Add("PlayerSpawnedNPC", "CAI Bot Detection", function(_, Entity)
		Add(Entity)
	end)
	hook.Add("OnNPCKilled", "CAI Bot Detection", Remove)
	hook.Add("EntityRemoved", "CAI Bot Detection", Remove)
end
