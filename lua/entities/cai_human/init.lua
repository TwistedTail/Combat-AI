AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.MoveTypes = {
	Idle = { MaxSpeed = 0, Acceleration = 0 },
	Walk = { MaxSpeed = 200, Acceleration = 400 },
	Run  = { MaxSpeed = 400, Acceleration = 800 }
}

ENT.HoldTypes = {
	normal = {
		Calm = {
			Idle = {
				Normal = {
					"idle_subtle",
					"idle_angry",
					"LineIdle01",
					"LineIdle03",
				},
				Crouch = "Crouch_idleD", -- NOTE: Look for a better one.
			},
			Walk = {
				Normal = {
					"walk_all_Moderate",
					"walk_all",
				},
				Crouch = "Crouch_walk_all",
			},
			Run = {
				Normal = "run_all", -- NOTE: sprint_all was too exaggerated in my opinion
				Crouch = "CrouchRUNALL1",
			}
		}
	},
	ar2 = {
		Calm = {
			Idle = {
				Normal = { -- NOTE: For some reason, these are different for some people
					"Idle_Alert_AR2_1",
					"Idle_Alert_AR2_2",
					"Idle_Alert_AR2_3",
					"Idle_Alert_AR2_4",
					"Idle_Alert_AR2_5",
					"Idle_Alert_AR2_6",
					"Idle_Alert_AR2_7",
					"Idle_Alert_AR2_8",
					"Idle_Alert_AR2_9",
					"idle_angry_Ar2",
				},
				Crouch = "Crouch_idleD",
			},
			Walk = {
				Normal = {
					"walkHOLDALL1_ar2",
					"walkAlertHOLD_AR2_ALL1",
				},
				Crouch = "Crouch_walk_holding_all",
			},
			Run = {
				Normal = {
					"run_holding_ar2_all",
					"run_alert_holding_ar2_all",
				},
				Crouch = "crouchRUNHOLDINGALL1",
			}
		},
		Combat = {
			Idle = {
				Normal = "idle_ar2_aim",
				Crouch = "crouch_aim_smg1",
			},
			Walk = {
				Normal = "walkAIMALL1_ar2",
				Crouch = "Crouch_walk_aiming_all",
			},
			Run = {
				Normal = "run_aiming_ar2_all",
				Crouch = "crouchRUNAIMINGALL1",
			}
		}
	}
}

ENT.Sounds = {
	Idle = {
		"vo/npc/male01/question01.wav",
		"vo/npc/male01/question03.wav",
		"vo/npc/male01/question04.wav",
		"vo/npc/male01/question05.wav",
		"vo/npc/male01/question06.wav",
		"vo/npc/male01/question07.wav",
		"vo/npc/male01/question09.wav",
		"vo/npc/male01/question10.wav",
		"vo/npc/male01/question11.wav",
		"vo/npc/male01/question12.wav",
		"vo/npc/male01/question13.wav",
		"vo/npc/male01/question16.wav",
		"vo/npc/male01/question17.wav",
		"vo/npc/male01/question18.wav",
		"vo/npc/male01/question19.wav",
		"vo/npc/male01/question20.wav",
		"vo/npc/male01/question21.wav",
		"vo/npc/male01/question22.wav",
		"vo/npc/male01/question23.wav",
		"vo/npc/male01/question25.wav",
		"vo/npc/male01/question26.wav",
		"vo/npc/male01/question27.wav",
		"vo/npc/male01/question28.wav",
		"vo/npc/male01/question30.wav",
		"vo/npc/male01/question31.wav",
	},
	Alert = {
		"vo/npc/male01/getdown02.wav",
		"vo/npc/male01/headsup01.wav",
		"vo/npc/male01/headsup02.wav",
		"vo/npc/male01/incoming02.wav",
		"vo/npc/male01/overthere01.wav",
		"vo/npc/male01/overthere02.wav",
		"vo/npc/male01/heretheycome01.wav",
		"vo/npc/male01/upthere01.wav",
		"vo/npc/male01/upthere02.wav",
		"vo/npc/male01/watchout.wav",
	},
	Attack = {
		"vo/npc/male01/leadtheway01.wav",
		"vo/npc/male01/leadtheway02.wav",
		"vo/npc/male01/letsgo01.wav",
		"vo/npc/male01/letsgo02.wav",
		"vo/npc/male01/readywhenyouare01.wav",
		"vo/npc/male01/readywhenyouare02.wav",
	},
	Kill = {
		"vo/npc/male01/gotone01.wav",
		"vo/npc/male01/gotone02.wav",
		"vo/npc/male01/likethat.wav",
		"vo/npc/male01/nice.wav",
		"vo/npc/male01/yeah02.wav",
		"vo/npc/male01/yougotit02.wav",
	},
	Defense = {
		"vo/npc/male01/getgoingsoon.wav",
		"vo/npc/male01/holddownspot01.wav",
		"vo/npc/male01/holddownspot02.wav",
		"vo/npc/male01/illstayhere01.wav",
		"vo/npc/male01/imstickinghere01.wav",
		"vo/npc/male01/littlecorner01.wav",
		"vo/npc/male01/takecover02.wav",
	},
	Reload = {
		"vo/npc/male01/gottareload01.wav",
		"vo/npc/male01/coverwhilereload01.wav",
		"vo/npc/male01/coverwhilereload02.wav"
	},
	Pain = {
		"vo/npc/male01/hitingut01.wav",
		"vo/npc/male01/hitingut02.wav",
		"vo/npc/male01/imhurt01.wav",
		"vo/npc/male01/imhurt02.wav",
		"vo/npc/male01/ow01.wav",
		"vo/npc/male01/ow02.wav"
	},
	Death = {
		"vo/npc/male01/pain01.wav",
		"vo/npc/male01/pain02.wav",
		"vo/npc/male01/pain03.wav",
		"vo/npc/male01/pain04.wav",
		"vo/npc/male01/pain05.wav",
		"vo/npc/male01/pain06.wav",
		"vo/npc/male01/pain07.wav",
		"vo/npc/male01/pain08.wav",
		"vo/npc/male01/pain09.wav",
	}
}

ENT.Models = {
	"models/humans/group03/male_01.mdl",
	"models/humans/group03/male_02.mdl",
	"models/humans/group03/male_03.mdl",
	"models/humans/group03/male_04.mdl",
	"models/humans/group03/male_05.mdl",
	"models/humans/group03/male_06.mdl",
	"models/humans/group03/male_07.mdl",
	"models/humans/group03/male_08.mdl",
	"models/humans/group03/male_09.mdl"
}

function ENT:SetupModel()
	local Models = self.Models
	local Path   = Models[math.random(#Models)]

	self:SetModel(Path)
end

function ENT:OnInitialized()
	self:GiveWeapon(self.DefaultWeapon)
end

function ENT:OnRemoved(DamageInfo)
	local Weapon = self.Weapon

	if Weapon then
		Weapon:Remove()
	end

	if DamageInfo and self.OnFire then
		self:SetModel("models/player/charple.mdl")
	end
end

do -- Weaponry functions
	local Weaponry = CAI.Weaponry

	function ENT:GiveWeapon(Name)
		if not isstring(Name) then return end

		local Weapon = Weaponry.Give(Name, self)

		if not Weapon then return end

		self:SetHoldType(Weapon.HoldType)

		self.Weapon = Weapon

		return true
	end

	function ENT:Attack(Entity)
		if not self.Weapon then return end
		if not IsValid(Entity) then return end

		local Position = Entity:EyePos()

		self.loco:FaceTowards(Position)
		self.Weapon:Shoot(Position)
	end

	function ENT:AttackPos(Position)
		if not self.Weapon then return end
		if not isvector(Position) then return end

		self.loco:FaceTowards(Position)
		self.Weapon:Shoot(Position)
	end
end
