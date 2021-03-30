include("shared.lua")

ENT.PrintName    = "Combat AI Node"
ENT.Author       = "TwistedTail"
ENT.Contact      = "No"
ENT.Purpose      = "Reinvent the wheel"
ENT.Instructions = "Create via CAI.Nodes.Create(), then set all the relevant fields."

local Globals  = CAI.Globals
local HalfSize = Globals.NodeSize * 0.495 -- Slightly smaller for display purposes
local Nodes    = CAI.Nodes
local BoxAngle = Angle()
local BoxColor = Color(255, 255, 0)

function ENT:Initialize()
	self.Position = Nodes.RoundPosition(self:GetPos())

	self:SetRenderBounds(-HalfSize, HalfSize)
end

function ENT:Draw()
	self:DrawModel()

	render.DrawWireframeBox(self.Position, BoxAngle, -HalfSize, HalfSize, BoxColor, true)
end
