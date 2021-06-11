local CAI      = CAI
local Weaponry = CAI.Weaponry
local Objects  = Weaponry.Objects

function Weaponry.Register(Name)
	if not isstring(Name) then return end

	local Data = {
		Class = Name
	}

	Objects[Name] = Data

	return Data
end

function Weaponry.Get(Name)
	if not isstring(Name) then return end

	return Objects[Name]
end

function Weaponry.Give(Name, Bot)
	if not isstring(Name) then return end
	if not IsValid(Bot) then return end
	if not Bot.IsCAIBot then return end

	local Base = Objects[Name]

	if not Base then return end

	local Object = {}

	setmetatable(Object, { __index = Base, })

	Object:Initialize()
	Object:CreateProp(Bot)

	return Object
end

function Weaponry.Remove(Name)
	if not isstring(Name) then return end

	Objects[Name] = Data
end
