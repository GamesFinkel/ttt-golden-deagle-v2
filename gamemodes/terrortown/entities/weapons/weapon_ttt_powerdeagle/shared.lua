--[[Author informations]]--
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

-- team fixes "Alf21"
-- contact "http://steamcommunity.com/profiles/76561198049831089"

local defaultClipSize = CreateConVar("ttt_golden_deagle_bullets", 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Amount of bullets you receive, when you buy a Golden Deagle.", 1)
local clipSize = CreateConVar("ttt_golden_deagle_max_bullets", 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum magazine size of the Golden Deagle.", 1)

if SERVER then
	AddCSLuaFile()

	-- Target kill modes
	-- 0: Kill when shot player is in the traitor team
	-- 1: Kill when shot player is an opponent
	-- 2: Kill when shot player is a traitor or an opponent
	CreateConVar("ttt_golden_deagle_kill_mode", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "When should the Golden Deagle kill the target?", 0, 2)

	-- Shooter suicide modes
	-- 0: Suicide when shot player is in the innocent team
	-- 1: Suicide when shot player is in same team
	-- 2: Suicide when shot player is not a traitor
	CreateConVar("ttt_golden_deagle_suicide_mode", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "When should the Golden Deagle suicide the shooter?", 0, 2)
else
	LANG.AddToLanguage("english", "golden_deagle_name", "Golden Deagle")
	LANG.AddToLanguage("english", "golden_deagle_desc", "Shoot a traitor, kill a traitor.\nShoot an innocent or detective, kill yourself.\nBe careful.")

	LANG.AddToLanguage("Deutsch", "golden_deagle_name", "Goldene Deagle")
	LANG.AddToLanguage("Deutsch", "golden_deagle_desc", "Schieße auf einen Spieler eines anderen Teams, um ihn direkt zu töten.\nSchieße auf deine Mates, um dich selbst zu töten.\nSei vorsichtig!")
	
    LANG.AddToLanguage("Русский", "golden_deagle_name", "Золотой Deagle")
	LANG.AddToLanguage("Русский", "golden_deagle_desc", "Стреляйте в предателя, убивайте предателя.\nСтреляйте в невиновного или детектива, убивайте себя.\nБудьте осторожны.")

	SWEP.PrintName = "golden_deagle_name"
	SWEP.Slot = 6
	SWEP.Icon = "vgui/ttt/icon_powerdeagle"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = true -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 72

	-- Equipment menu information is only needed on the client
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "golden_deagle_desc"
	}

	hook.Add("TTT2ScoreboardAddPlayerRow", "ZaratusasTTTMod", function(ply)
		local ID64 = ply:SteamID64()

		if (ID64 == "76561198032479768") then
			AddTTT2AddonDev(ID64)
		end
	end)
end

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.6
SWEP.Primary.Recoil = 6
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 37
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = defaultClipSize:GetInt()
SWEP.Primary.ClipSize = clipSize:GetInt()
SWEP.Primary.Sound = Sound("Golden_Deagle.Single")

--[[Model settings]]--
SWEP.HoldType = "pistol"
SWEP.ViewModel = Model("models/weapons/zaratusa/powerdeagle/v_powerdeagle.mdl")
SWEP.WorldModel = Model("models/weapons/zaratusa/powerdeagle/w_powerdeagle.mdl")

SWEP.IronSightsPos = Vector(1.1, 0.6, 0.7)
SWEP.IronSightsAng = Vector(0, 0, 75)

--[[TTT config values]]--

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP1

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2,
-- then this gun can be spawned as a random weapon.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "none"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_DETECTIVE }

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = false

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = false

-- support for TTT Custom Roles

local function IsInInnocentTeam(ply)
	local inno_roles = GetTeamRoles(INNOCENT_ROLES)
	for _, role in ipairs(inno_roles) do
		if(ply:GetRole()==role) then
			return true
		end
	end
	return false
end

-- Precache sounds
function SWEP:Precache()
	util.PrecacheSound("Golden_Deagle.Single")
end

function SWEP:Initialize()
	if (CLIENT and self:Clip1() == -1) then
		self:SetClip1(self.Primary.DefaultClip)
	elseif (SERVER) then
		self.shotsFired = 0
		self.fingerprints = {}
		self:SetIronsights(false)
	end

	self:SetDeploySpeed(self.DeploySpeed)

	if (self.SetHoldType) then
		self:SetHoldType(self.HoldType or "pistol")
	end

	PrecacheParticleSystem("smoke_trail")
end

function SWEP:PrimaryAttack()
	if (self:CanPrimaryAttack()) then
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

		local owner = self:GetOwner()
		owner:GetViewModel():StopParticles()

		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		if SERVER then
			sound.Play(self.Primary.Sound, self:GetPos())
			self.shotsFired = self.shotsFired + 1

			local title = "HandleGoldenDeagle" .. self:EntIndex() .. self.shotsFired

			hook.Add("EntityTakeDamage", title, function(ent, dmginfo)
				if (IsValid(ent) and ent:IsPlayer() and dmginfo:IsBulletDamage() and dmginfo:GetAttacker():GetActiveWeapon() == self) then
					if (IsInInnocentTeam(ent)==false) then
						hook.Remove("EntityTakeDamage", title) -- remove hook before applying new damage
						dmginfo:ScaleDamage(270) -- deals 9990 damage
						return false -- one hit the traitor
					else
						local newdmg = DamageInfo()
						newdmg:SetDamage(9990)
						newdmg:SetAttacker(owner)
						newdmg:SetInflictor(self)
						newdmg:SetDamageType(DMG_BULLET)
						newdmg:SetDamagePosition(owner:GetPos())

						hook.Remove("EntityTakeDamage", title) -- remove hook before applying new damage
						owner:TakeDamageInfo(newdmg)

						return true -- block all damage on the target
					end
				end
			end)

			timer.Simple(1, function() hook.Remove("EntityTakeDamage", title) end) -- wait 1 seconds for the damage
		end

		self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
		self:TakePrimaryAmmo(1)

		if (IsValid(owner) and not owner:IsNPC() and owner.ViewPunch) then
			owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) * self.Primary.Recoil, 0))
		end

		timer.Simple(0.5, function()
			if (IsValid(self) and IsValid(self:GetOwner())) then
				ParticleEffectAttach("smoke_trail", PATTACH_POINT_FOLLOW, self:GetOwner():GetViewModel(), 1)
			end
		end)
	end
end

function SWEP:Holster()
	if (IsValid(self:GetOwner())) then
		local vm = self:GetOwner():GetViewModel()
		if (IsValid(vm)) then
			vm:StopParticles()
		end
	end

	return true
end
