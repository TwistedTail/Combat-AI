-- Global variables
local Globals = CAI.Globals

-- File paths
Globals.BasePath = "combat-ai/"
Globals.MapPath  = Globals.BasePath .. "%s/"
Globals.FilePath = Globals.MapPath .. "/%s.json"

-- Node settings
Globals.MaxHeight = 75
Globals.MaxCrouch = 37
Globals.MaxWidth  = 35
Globals.MaxJump   = 20
Globals.MaxSlope  = math.cos(math.rad(45)) -- Can't climb slopes steeper than 45°

-- Squad settings
Globals.SquadSize = 10

if CLIENT then return end

CAI.Bots = CAI.Bots or {} -- Temp

local CNode = CNode
local Bots  = CAI.Bots

-- Initializing the human grid
CNode.AddGrid("human", Vector(35, 35, 75))

hook.Add("Tick", "CAI Pathfinding Result", function()
	local Paths = CNode.GetPaths()

	if not Paths then return end

	for Name, Path in pairs(Paths) do
		for Bot in pairs(Bots) do
			Bot:PushPath(Path)
		end

		Paths[Name] = nil
	end
end)
