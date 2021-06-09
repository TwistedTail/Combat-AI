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

-- Materials
Globals.Materials = {
	[MAT_CONCRETE] = 1,
	[MAT_DIRT]     = 1.15,
	[MAT_GRATE]    = 1.05,
	[MAT_SNOW]     = 1.2,
	[MAT_PLASTIC]  = 1.05,
	[MAT_METAL]    = 1,
	[MAT_SAND]     = 1.2,
	[MAT_FOLIAGE]  = 1.15,
	[MAT_SLOSH]    = 1.2,
	[MAT_TILE]     = 1,
	[MAT_GRASS]    = 1.1,
	[MAT_VENT]     = 1.05,
	[MAT_WOOD]     = 1.05,
	[MAT_GLASS]    = 1.1,
}

if CLIENT then return end

-- Initializing the human grid
CNode.AddGrid("human", Vector(35, 35, 75))
