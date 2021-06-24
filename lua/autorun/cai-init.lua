local File = "cai-loader.lua"

-- Creating global table and namespaces
if not CAI then
	CAI = {
		Detection  = { Entities = {} },
		Globals    = {},
		Networking = { Sender = {}, Receiver = {}, },
		Nodes      = {},
		Paths      = { Requests = {}, },
		Squadrons  = { Objects = {}, },
		Utilities  = {},
		Weaponry   = { Objects = {}, }
	}
end

if SERVER then
	hook.Add("dotnet_loaded", "CAI/CNode loading", function()
		if dotnet then
			dotnet.load("CombatNode")

			AddCSLuaFile(File)
			include(File)
		else
			print("ERROR: GmodDotNet is not installed, CAI will not be loaded.")
		end

		hook.Remove("dotnet_loaded", "CAI/CNode loading")
	end)
else
	AddCSLuaFile(File)
	include(File)
end
