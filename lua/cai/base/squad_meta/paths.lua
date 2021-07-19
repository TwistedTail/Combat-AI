local Meta = CAI.Squadrons.GetMeta()

function Meta:RequestPath(Goal, Type)
	for Member in pairs(self.Members) do
		Member:RequestPath(Goal, Type)
	end
end
