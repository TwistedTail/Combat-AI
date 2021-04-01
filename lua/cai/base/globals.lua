-- Global variables
local Globals = CAI.Globals

-- File paths
Globals.BasePath = "combat-ai/"
Globals.NodePath = Globals.BasePath .. "maps/"

-- Subnode settings
Globals.MaxHeight   = 75
Globals.MaxCrouch   = 37
Globals.MaxWidth    = 35
Globals.MaxJump     = 20
Globals.MaxSlope    = math.cos(math.rad(45)) -- Can't climb slopes steeper than 45°
Globals.SubnodeSize = Vector(Globals.MaxWidth, Globals.MaxWidth, Globals.MaxHeight)
Globals.MaxDistance = 2500 ^ 2

-- Node settings
Globals.NodeGrid = Vector(25, 25, 1) -- Subnodes per axis per node
Globals.NodeSize = Globals.NodeGrid * Globals.SubnodeSize
