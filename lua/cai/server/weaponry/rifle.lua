local CAI      = CAI
local Utils    = CAI.Utilities
local Weaponry = CAI.Weaponry
local WEAPON   = Weaponry.Register("rifle")

WEAPON.Model      = "models/weapons/w_rif_famas.mdl"
WEAPON.FireSound  = "weapons/ump45/ump45-1.wav"
WEAPON.FireRate   = 600 -- shots per minute
WEAPON.Spread     = 0.01
WEAPON.ReloadTime = 4
WEAPON.HoldType   = "ar2"

function WEAPON:Initialize()
	self.FireDelay = 1 / (self.FireRate / 60)
	self.Ammo      = 30
	self.MagSize   = 30

	self.Bullet = {
		Attacker   = true,
		Damage     = 20,
		Force      = 5,
		Tracer     = 5,
		TracerName = "LaserTracer",
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
	local Muzzle     = Prop:LookupAttachment("muzzle")

	Prop:SetPos(Attachment.Pos)
	Prop:SetParent(Owner, AttachID)
	Prop:AddEffects(EF_BONEMERGE)
	Prop:Spawn()

	self.Muzzle = Prop:WorldToLocal(Prop:GetAttachment(Muzzle).Pos)
	self.Prop   = Prop

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

	self.Prop:EmitSound(self.FireSound, SNDLVL_GUNFIRE, 100, 1, CHAN_WEAPON)

	self:MuzzleFlash(Source, Bullet.Dir)

	self.Ammo      = self.Ammo - 1
	self.Cycling   = true
	self.NextCycle = Utils.CurTime + self.FireDelay

	if self.Ammo == 0 then
		self:Reload()
	end

	return true
end

function WEAPON:MuzzleFlash(Position, Direction)
	local Angle = Direction:Angle()
	local Effect = EffectData()
		Effect:SetOrigin(Position + Direction * 5)
		Effect:SetAngles(Angle)
		Effect:SetScale(1)

	util.Effect("MuzzleEffect", Effect)
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
	local Prop = self.Prop

	if IsValid(Prop) then
		Prop:Remove()
	end

	self.Prop = nil
end
