local CAI      = CAI
local Utils    = CAI.Utilities
local Weaponry = CAI.Weaponry
local WEAPON   = Weaponry.Register("rifle")

WEAPON.Model      = "models/weapons/w_rif_famas.mdl"
WEAPON.FireSound  = "weapons/famas/famas-1.wav"
WEAPON.FireRate   = 600 -- shots per minute
WEAPON.Spread     = 0.01
WEAPON.ReloadTime = 4

WEAPON.Sequences = {
	idle_calm = {
		"Idle_Relaxed_AR2_1",
		"Idle_Relaxed_AR2_2",
		"Idle_Relaxed_AR2_3",
		"Idle_Relaxed_AR2_4",
		"Idle_Relaxed_AR2_5",
		"Idle_Relaxed_AR2_6",
		"Idle_Relaxed_AR2_7",
		"Idle_Relaxed_AR2_8",
		"Idle_Relaxed_AR2_9"
	},
	idle_alert = {
		"Idle_Alert_AR2_1",
		"Idle_Alert_AR2_2",
		"Idle_Alert_AR2_3",
		"Idle_Alert_AR2_4",
		"Idle_Alert_AR2_5",
		"Idle_Alert_AR2_6",
		"Idle_Alert_AR2_7",
		"Idle_Alert_AR2_8",
		"Idle_Alert_AR2_9"
	},
	idle_combat     = "idle_angry_Ar2",
	idle_crouch     = "Crouch_idleD",
	walk_calm       = "walk_AR2_Relaxed_all",
	walk_alert      = "walkHOLDALL1_ar2",
	walk_combat     = "walkAlertHOLD_AR2_ALL1",
	walk_crouch     = "Crouch_walk_holding_all",
	run_calm        = "run_AR2_Relaxed_all",
	run_alert       = "run_holding_ar2_all",
	run_combat      = "run_alert_holding_ar2_all",
	run_crouch      = "crouchRUNHOLDINGALL1",
	aim_idle        = "idle_ar2_aim",
	aim_walk        = "walkAIMALL1_ar2",
	aim_run         = "run_aiming_ar2_all",
	aim_idle_crouch = "crouch_aim_smg1",
	aim_walk_crouch = "Crouch_walk_aiming_all",
	aim_run_crouch  = "crouchRUNAIMINGALL1",
}

function WEAPON:Initialize()
	self.FireDelay = 1 / (self.FireRate / 60)
	self.Ammo      = 30
	self.MagSize   = 30

	self.Bullet = {
		Attacker   = true,
		Damage     = 20,
		Force      = 5,
		Tracer     = 1,
		TracerName = "Tracer",
		Spread     = Vector(self.Spread, self.Spread),
		Dir        = true,
		Src        = true,
	}
end

function WEAPON:GetOwner()
	return self.Prop:GetOwner()
end

function WEAPON:CreateProp(Owner)
	local Prop = ents.Create("base_anim")

	if not IsValid(Prop) then return end

	Prop:SetModel(self.Model)
	Prop:SetSolid(SOLID_NONE)
	Prop:SetOwner(Owner)

	local AttachID   = Owner:LookupAttachment("anim_attachment_RH")
	local Attachment = Owner:GetAttachment(AttachID)

	Prop:SetPos(Attachment.Pos)
	Prop:SetParent(Owner, AttachID)
	Prop:AddEffects(EF_BONEMERGE)
	Prop:Spawn()

	local Muzzle = Prop:LookupAttachment("muzzle")

	self.Prop   = Prop
	self.Muzzle = Prop:WorldToLocal(Prop:GetAttachment(Muzzle).Pos)

	return Prop
end

function WEAPON:CanShoot()
	if self.Reloading then return false end
	if self.Cycling then return false end

	return self.Ammo > 0
end

function WEAPON:GetMuzzlePos()
	return self.Prop:LocalToWorld(self.Muzzle)
end

function WEAPON:Shoot(Position)
	if not self:CanShoot() then return false end

	local Bullet = self.Bullet
	local Owner  = self:GetOwner()
	local Source = self:GetMuzzlePos()

	Bullet.Attacker = Owner
	Bullet.Src      = Source
	Bullet.Dir      = (Position - Source):GetNormalized()


	Owner:FireBullets(Bullet)

	self.Ammo      = self.Ammo - 1
	self.Cycling   = true
	self.NextCycle = Utils.CurTime + self.FireDelay

	if self.Ammo == 0 then
		self:Reload()
	end

	return true
end

function WEAPON:Reload()
	if self.Reloading then return false end

	self.Reloading = true
	self.EndReload = Utils.CurTime + self.ReloadTime

	return true
end

function WEAPON:Think()
	local Now = Utils.CurTime

	if self.Cycling and self.NextCycle < Now then
		self.Cycling   = nil
		self.NextCycle = nil
	end

	if self.Reloading and self.EndReload < Now then
		self.Ammo      = self.MagSize
		self.Reloading = nil
		self.EndReload = nil
	end
end

function WEAPON:Remove()
	self.Prop:Remove()
	self.Prop = nil
end
