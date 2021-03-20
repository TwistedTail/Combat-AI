-- Map nodes

if not CAI.Nodes then CAI.Nodes = {} end

local Nodes     = CAI.Nodes
local KeyFormat = "%i %i %i"

Nodes.Lookup = Nodes.Lookup or {} -- All the node objects will go here
Nodes.Areas  = Nodes.Areas or {} -- All the node area tables will go here

local Lookup = Nodes.Lookup

local function GetKey(X, Y, Z)
	if not isnumber(X) then return end
	if not isnumber(Y) then return end
	if not isnumber(Z) then return end

	return KeyFormat:format(X, Y, Z)
end

-- TODO: Replace table with node entity
-- TODO: Create new node area if needed
-- TODO: Save in area as local coords
function Nodes:Create(X, Y, Z)
	local Key = GetKey(X, Y, Z)

	if not Key then return end

	Lookup[Key] = { X = X, Y = Y, Z = Z }
end

function Nodes:Get(X, Y, Z)
	local Key = GetKey(X, Y, Z)

	if not Key then return end

	return Lookup[Key]
end

-- TODO: Remove node entity aswell
-- TODO: Remove related node area if empty
function Nodes:Remove(X, Y, Z)
	local Key = GetKey(X, Y, Z)

	if not Key then return end

	Lookup[Key] = nil
end

-- NOTE: What would be the reason for this to exist?
function Nodes:GetAll()
	local Result = {}

	for K, V in pairs(Lookup) do
		Result[K] = V
	end

	return Result
end

-- NOTE: Maybe return in global coords instead of local?
function Nodes:GetNodesFromArea(X, Y, Z)
	local Key = GetKey(X, Y, Z)

	if not Key then return end

	local Area   = Areas[Key]
	local Result = {}

	if Area then
		for K, V in pairs(Area) do
			Result[K] = V
		end
	end

	return Result
end
