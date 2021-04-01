include("shared.lua")

ENT.PrintName    = "Combat AI Node"
ENT.Author       = "TwistedTail"
ENT.Contact      = "No"
ENT.Purpose      = "Reinvent the wheel"
ENT.Instructions = "Create via CAI.Nodes.Create(), then set all the relevant fields."

local Globals  = CAI.Globals
local Network  = CAI.Networking
local Nodes    = CAI.Nodes
local Subnodes = CAI.Subnodes
local Utils    = CAI.Utilities
local Distance = Globals.MaxDistance
local HalfSize = Globals.NodeSize * 0.499 -- Slightly smaller for display purposes
local HalfNode = Globals.SubnodeSize * 0.47
local BoxAngle = Angle()
local BoxColor = Color(255, 255, 0)
local NodeColor = Color(0, 255, 0)
local GroundColor = Color(0, 255, 255)
local WaterColor  = Color(255, 0, 0)

function ENT:Initialize()
	self.Pos = Nodes.RoundPosition(self:GetPos())

	self:SetRenderBounds(-HalfSize, HalfSize)
end

function ENT:Draw()
	if Utils.EyePos:DistToSqr(self.Pos) > Distance then return end
	if not self.Subnodes then
		if not self.Queued then
			self.Queued = true

			Network.Send("NodeInfo", self)
		end

		return
	end

	render.DrawWireframeBox(self.Pos, BoxAngle, -HalfSize, HalfSize, BoxColor, true)

	for _, Node in pairs(self.Subnodes) do
		local PosColor = Node.Swim and WaterColor or GroundColor

		render.DrawWireframeSphere(Node.FeetPos, 5, 5, 5, PosColor, true)
		render.DrawWireframeBox(Node.Pos, BoxAngle, -HalfNode, HalfNode, NodeColor, true)
	end
end

Network.CreateSender("NodeInfo", function(Queue, Node)
	Queue[Node:EntIndex()] = true
end)

Network.CreateReceiver("NodeInfo", function(Message)
	for Index, Data in pairs(Message) do
		local Node = Entity(Index)

		if IsValid(Node) then
			local List = Data.Subnodes

			Node.Key      = Data.Key
			Node.Coords   = Data.Coords
			Node.Subnodes = {}
			Node.Queued   = nil

			for I = #List, 1, -1 do
				Subnodes.Create(Node, List[I]) -- NOTE: Would it be better for the client to not do this?
			end
		end

		Message[Index] = nil
	end
end)
