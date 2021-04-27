-- Global variables
local Globals = CAI.Globals

-- File paths
Globals.BasePath = "combat-ai/"
Globals.NodePath = Globals.BasePath .. "maps/"

-- Node settings
Globals.MaxHeight = 75
Globals.MaxCrouch = 37
Globals.MaxWidth  = 35
Globals.MaxJump   = 20
Globals.MaxSlope  = math.cos(math.rad(45)) -- Can't climb slopes steeper than 45°

if CLIENT then return end

-- Initializing the human grid
CNode.AddGrid("human", Vector(35, 35, 75))
