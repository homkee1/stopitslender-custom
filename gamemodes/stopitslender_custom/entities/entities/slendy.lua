if SERVER then
	AddCSLuaFile()
	
	resource.AddFile("materials/filmgrain.vmt")
	resource.AddFile("materials/filmgrain.vtf")
end

ENT.Base = "base_anim" 
ENT.Type = "anim"
 
ENT.PrintName		= "Slenderman"
ENT.Author			= "NECROSSIN"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Category		= "Other"

ENT.Spawnable = true
ENT.AdminOnly = true

//ENT.TeleportStep = 190
//ENT.TeleportFrequency = 0.5

ENT.StuckDistance = 60
ENT.AttackDistance = 650
ENT.DamageDistance = 650

util.PrecacheModel("models/slenderman/slenderman.mdl")

function ENT:Initialize()

	if SERVER then
		self:SetModel( "models/slenderman/slenderman.mdl" )
		self:SetSolid( SOLID_BBOX ) 
		self:SetMoveType( MOVETYPE_STEP )
		self:SetSequence( self:LookupSequence("idle_subtle") )
		//self:DropToFloor()
		
		for k, v in pairs( GAMEMODE.SlenderBoneMods ) do
			local bone = self:LookupBone(k)
			if (!bone) then continue end
			self:ManipulateBoneScale( bone, v.scale  )
			self:ManipulateBoneAngles( bone, v.angle  )
			self:ManipulateBonePosition( bone, v.pos  )
		end
	end
	
	if CLIENT then
		self:SetIK( false )
	end
	
end


function ENT:Think()

	local ct = CurTime()
	
	if SERVER then
		
		self.NextTeleport = self.NextTeleport or ct + SLENDER_TELEPORT_FREQUENCY
		
		if self.NextTeleport < ct then
			
			self:Teleport()
			
			self.NextTeleport = ct + SLENDER_TELEPORT_FREQUENCY
			
			self:SetSequence( self:LookupSequence("idle_subtle") )
			self:SetCycle(0)
		end
		
		self.NextAttack = self.NextAttack or ct + 0.5
		
		if self.NextAttack < ct then
			
			self:Attack()
			
			self.NextAttack = ct + 0.0005
		end
	
	end
	
	self:NextThink(CurTime())
end

if CLIENT then
	
	function ENT:Draw()
		self:DrawModel()
		
		if EyePos():Distance(self:GetPos()) >= 600 then return end
		
		local bone = self:GetAttachment(self:LookupAttachment("eyes"))//self.Owner:LookupBone("ValveBiped.Bip01_Head1")
		if bone then
			local pos,ang = bone.Pos, bone.Ang//self.Owner:GetBonePosition(bone)
			if pos and ang then
				local dlight = DynamicLight( self:EntIndex() )
				if ( dlight ) then
					dlight.Pos = pos+self:GetAngles():Forward() *13//+ang:Forward()*3
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

if SERVER then
function ENT:SpawnFunction( pl, tr )

	if !IsValid(pl) then return end
		
	local ent = ents.Create( self.ClassName )
	ent:SetPos(tr.HitPos)
	ent:Spawn()
	ent:Activate()
	 
	return ent
end

function ENT:Attack()

	local cur = self:GetPos()

	for k,v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		
		if IsValid(v) and v:Alive() and (v:GetPos():Distance(cur) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-cur):GetNormal()) < -0.3 and TrueVisible(v:EyePos(),self:NearestPoint(v:EyePos()),v) or v:GetPos():Distance(cur) <= self.StuckDistance+3) then
			v:SetHealth(math.Clamp(v:Health()-math.Clamp(3*((self.DamageDistance-v:GetPos():Distance(cur))/self.DamageDistance),0,3),0,100))
			v:BreakBattery(math.Clamp(3*((self.DamageDistance-v:GetPos():Distance(cur))/self.DamageDistance),0,3))
			v.NextRegen = CurTime() + 3
			if v:Health() <= 0 and (v.NextDeath or 0) <= CurTime() then
				v.NextDeath = CurTime() + 10
				v:Freeze(true)
				v:SendLua("ShowCloseup()")
				timer.Simple(3, function() 
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

local ground = {}
function ENT:Teleport()
	
	if not FIRST_PAGE then return end
	
	local target = self:GetClosest()
	
	if !IsValid(target) then return end
	
	local distance = target:GetPos():Distance(self:GetPos())
	local nicedistance = distance - self.StuckDistance
	
	if distance <= self.StuckDistance then return end
	
	local clear = true
	
	local dest = target:GetPos()+vector_up*2
	local cur = self:GetPos()
	
	
	
	
	for k,v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		
		if IsValid(v) and v:Alive() and v:GetPos():Distance(cur) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-cur):GetNormal()) < -0.3 and TrueVisible(v:EyePos(),cur+vector_up*50,v) then
			clear = false
			break
		end
	end
	
	if not clear then return end
	
	//self:SetColor(Color(255,255,255,0))
	//self:SetRenderMode(RENDERMODE_TRANSALPHA)
	
	local dir = (dest-cur):GetNormal()
	
	ground.start = cur+vector_up*72
	ground.endpos = ground.start-vector_up*1200
	ground.filter = self
	
	local tr = util.TraceLine( ground )
	
	local final = cur + dir * ( distance>=1100 and SLENDER_TELEPORT_STEP*6 or math.min(SLENDER_TELEPORT_STEP,nicedistance))
	
	if distance <= 800 and math.random(20) == 1 and clear and target:SyncAngles():Forward():Dot((target:GetPos()-cur):GetNormal()) > -0.3 then
		final = target:GetPos()+vector_up*4+target:SyncAngles():Forward()*700
	end
	
	local drop = false
	
	if tr.Hit and tr.HitWorld and !tr.HitNoDraw and final.z- dest.z <= 72 then
		final.z = tr.HitPos.z
		drop = true
		//self:DropToFloor()
	end
	
	if math.abs(dest.z - final.z) >= 200 and distance <= 630 then
		final.z = dest.z + 2
		drop = math.random(10) == 1 
		//self:DropToFloor()
	end
	
	for k,v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		
		if IsValid(v) and v:Alive() and v:GetPos():Distance(final) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-final):GetNormal()) < -0.3 and TrueVisible(v:EyePos(),final+vector_up*50) then
			clear = false
			break
		end
	end
	
	if not clear then 
		if distance <= 800 and target:SyncAngles():Forward():Dot((target:GetPos()-cur):GetNormal()) < -0.3 and !TrueVisible(target:EyePos(),cur+vector_up*50,target) and math.random(10) == 1 then
			final = target:GetPos()+vector_up*4-target:SyncAngles():Forward()*600
		else
			return
		end
	end

	self:SetPos(final)
	
	dir = (target:GetPos()-self:GetPos()):GetNormal()
	local ang = dir:Angle()
	self:SetAngles(Angle(0,ang.y,ang.r))
	
	//if drop then self:DropToFloor() end
	
	//PrintTable(tr)
	
	//self:SetColor(Color(255,255,255,255))

end

end

function ENT:GetClosest()
	local Closest = 0
	local dist = 0
	local Ent = nil
		for k, v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
			dist = v:GetPages()//v:GetPos():Distance( self.Entity:GetPos() )
				if( dist >= Closest) then
					if v:IsPlayer() and v:Alive() then
						Closest = dist
						Ent = v
						if math.random(10) == 1 then
							break
						end
					end
				end
		end
	return Ent
end

local meta = FindMetaTable( "Player" )
if (!meta) then return end

function meta:SyncAngles()
	local ang = self:EyeAngles()
	ang.pitch = 0
	ang.roll = 0
	return ang
end