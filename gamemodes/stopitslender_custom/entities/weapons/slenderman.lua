AddCSLuaFile()

SWEP.Author			= "NECROSSIN"

SWEP.ViewModel			= Model ("models/weapons/c_arms_cstrike.mdl" )
SWEP.WorldModel			= Model("models/MaxOfS2D/camera.mdl")

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Slot				= 0
SWEP.SlotPos			= 0

SWEP.StuckDistance = 60
SWEP.AttackDistance = 650
SWEP.DamageDistance = 645

local team = team
local CurTime = CurTime
local ipairs = ipairs
local math = math
local Vector = Vector
local util = util
local ents = ents

function SWEP:Think()

	local ct = CurTime()

	if self.Owner:GetVelocity():Length() > 1 and self:GetInvisMode() then
		if not self:Seen() then
			self.Owner:SetRenderMode(RENDERMODE_NONE)
			if self:IsVisible() then
				self:MakeVisible( false )
			end
		end
		//self.Owner:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	else
			if not self:Seen() then
				self.Owner:SetRenderMode(RENDERMODE_NORMAL)
				//self.Owner:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				
				if !self:IsVisible() then
					self:MakeVisible( true )
				end
			end
			
			if SERVER then
				self.NextAttack = self.NextAttack or ct + 0.5
				
				if self.NextAttack < ct then
					
					self:Attack()
					
					self.NextAttack = ct + 0.1
				end
			end
		//end
	end
	
	self:NextThink(ct)

end

function SWEP:Move(mv)
	if !self:GetInvisMode() then
		mv:SetMaxSpeed( 114 )
	end
	
	if self:Seen( nil, -0.5, true) and self:IsVisible() then
		mv:SetMaxSpeed( 0 )
	end
	
	if self:IsVisible() then
		mv:SetUpSpeed( 1 )
	end
	
end

function SWEP:MakeVisible( bl )
	self:SetDTBool(0,bl)
	if self.Owner then
		self.Owner:CollisionRulesChanged()
	end
end

function SWEP:IsVisible()
	return self:GetDTBool(0)
end

function SWEP:SetInvisMode( bl )
	self:SetDTBool(1,bl)
	if self.Owner then
		self.Owner:CollisionRulesChanged()
	end
end

function SWEP:GetInvisMode()
	return self:GetDTBool(1)
end

function SWEP:Attack()

	local cur = self.Owner:GetPos()

	for k,v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		
		if IsValid(v) and self:IsVisible() and v:Alive() and (v:GetPos():Distance(cur) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-cur):GetNormal()) < -0.3 and TrueVisible(v:EyePos(),self.Owner:NearestPoint(v:EyePos()),v) or v:GetPos():Distance(cur) <= self.StuckDistance+3) then
			v:SetHealth(math.Clamp(v:Health()-math.Clamp(3*((self.DamageDistance-v:GetPos():Distance(cur))/self.DamageDistance),0,3),0,100))
			v:BreakBattery(math.Clamp(3*((self.DamageDistance-v:GetPos():Distance(cur))/self.DamageDistance),0,3))
			v.NextRegen = CurTime() + 3
			if v:Health() <= 0 and (v.NextDeath or 0) <= CurTime() then
				v.NextDeath = CurTime() + 10
				v:Freeze(true)
				v:SendLua("ShowCloseup()")
				timer.Simple(5.5, function() 
					if IsValid(v) then
						if CurTime() - ROUNDTIME >= 10 then
							v:Kill()
						end
					end
				end)
			end
		end
	end

end

function SWEP:Seen( newpos, newdot, checkvisibility )
	
	local clear = true
	local cur = self.Owner:GetPos()

	for k,v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		if IsValid(v) and v:Alive() and (v:GetPos():Distance(cur) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-cur):GetNormal()) < (newdot or -0.3) and TrueVisible(v:EyePos(),(newpos and newpos +vector_up*64)	or self.Owner:NearestPoint(v:EyePos()),v) or self:GetInvisMode() and v:GetPos():Distance(cur) < self.StuckDistance) then
			clear = false
			break
		end
	end
	
	return !clear
	
end

local nextswitch1 = 0
local tracebox = {mask = MASK_SHOT}

function SWEP:CheckTeleportPos()
	
	if self:Seen() then return end
	if !self:IsVisible() then return end
	
	local target = self:GetClosest()
	
	if IsValid(target) then
		tracebox.start = target:GetPos()+vector_up*2
		tracebox.endpos = target:GetPos() +vector_up*2 + target:SyncAngles():Forward()*900
		tracebox.mins = Vector(-20,-20,0)
		tracebox.maxs = Vector(20,20,80)
		tracebox.filter = target
		
		local tr = util.TraceHull( tracebox )
		
		if !tr.Hit and !self:Seen( tracebox.endpos ) and TrueVisible(target:EyePos(),tracebox.endpos+vector_up*64,v) then
			return tracebox.endpos, tracebox.start
		end
		
	end
	
	return 
	
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	if nextswitch1 >= CurTime() then return end
	if self:Seen() then return end
	if !self:IsVisible() then return end
	if game.GetWorld():GetDTInt( 1 ) < 4 then return end
	nextswitch = CurTime() + 0.1
	
	local to, targetpos = self:CheckTeleportPos()
	
	if to and targetpos then	
		self.Owner:SetPos(to)
		local dir = (targetpos-self.Owner:GetPos()):GetNormal()
		local ang = dir:Angle()
		self.Owner:SetEyeAngles(Angle(0,ang.y,ang.r))	
		nextswitch = CurTime() + 10
	end
end

function SWEP:GetClosest()
	local Closest = 999999999999999999
	local dist = 0
	local Ent = nil
		for k, v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
			dist = v:GetPos():Distance( self.Owner:GetPos() )
				if( dist < Closest) then
					if v:IsPlayer() and v:Alive() then
						Closest = dist
						Ent = v
						if math.random(20) == 1 then
							break
						end
					end
				end
		end
	return Ent
end

local switchsound = Sound( "npc/fast_zombie/wake1.wav" )

local nextswitch = 0
function SWEP:SecondaryAttack()
	if nextswitch >= CurTime() then return end
	if self:Seen() then return end
	nextswitch = CurTime() + 0.1
	

	if CLIENT then 
		self.Owner:EmitSound( switchsound, 35,120 )
	else
		self:SetInvisMode( !self:GetInvisMode() )
		if not self.Owner:OnGround() then
			self.Owner:SetLocalVelocity(vector_origin)
		end
	end
end


if CLIENT then

function SWEP:FreezeMovement()
	return self:Seen(nil, -0.5, true) and self:IsVisible()
end

function SWEP:DrawHUD()
	//if GAMEMODE:IsNight() then
		local light = Entity(0):GetDTEntity(3)
		
		if light and IsValid(light) then
			light:SetOwner(LocalPlayer())
			light:SetPos(EyePos())
			light:SetAngles(EyeAngles())
		end
	//else
	/*	local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			dlight.Pos = EyePos()+EyeAngles():Forward()*30
			dlight.r = 255
			dlight.g = 55
			dlight.b = 55
			dlight.Brightness = 3
			dlight.Size = 570
			dlight.Decay = 570 * 5
			dlight.DieTime = CurTime() + 1
			dlight.Style = 0
		end*/
	//end
	
	for k,v in pairs(team.GetPlayers(TEAM_HUMENS)) do
		local pos = v:GetShootPos():ToScreen()
		draw.SimpleText(v:GetPages().."/"..v:GetMaxPages(), "Tahoma_lines23",pos.x, pos.y, Color(215,215,215,250), TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	end
	
	local visible = self:IsVisible()
	local seen = self:Seen() and visible
	
	draw.SimpleText(seen and "Someone sees you!" or "Noone sees you", "Tahoma_lines30",50, ScrH()-170, seen and Color(15,215,15,100) or Color(215,15,15,100), TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	draw.SimpleText("X", "Tahoma_lines130",50, ScrH()-100, visible and Color(15,215,15,100) or Color(215,15,15,100), TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	
	draw.SimpleText((self:Seen() and "(Blocked) " or "").."RMB - Toggle invisibility", "Tahoma_lines30",ScrW()-50, ScrH()-170, !self:GetInvisMode() and Color(15,215,15,100) or Color(215,15,15,100), TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	if Entity(0):GetDTInt( 1 ) < 4 then return end
	draw.SimpleText((self:CheckTeleportPos() and "" or "(Blocked) ").."LMB - Teleport to nearby player", "Tahoma_lines30",ScrW()-50, ScrH()-90, self:CheckTeleportPos() and Color(15,215,15,100) or Color(215,15,15,100), TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	
end

function SWEP:DrawWorldModel()
	if EyePos():Distance(self.Owner:GetPos()) >= 600 then return end
	if !self:IsVisible() then return end
		
		local bone = self.Owner:GetAttachment(self.Owner:LookupAttachment("eyes"))//self.Owner:LookupBone("ValveBiped.Bip01_Head1")
		if bone then
			local pos,ang = bone.Pos, bone.Ang//self.Owner:GetBonePosition(bone)
			if pos and ang then
				local dlight = DynamicLight( self.Owner:EntIndex() )
				if ( dlight ) then
					dlight.Pos = pos+self.Owner:GetAngles():Forward() * 13//+ang:Forward()*3
					dlight.r = 255
					dlight.g = 255
					dlight.b = 255
					dlight.Brightness = 5
					dlight.Size = 40
					dlight.Decay = 40 * 5
					dlight.DieTime = CurTime() + 1
					dlight.Style = 0
				end
			end
		end
end
end