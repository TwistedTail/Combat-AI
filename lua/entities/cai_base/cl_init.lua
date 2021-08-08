
include("shared.lua")

ENT.PrintName = "Combat AI NextBot"
ENT.Author    = "TwistedTail"
ENT.Contact   = "https://steamcommunity.com/id/TwistedTail/"
ENT.Purpose   = "Provide a combat-focused bot base"

function ENT:Initialize()
	self.EyesIndex = self:LookupAttachment("eyes")
end

function ENT:Think()
	local Eyes = self:GetAttachment(self.EyesIndex)

	self.Position = self:GetPos()
	self.ShootPos = Eyes.Pos
	self.ShootDir = Eyes.Ang:Forward()
end
