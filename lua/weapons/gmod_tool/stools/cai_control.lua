local CAI     = CAI
local CNode   = CNode
local Network = CAI.Networking

TOOL.Name = "#tool.cai_control.name"
TOOL.Category = "Combat AI"

function TOOL:LeftClick(Trace)
	if CLIENT then return true end

	local Owner = self:GetOwner()
	local Ent   = Trace.Entity

	if not (Trace.HitNonWorld and Ent.IsCAIBot) then
		if self.Selected then
			self.Selected = nil

			Network.Send("CAI Clear Halos", Owner)
		end

		return false
	end

	if self.LastHit == Ent then
		self.Selected = Ent
	else
		self.Selected = Ent.Squadron
	end

	self.GridName = Ent.GridName
	self.LastHit  = Ent

	Network.Send("CAI Set Halos", Owner, self.Selected)

	return true
end

function TOOL:RightClick(Trace)
	if CLIENT then return true end
	if not self.Selected then return false end

	local HitPos = Trace.HitPos

	if not CNode.HasGrid(self.GridName, HitPos) then return false end

	self.Selected:RequestPath(HitPos, "Full")

	return true
end

if CLIENT then
	language.Add("tool.cai_control.name", "Bot Controller")
	language.Add("tool.cai_control.desc", "Manually control CAI Bots.")

	local HaloColor = Color(255, 255, 0)
	local Selected  = {}
	local List      = {}

	local function ClearSelected()
		for Ent in pairs(Selected) do
			Selected[Ent] = nil

			Ent:RemoveCallOnRemove("CAI Halo")
		end
	end

	local function UpdateList()
		local Index = 0

		for I = #List, 1, -1 do
			List[I] = nil
		end

		for Ent in pairs(Selected) do
			Index = Index + 1

			List[Index] = Ent
		end
	end

	Network.CreateReceiver("CAI Clear Halos", function()
		ClearSelected()
		UpdateList()
	end)

	Network.CreateReceiver("CAI Set Halos", function(Data)
		ClearSelected()

		for Index in pairs(Data) do
			local Ent = Entity(Index)

			Selected[Ent] = true

			Ent:CallOnRemove("CAI Halo", function()
				Selected[Ent] = nil

				UpdateList()
			end)
		end

		UpdateList()
	end)

	hook.Add("PreDrawHalos", "CAI Halo", function()
		halo.Add(List, HaloColor, 1, 1)
	end)
else
	Network.CreateSender("CAI Clear Halos", function() end)

	Network.CreateSender("CAI Set Halos", function(Queue, Object)
		if Object.IsSquadron then
			for Member in pairs(Object:GetMembers()) do
				Queue[Member:EntIndex()] = true
			end
		else
			Queue[Object:EntIndex()] = true
		end
	end)
end
