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
