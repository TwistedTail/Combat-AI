-- Global variables
local Globals = CAI.Globals

-- File paths
Globals.BasePath = "combat-ai/"
Globals.NodePath = Globals.BasePath .. "maps/"

-- Grid settings
Globals.MaxHeight = 75
Globals.MaxCrouch = 37
Globals.MaxWidth  = 35
Globals.MaxJump   = 20
Globals.GridSize  = Vector(Globals.MaxWidth, Globals.MaxWidth, Globals.MaxHeight)

-- Node settings
Globals.GridsPerNode = Vector(10, 10, 1)
Globals.NodeSize     = Globals.GridsPerNode * Globals.GridSize
