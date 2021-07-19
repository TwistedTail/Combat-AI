local Meta = CAI.Squadrons.GetMeta()

function Meta:OnGainedSight(Entity, Data)
	print(self, "OnGainedSight", Entity, Data)
end

function Meta:OnLostSight(Entity, Data)
	print(self, "OnLostSight", Entity, Data)
end
