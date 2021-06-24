include("shared.lua")

ENT.PrintName = "Combat AI View Trigger"
ENT.Author    = "TwistedTail"
ENT.Contact   = "https://steamcommunity.com/id/TwistedTail/"
ENT.Purpose   = "Allow CAI NextBots to see and detect enemies"

local CAI    = CAI
local Utils  = CAI.Utilities
local Box    = Color(255, 0, 0)
local Sphere = Color(0, 255, 0)
local Angles = Angle()

function ENT:Initialize()
	self.Position = self:GetPos()

	self:UpdateRadius()
end

function ENT:UpdateRadius()
	local Radius = self:GetNWFloat("Radius")

	if Radius <= 0 then return end

	self.Radius = Radius
	self.Size   = Vector(Radius, Radius, Radius)

	self:SetRenderBounds(-self.Size, self.Size)
end

function ENT:Draw()
	if not self.Radius then return self:UpdateRadius() end

	render.DrawWireframeBox(self.Position, Angles, -self.Size, self.Size, Box, true)
	render.DrawWireframeSphere(self.Position, self.Radius, 30, 30, Sphere, true)
end

function ENT:Think()
	self.Position = self:GetPos()

	self:NextThink(Utils.CurTime)

	return true
end
