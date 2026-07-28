AddCSLuaFile()

SWEP.Author			= "NECROSSIN"

SWEP.ViewModel			= Model ( "models/weapons/c_arms_cstrike.mdl" )
SWEP.WorldModel			= Model("models/MaxOfS2D/camera.mdl")

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.Slot				= 0
SWEP.SlotPos			= 0

local switchsound = Sound( "buttons/lightswitch2.wav" )
local batterysound = Sound( "ambient/energy/zap6.wav" )

SWEP.MaxBattery = 100
SWEP.BatteryDrain = 1
SWEP.BatteryRecharge = 0.1

function SWEP:Initialize()

	self:SetWeaponHoldType( "camera" )
	
	if CLIENT then
		self.Zoom = 0
	end
	
	self.NextHeal = 0

end

SWEP.nextswitch = 0
function SWEP:PrimaryAttack()
	if self.nextswitch >= CurTime() then return end
	self.nextswitch = CurTime() + 0.1
	
	
	if CLIENT then 
		self.Owner:EmitSound( switchsound )
	else
		self:Switch( !self:GetSwitch() )
	end
	
	
	//sound.Play( switchsound, self.Owner:GetShootPos() )
	
end

function SWEP:Deploy()
	
	
end

function SWEP:SecondaryAttack()

end

function SWEP:Switch( bl )
	self:SetDTBool(0,bl)
end

function SWEP:GetSwitch()
	return self:GetDTBool(0)
end

function SWEP:SetBattery( am )
	if IsValid(self.Owner) then
		local maxOver = GetGlobalInt("slender_battery_limit", 100) * (GetGlobalInt("slender_battery_overcharge", 150) / 100)
		self.Owner:SetDTInt(1, math.Clamp(am, 0, math.Round(maxOver)))
	end
end

function SWEP:GetBattery()
	if IsValid(self.Owner) then
		return self.Owner:GetDTInt(1)
	end
	return 0
end

SWEP.NextHeal = 0
SWEP.NextDrain = 0
SWEP.NextRecharge = 0
function SWEP:Think()
	if GetGlobalBool("slender_round_paused", false) then return end

	local ct = CurTime()
	
	if SERVER then
		local ply = self.Owner
		if IsValid(ply) and ply:Health() < 100 then
			local canRegen = GetGlobalBool("slender_sanity_regen", true)
			
			if canRegen and GetGlobalBool("slender_sanity_regen_far", true) then
				if not ply.NextRegen or ply.NextRegen > ct then
					canRegen = false
				end
			end
			
			if canRegen and GetGlobalBool("slender_sanity_regen_light", true) then
				if not self:GetSwitch() or self:GetBattery() <= 0 then
					canRegen = false
				end
			end
			
			if canRegen then
				if self.NextHeal and self.NextHeal <= ct then
					ply:SetHealth(math.Clamp(ply:Health() + 1, 0, 100))
					self.NextHeal = ct + 0.5 + (0.03 * ply:GetPages())
				end
			end
		end
		local batLimit = GetGlobalInt("slender_battery_limit", 100)
		local batDrain = GetGlobalFloat("slender_battery_drain", 1.0)
		local batRecharge = GetGlobalFloat("slender_battery_recharge", 0.1)
		local batLockout = GetGlobalInt("slender_battery_lockout", 6)

		if self:GetBattery() > 0 and self:GetSwitch() then
			if self.NextDrain <= ct then
				self:SetBattery( self:GetBattery() - 1 )
				self.NextDrain = ct + batDrain
				if self:GetBattery() == 0 then
					self:Switch( false )
					self.nextswitch = ct + batLockout
					self.Owner:SendLua("surface.PlaySound(\"ambient/energy/zap6.wav\")")
					self.Owner:SendLua("surface.PlaySound(\"ambient/energy/zap6.wav\")")
				end
			end
		else
			if self.NextRecharge <= ct and self:GetBattery() < batLimit then
				self:SetBattery( self:GetBattery() + 1 )
				self.NextRecharge = ct + batRecharge
			end
		end
	end

end

if CLIENT then 
local current = 0
function SWEP:TranslateFOV( current_fov )
	
	current = math.Approach(current,self.Zoom,FrameTime()*10)
	
	return self.Owner:GetFOV() - (current or 0)

end

local vecfake = Vector(0, 0, 16000)
function SWEP:DrawHUD()//DrawHUD
	
	
	local light = Entity(0):GetDTEntity(0)
	local light_small = Entity(0):GetDTEntity(1)
	
	if light and IsValid(light) and light_small and IsValid(light_small) then
		
		local todraw = self:GetSwitch() and not self.Owner:KeyDown(IN_ATTACK2)
		
		if todraw then
			
			if light:IsEffectActive( EF_NODRAW ) then
				light:SetNoDraw(false)
			end
			
			local pos = EyePos()+EyeAngles():Right()*14+EyeAngles():Forward()*5
			
			light:SetPos(pos)
			light:SetAngles(((self.Owner:GetEyeTrace().HitPos - EyePos()):GetNormal()):Angle())
			
		else
			if not light:IsEffectActive( EF_NODRAW ) then
				light:SetNoDraw(true)
			end
			light:SetPos(vecfake)
		end
		
		local todraw2 = self:GetSwitch() and self.Owner:KeyDown(IN_ATTACK2)
		
		if todraw2 then
			
			if light_small:IsEffectActive( EF_NODRAW ) then
				light_small:SetNoDraw(false)
			end
			
			//light_small:SetOwner(LocalPlayer())
			
			local pos = EyePos()+EyeAngles():Right()*14+EyeAngles():Forward()*5
			
			light_small:SetPos(pos)
			light_small:SetAngles(((self.Owner:GetEyeTrace().HitPos - EyePos()):GetNormal()):Angle())
			
		else
			if not light_small:IsEffectActive( EF_NODRAW ) then
				light_small:SetNoDraw(true)
			end
			light_small:SetPos(vecfake)
		end
	
	end	
end

function SWEP:DrawWorldModel()
	if LocalPlayer() ~= self.Owner then
		self:DrawModel()
	end
end


end