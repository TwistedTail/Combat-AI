local ToJSON   = util.TableToJSON
local ToTable  = util.JSONToTable
local Network  = CAI.Networking
local Sender   = Network.Sender
local Receiver = Network.Receiver
local Messages = {}
local IsQueued

function Network.CreateSender(Name, Function)
	if not isstring(Name) then return end
	if not isfunction(Function) then return end

	Sender[Name] = Function
end

function Network.RemoveSender(Name)
	if not isstring(Name) then return end

	Sender[Name] = nil
end

function Network.CreateReceiver(Name, Function)
	if not isstring(Name) then return end
	if not isfunction(Function) then return end

	Receiver[Name] = Function
end

function Network.RemoveReceiver(Name)
	if not isstring(Name) then return end

	Receiver[Name] = nil
end

if SERVER then
	util.AddNetworkString("CAI_Networking")

	local function PrepareQueue(Target, Name)
		if not Messages[Target] then
			Messages[Target] = {
				[Name] = {}
			}
		elseif not Messages[Target][Name] then
			Messages[Target][Name] = {}
		end

		return Messages[Target][Name]
	end

	-- NOTE: Consider the overflow size
	local function SendMessages()
		local All = Messages.All

		if All and next(All) then
			net.Start("CAI_Networking")
				net.WriteString(ToJSON(All))
			net.Broadcast()

			Messages.All = nil
		end

		if next(Messages) then
			for Target, Data in pairs(Messages) do
				net.Start("CAI_Networking")
					net.WriteString(ToJSON(Data))
				net.Send(Target)

				Messages[Target] = nil
			end
		end

		IsQueued = nil
	end

	function Network.Broadcast(Name, ...)
		if not Name then return end
		if not Sender[Name] then return end

		local Handler = Sender[Name]
		local Queue   = PrepareQueue("All", Name)

		Handler(Queue, ...)

		if not IsQueued then
			IsQueued = true

			timer.Simple(0, SendMessages)
		end
	end

	function Network.Send(Name, Player, ...)
		if not Name then return end
		if not Sender[Name] then return end
		if not IsValid(Player) then return end

		local Handler = Sender[Name]
		local Queue   = PrepareQueue(Player, Name)

		Handler(Queue, ...)

		if not IsQueued then
			IsQueued = true

			timer.Simple(0, SendMessages)
		end
	end

	net.Receive("CAI_Networking", function(_, Player)
		local Message = ToTable(net.ReadString())

		for Name, Data in pairs(Message) do
			local Handler = Receiver[Name]

			if Handler then
				Handler(Player, Data)
			end
		end
	end)
else
	local function PrepareQueue(Name)
		if not Messages[Name] then
			Messages[Name] = {}
		end

		return Messages[Name]
	end

	-- NOTE: Consider the overflow size
	local function SendMessages()
		if next(Messages) then
			net.Start("CAI_Networking")
				net.WriteString(ToJSON(Messages))
			net.SendToServer()

			for K in pairs(Messages) do
				Messages[K] = nil
			end
		end

		IsQueued = nil
	end

	function Network.Send(Name, ...)
		if not Name then return end
		if not Sender[Name] then return end

		local Handler = Sender[Name]
		local Queue   = PrepareQueue(Name)

		Handler(Queue, ...)

		if not IsQueued then
			IsQueued = true

			timer.Simple(0, SendMessages)
		end
	end

	net.Receive("CAI_Networking", function()
		local Message = ToTable(net.ReadString())

		for Name, Data in pairs(Message) do
			local Handler = Receiver[Name]

			if Handler then
				Handler(Data)
			end
		end
	end)
end