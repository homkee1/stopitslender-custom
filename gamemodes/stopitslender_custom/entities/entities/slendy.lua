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
		self:SetCustomCollisionCheck( true )
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

-- Автоматическое освобождение администратора при удалении/уничтожении бота
function ENT:OnRemove()
	if SERVER then
		if IsValid(self.Possessor) then
			local ply = self.Possessor
			self.Possessor = nil
			ply:SetNWBool("PossessingBot", false)
			ply:SetNWEntity("PossessedBot", NULL)
			ply:SetNWAngle("PossessOrigAng", angle_zero)
			ply:SetMoveType(ply:Team() == TEAM_SPECTATOR and MOVETYPE_OBSERVER or MOVETYPE_WALK)
		end
	end
end


function ENT:Think()
	if GetGlobalBool("slender_round_paused", false) then
		if SERVER then
			self:SetLocalVelocity(vector_origin)
		end
		self:NextThink(CurTime() + 0.1)
		return true
	end

	local ct = CurTime()
	
	if SERVER then
		-- Считываем динамические дистанции из админ-панели
		self.StuckDistance = GetGlobalInt("slender_bot_stuck_dist", 60)
		self.AttackDistance = GetGlobalInt("slender_bot_attack_dist", 650)
		self.DamageDistance = GetGlobalInt("slender_bot_damage_dist", 650)

		-- ПРЯМОЕ УПРАВЛЕНИЕ БОТОМ (Possession) (Игровой баланс и механика 1 в 1 как у реального Слендера)
		if IsValid(self.Possessor) then
			local ply = self.Possessor
			
			-- Расчет векторов передвижения относительно взгляда администратора
			local forward = ply:EyeAngles():Forward()
			forward.z = 0
			forward:Normalize()
			
			local right = ply:EyeAngles():Right()
			right.z = 0
			right:Normalize()
			
			local moveVec = Vector(0, 0, 0)
			if ply:KeyDown(IN_FORWARD) then moveVec = moveVec + forward end
			if ply:KeyDown(IN_BACK) then moveVec = moveVec - forward end
			if ply:KeyDown(IN_MOVERIGHT) then moveVec = moveVec + right end
			if ply:KeyDown(IN_MOVELEFT) then moveVec = moveVec - right end
			
			-- Реализация баланса скорости передвижения Слендера 1 в 1:
			-- Если бот в инвизе, скорость 260. Если видим, скорость 114.
			-- Если Слендера увидел хотя бы один выживший, его скорость падает до 0 (Замораживается)
			local speed = 260
			local isCloaked = self:GetNWBool("SlenderCloaked", false)
			if not isCloaked then
				speed = 114
				if self:Seen(nil, -0.5, true) then
					speed = 0 -- Слендер замирает при взгляде на него
				end
			end

			if speed > 0 and moveVec:LengthSqr() > 0 then
				moveVec:Normalize()
				self:SetPos(self:GetPos() + moveVec * speed * FrameTime())
				
				-- Воспроизведение анимации ходьбы
				if self:GetSequence() ~= self:LookupSequence("walk_all_moderate") then
					self:SetSequence(self:LookupSequence("walk_all_moderate"))
				end
			else
				-- Анимация покоя при остановке или заморозке взгляда
				if self:GetSequence() ~= self:LookupSequence("idle_subtle") then
					self:SetSequence(self:LookupSequence("idle_subtle"))
				end
			end
			
			-- Плавный поворот бота в сторону взгляда администратора (блокируется при полной заморозке взгляда)
			if speed > 0 or not isCloaked then
				self:SetAngles(Angle(0, ply:EyeAngles().y, 0))
			end
			
			-- Обработка ЛКМ (Принудительный ТЕЛЕПОРТ за спину выжившему 1 в 1 как у реального Слендера, разблокируется при сборе 4 записок)
			if ply:KeyDown(IN_ATTACK) then
				self.NextTeleportCooldown = self.NextTeleportCooldown or 0
				if self.NextTeleportCooldown < ct then
					if not self:Seen() and not isCloaked and game.GetWorld():GetDTInt(1) >= 4 then
						local teleportPos, facingPos = self:CheckTeleportPos()
						if teleportPos and facingPos then
							self:SetPos(teleportPos)
							local dir = (facingPos - self:GetPos()):GetNormal()
							local ang = dir:Angle()
							self:SetAngles(Angle(0, ang.y, 0))
							ply:SetEyeAngles(Angle(0, ang.y, 0)) -- Разворачиваем камеру админа на выжившего
							self:EmitSound("camera_static/single_big1.wav", 100, 100) -- Проигрываем тяжелые помехи
							self.NextTeleportCooldown = ct + 10 -- Перезарядка ТП 10 секунд
						end
					end
				end
			end

			-- Обработка ПКМ (Переключение скрытности бота с оригинальным звуком npc/fast_zombie/wake1.wav 1 в 1 как у реального Слендера)
			if ply:KeyDown(IN_ATTACK2) then
				self.NextPossessInvis = self.NextPossessInvis or 0
				if self.NextPossessInvis < ct then
					if not self:Seen() then
						local nextInvis = not isCloaked
						self:SetNWBool("SlenderCloaked", nextInvis)
						self:SetNoDraw(nextInvis)
						self:DrawShadow(not nextInvis)
						self:EmitSound("npc/fast_zombie/wake1.wav", 35, 120) -- Оригинальный не зацикливающийся звук перехода
						self.NextPossessInvis = ct + 0.8
					end
				end
			end

			self.NextAttack = self.NextAttack or ct + 0.5 -- Исправлена опечатка двоеточия на точку
			if self.NextAttack < ct then
				self:Attack() -- Пассивно наносим урон глазами (Слендер-видение)
				self.NextAttack = ct + 0.1
			end

			self:NextThink(ct)
			return true
		end

		-- ПРОВЕРКА НА ЗАМОРОЗКУ ИИ АДМИНИСТРАТОРОМ
		local isFrozen = self:GetNWBool("SlenderAIFrozen", false)
		if not isFrozen then
			-- Пока нет записок, боты подвержены гравитации и падают вниз
			if not FIRST_PAGE then
				if self:GetMoveType() ~= MOVETYPE_FLYGRAVITY then
					self:SetMoveType( MOVETYPE_FLYGRAVITY )
				end
			else
				if self:GetMoveType() ~= MOVETYPE_STEP then
					self:SetMoveType( MOVETYPE_STEP )
					self:SetLocalVelocity( vector_origin ) -- сбрасываем скорость падения при переходе в режим телепортов
				end
			end

			local botFreq = GetGlobalFloat("slender_bot_teleport_freq", 1.35)
			self.NextTeleport = self.NextTeleport or ct + botFreq
			
			if self.NextTeleport < ct then
				self:Teleport()
				self.NextTeleport = ct + botFreq
				self:SetSequence( self:LookupSequence("idle_subtle") )
				self:SetCycle(0)
			end
			
			self.NextAttack = self.NextAttack or ct + 0.5
			
			if self.NextAttack < ct then
				self:Attack()
				self.NextAttack = ct + 0.1
			end
		else
			-- Сбрасываем скорость, если ИИ заморожен администратором
			self:SetLocalVelocity(vector_origin)
			if self:GetSequence() ~= self:LookupSequence("idle_subtle") then
				self:SetSequence(self:LookupSequence("idle_subtle"))
			end
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
	
	local botStep = GetGlobalInt("slender_bot_teleport_step", 90)
	local final = cur + dir * ( distance>=1100 and botStep*6 or math.min(botStep,nicedistance))
	
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

function ENT:Seen(newpos, newdot, checkvisibility)
	local clear = true
	local cur = self:GetPos()

	for k, v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
		if IsValid(v) and v:Alive() and (v:GetPos():Distance(cur) <= self.AttackDistance and v:SyncAngles():Forward():Dot((v:GetPos()-cur):GetNormal()) < (newdot or -0.3) and TrueVisible(v:EyePos(), (newpos and newpos + vector_up*64) or self:NearestPoint(v:EyePos()), v) or self:GetNWBool("SlenderCloaked", false) and v:GetPos():Distance(cur) < self.StuckDistance) then
			clear = false
			break
		end
	end
	return not clear
end

function ENT:CheckTeleportPos()
	if self:Seen() then return end
	if self:GetNWBool("SlenderCloaked", false) then return end
	
	local target = self:GetClosest()
	
	if IsValid(target) then
		-- Локальное объявление таблицы tracebox для устранения ошибок компиляции
		local tracebox = {
			start = target:GetPos() + vector_up * 2,
			endpos = target:GetPos() + vector_up * 2 + target:SyncAngles():Forward() * 900,
			mins = Vector(-20, -20, 0),
			maxs = Vector(20, 20, 80),
			filter = target,
			mask = MASK_SHOT
		}
		
		local tr = util.TraceHull( tracebox )
		
		if not tr.Hit and not self:Seen( tracebox.endpos ) and TrueVisible(target:EyePos(), tracebox.endpos + vector_up * 64, target) then
			return tracebox.endpos, tracebox.start
		end
	end
	return 
end

function ENT:GetClosest()
	-- Если администратор принудительно зафиксировал цель ИИ
	if IsValid(self.TargetLock) and self.TargetLock:IsPlayer() and self.TargetLock:Alive() and self.TargetLock:Team() == TEAM_HUMENS then
		return self.TargetLock
	end

	local Closest = 999999999
	local dist = 0
	local Ent = nil
		for k, v in ipairs(team.GetPlayers(TEAM_HUMENS)) do
			dist = v:GetPos():Distance( self:GetPos() )
				if( dist < Closest) then
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