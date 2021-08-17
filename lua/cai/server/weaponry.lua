local CAI      = CAI
local Weaponry = CAI.Weaponry
local Weapons  = Weaponry.Weapons
local Objects  = Weaponry.Objects

local function Think()
	for Weapon in pairs(Objects) do
		Weapon:Think()
	end
end

function Weaponry.Register(Name)
	if not isstring(Name) then return end

	local Data = {
		Class = Name
	}

	Weapons[Name] = Data

	return Data
end

function Weaponry.Get(Name)
	if not isstring(Name) then return end

	return Weapons[Name]
end

function Weaponry.Give(Name, Bot)
	if not isstring(Name) then return end
	if not IsValid(Bot) then return end
	if not Bot.IsCAIBot then return end

	local Base = Weapons[Name]

	if not Base then return end

	local Object = {}

	setmetatable(Object, { __index = Base, })

	Object:Initialize()
	Object:CreateProp(Bot)

	if not next(Objects) then
		hook.Add("Think", "CAI Weapon Think", Think)
	end

	Objects[Object] = true

	return Object
end

function Weaponry.Remove(Object)
	if not istable(Object) then return end

	Objects[Object] = nil

	if not next(Objects) then
		hook.Remove("Think", "CAI Weapon Think")
	end
end
