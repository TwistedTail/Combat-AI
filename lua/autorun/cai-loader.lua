-- Combat AI file loader
-- Never liked how the include + AddCSLuaFile mess looked like
-- So we'll just load anything inside the cai folder
-- Outright copied from ACF-3

print("\n===========[ Loading Combat AI ]============\n|")

if not CAI then CAI = {} end

if SERVER then
	local Text        = "| > Loaded %s serverside file(s).\n| > Loaded %s shared file(s).\n| > Loaded %s clientside file(s)."
	local Realms      = { client = "client", server = "server", shared = "shared" }
	local ServerCount = 0
	local SharedCount = 0
	local ClientCount = 0

	local function Load(Path, Realm)
		local Files, Directories = file.Find(Path .. "/*", "LUA")

		for _, File in ipairs(Files) do
			local Sub = string.sub(File, 1, 3)

			File = Path .. "/" .. File

			if Realm == "client" or Sub == "cl_" then
				AddCSLuaFile(File)

				ClientCount = ClientCount + 1
			elseif Realm == "server" or Sub == "sv_" then
				include(File)

				ServerCount = ServerCount + 1
			else -- Shared
				include(File)
				AddCSLuaFile(File)

				SharedCount = SharedCount + 1
			end
		end

		for _, Directory in ipairs(Directories) do
			local Sub = string.sub(Directory, 1, 6)

			Realm = Realms[Sub] or Realm or nil

			Load(Path .. "/" .. Directory, Realm)
		end
	end

	Load("cai")

	print(Text:format(ServerCount, SharedCount, ClientCount))
else
	local Text = "| > Loaded %s clientside file(s).\n| > Skipped %s clientside file(s)."
	local FileCount = 0
	local SkipCount = 0

	local function Load(Path)
		local Files, Directories = file.Find(Path .. "/*", "LUA")

		for _, File in ipairs(Files) do
			local Sub = string.sub(File, 1, 3)

			if Sub == "sk_" then
				SkipCount = SkipCount + 1
			else
				File = Path .. "/" .. File

				include(File)

				FileCount = FileCount + 1
			end
		end

		for _, Directory in ipairs(Directories) do
			Load(Path .. "/" .. Directory)
		end
	end

	Load("cai")

	print(Text:format(FileCount, SkipCount))
end

print("|\n=======[ Finished Loading Combat AI ]=======\n")
