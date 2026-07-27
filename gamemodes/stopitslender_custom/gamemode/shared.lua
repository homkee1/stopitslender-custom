//Stop, it Slender! by NECROSSIN
//Originally made to mess around with some friends

include("obj_player_extend.lua")

if SERVER then
	AddCSLuaFile("sh_adminpanel.lua")
end
include("sh_adminpanel.lua")

//humens is on purpose
TEAM_HUMENS = 3
TEAM_SLENDER = 4

GM.Name 		= "Stop it Slender Custom"
GM.Author 		= "NECROSSIN"
GM.Version		= "03/12/2016"
GM.Email 		= ""
GM.Website 		= ""

team.SetUp(TEAM_HUMENS, "Humens", Color(0,121,250,192))
team.SetUp(TEAM_SLENDER, "Slenderman", Color(218,11,11,192))

function GM:GetGameDescription()
	return self.Name
end

//Supported maps in workshop version
GM.Maps = {
	[1] = {map = "slender_forest", votes = 0},
	[2] = {map = "ttt_slender_v2", votes = 0},
	[3] = {map = "zs_clav_segments_v2", votes = 0},
	[4] = {map = "zs_last_mansion_v3", votes = 0},
	[5] = {map = "slender_outland_v3", votes = 0},
	[6] = {map = "slender_janitor_fixed", votes = 0},
	[7] = {map = "slender_infirmary", votes = 0},
	[8] = {map = "de_school", votes = 0},
}

function TrueVisible(posa, posb, owner)
	local filt = owner or player.GetAll()
	return not util.TraceLine({start = posa, endpos = posb,mask = MASK_SHOT, filter = filt}).Hit
end

function GM:ShouldCollide( ent1, ent2 )
	local isSlender1 = (ent1:IsPlayer() and ent1:IsSlenderman()) or ent1:GetClass() == "slendy"
	local isSlender2 = (ent2:IsPlayer() and ent2:IsSlenderman()) or ent2:GetClass() == "slendy"

	if ent1:IsPlayer() and ent2:IsPlayer() then
		if ent1:IsSlenderman() and !ent1:IsSlenderVisible() and ent2:Team() == TEAM_HUMENS or ent2:IsSlenderman() and !ent2:IsSlenderVisible() and ent1:Team() == TEAM_HUMENS then
			return false
		end
	end
	if isSlender1 and (ent2:GetClass() == "prop_physics" or ent2:GetClass() == "prop_door_rotating") or
		isSlender2 and (ent1:GetClass() == "prop_physics" or ent1:GetClass() == "prop_door_rotating") then
		return false
	end
	return true
end

function GM:Move( pl, mv )		
	local wep = IsValid(pl:GetActiveWeapon()) and pl:GetActiveWeapon()
	if wep and wep.Move then
		wep:Move(mv)
	end
end

hook.Add("CalcMainActivity","Slenderman_Animations",function(pl,vel)
	if pl:IsSlenderman() then
		local iSeq, iIdeal = pl:LookupSequence ( "reference" )
		
		local fVel = vel:Length2D()
		
		local wep = IsValid(pl:GetActiveWeapon()) and pl:GetActiveWeapon()
		
		if wep and wep.IsVisible and wep:IsVisible() and fVel > 1 then
			iSeq = pl:LookupSequence ( "walk_all_moderate" )
		end
		
		return iIdeal, iSeq
	end	
end)

hook.Add("UpdateAnimation","Slenderman_UpdateAnimations",function(pl, velocity, maxseqgroundspeed)
	
	if pl:IsSlenderman() then
		if velocity:Length2D() < 1 then
			pl:SetCycle(0)
		else
			pl:SetPlaybackRate(0.7)
		end
		return true
	end

end)

hook.Add("PlayerFootstep","Slenderman_Footsteps", function( pl, pos, foot, sound, volume, rf ) 
	if pl:IsSlenderman() then
		 return true
	end
end)

function GM:PlayerStepSoundTime( ply, iType, bWalking )
	
	local fStepTime = 350
	local fMaxSpeed = ply:GetMaxSpeed()
	
	if ( iType == STEPSOUNDTIME_NORMAL || iType == STEPSOUNDTIME_WATER_FOOT ) then
		
		if ( fMaxSpeed <= 130 ) then 
			fStepTime = 370
		elseif ( fMaxSpeed <= 300 ) then 
			fStepTime = 350
		else 
			fStepTime = 250 
		end
	
	elseif ( iType == STEPSOUNDTIME_ON_LADDER ) then
	
		fStepTime = 450 
	
	elseif ( iType == STEPSOUNDTIME_WATER_KNEE ) then
	
		fStepTime = 600 
	
	end
	
	-- Step slower if crouching
	if ( ply:Crouching() ) then
		fStepTime = fStepTime + 50
	end
	
	return fStepTime
	
end

hook.Add("SetupMove", "Slender_Stamina", function(ply, mv, cmd)
	if ply:Team() != TEAM_HUMENS or not ply:Alive() then return end

	ply.Stamina = ply.Stamina or 100
	ply.ExhaustedTime = ply.ExhaustedTime or 0

	local isExhausted = ply.ExhaustedTime > CurTime()

	local isMoving = bit.band(mv:GetButtons(), IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT) != 0
	local isSprinting = mv:KeyDown(IN_SPEED) and isMoving and ply:OnGround() and not ply:Crouching()

	-- Отслеживание изменения рассудка за последние 10 секунд (День 3 - Скорость от паники)
	ply.NextSanityRecord = ply.NextSanityRecord or 0
	ply.SanityHistory = ply.SanityHistory or {}

	local ct = CurTime()
	if ply.NextSanityRecord < ct then
		table.insert(ply.SanityHistory, {time = ct, hp = ply:Health()})
		ply.NextSanityRecord = ct + 1

		-- Очищаем записи старше 10 секунд
		for i = #ply.SanityHistory, 1, -1 do
			if ply.SanityHistory[i].time < ct - 10 then
				table.remove(ply.SanityHistory, i)
			end
		end
	end

	-- Находим самое старое значение за 10-секундный период
	local oldSanity = 100
	if #ply.SanityHistory > 0 then
		oldSanity = ply.SanityHistory[1].hp
	end

	local lostSanity = math.Clamp(oldSanity - ply:Health(), 0, 100)
	local coeff = GetGlobalFloat("slender_sanity_speed_coeff", 0.5)
	local speedMult = 1 + coeff * (lostSanity / 100)

	local walkSpeed = math.Round(GetGlobalInt("slender_walk_speed", 125) * speedMult)
	local sprintSpeed = math.Round(GetGlobalInt("slender_sprint_speed", 190) * speedMult)
	local staminaDrain = GetGlobalFloat("slender_stamina_drain", 10)
	local staminaRegen = GetGlobalFloat("slender_stamina_regen", 1)
	local exhaustedTime = GetGlobalInt("slender_exhausted_time", 10)

	if isSprinting and not isExhausted and ply.Stamina > 0 then
		ply.Stamina = math.Clamp(ply.Stamina - FrameTime() * staminaDrain, 0, 100)
		if ply.Stamina <= 0 then
			ply.ExhaustedTime = CurTime() + exhaustedTime
		end
		mv:SetMaxSpeed(sprintSpeed)
		mv:SetMaxClientSpeed(sprintSpeed)
	else
		ply.Stamina = math.Clamp(ply.Stamina + FrameTime() * staminaRegen, 0, 100)
		if mv:KeyDown(IN_SPEED) then
			mv:SetMaxSpeed(walkSpeed)
			mv:SetMaxClientSpeed(walkSpeed)
		end
	end

	if SERVER then
		ply:SetNWFloat("Stamina", ply.Stamina)
		ply:SetNWBool("Exhausted", ply.ExhaustedTime > CurTime())
	end
end)