AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/player/riot.mdl")

	self.Enemies = {}
	self.Allies  = {}
end

