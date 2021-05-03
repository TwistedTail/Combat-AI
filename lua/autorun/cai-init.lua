local File = "cai-loader.lua"

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
