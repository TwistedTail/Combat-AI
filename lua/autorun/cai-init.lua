local File = "cai-loader.lua"

hook.Add("Initialize", "CAI/CNode loading", function()
	if dotnet then
		dotnet.load("CombatNode")

		AddCSLuaFile(File)
		include(File)
	else
		print("ERROR: GmodDotNet is not installed, CAI will not be loaded.")
	end

	hook.Remove("Initialize", "CAI/CNode loading")
end)
