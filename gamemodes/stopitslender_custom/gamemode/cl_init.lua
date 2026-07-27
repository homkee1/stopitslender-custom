include( 'shared.lua' )

surface.CreateFont( "Tahoma_lines50", { font = "Tahoma", size = 50, weight = 500, scanlines = 3, antialias = true} )
surface.CreateFont( "Tahoma_lines30", { font = "Tahoma", size = 30, weight = 700, scanlines = 3, antialias = true} )
surface.CreateFont( "Tahoma_lines18", { font = "Tahoma", size = 18, weight = 700, scanlines = 2, antialias = true} )
surface.CreateFont( "Tahoma_lines23", { font = "Tahoma", size = 23, weight = 700, scanlines = 2, antialias = true} )

surface.CreateFont( "Tahoma_lines60", { font = "Tahoma", size = 60, weight = 700, scanlines = 3, antialias = true} )
surface.CreateFont( "Tahoma_lines80", { font = "Tahoma", size = 80, weight = 700, scanlines = 3, antialias = true} )
surface.CreateFont( "Tahoma_lines130", { font = "Tahoma", size = 130, weight = 700, scanlines = 3, antialias = true} )


//Pretty much zs based ambient/beat system
local Ambient = {}
Ambient[1] = "onetwo.wav"
Ambient[2] = "onetwo.wav"
Ambient[3] = "threefour.wav"
Ambient[4] = "threefour.wav"
Ambient[5] = "fivesix.wav"
Ambient[6] = "fivesix.wav"
Ambient[7] = "seven.wav"
Ambient[8] = "seven.wav"
Ambient[9] = "seven.wav"
Ambient[10] = "seven.wav"
Ambient[11] = "seven.wav"

util.PrecacheSound("onetwo.wav")
util.PrecacheSound("threefour.wav")
util.PrecacheSound("fivesix.wav")
util.PrecacheSound("seven.wav")

util.PrecacheSound("ambient/machines/thumper_hit.wav")

for i=1,5 do
	util.PrecacheSound("ambient/creatures/flies"..i..".wav")
end


CreateClientConVar("slender_beats", 1, true, false)
CreateClientConVar("slender_filmgrain", 0, true, false)

GM.CloseupTime = 0

local starttime = 0
local nexttick = 0

local ambience = nil
local ambiencesound = Sound("ambient/atmosphere/ambience_base.wav")

local StaminaBarAlpha = 0
local staticamount = 0

local VotingTime = 0
local Voted = false

local decaltime = 0

local vote_cur_page = 1

//Check how many voting pages we need. Max 8 maps per page.
local function voting_get_max_pages()
	local max = 1
	for i=1, #GAMEMODE.Maps do
		if i > 8 * max then
			max = max + 1
		end
	end
	return max
end

local tr = {mask = MASK_SOLID}
function GM:PaintStuff()
	
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if decaltime >= CurTime() then return end
	
	local pages = ply.GetPages and ply:GetPages() or 0
	decaltime = CurTime() + math.random(1,3) + math.Clamp( 4 - pages, 0, 4)
	
	//local test = LocalPlayer():GetEyeTrace()
	
	tr.start = EyePos()
	tr.endpos = EyePos() + VectorRand() * 1300
	tr.filter = player.GetAll()
	
	local test = util.TraceLine( tr )
	
	if test.Hit then
		util.Decal("Blood", test.HitPos + test.HitNormal, test.HitPos - test.HitNormal)
		
		if math.random(40) == 1 then
			sound.Play(math.random(5) == 5 and "ambient/machines/thumper_hit.wav" or "ambient/creatures/flies"..math.random(1,5)..".wav", test.HitPos, 90, math.random(80, 110),1)
		end
	end

end

local checked_first_initial = true
local redownloaded_lightmaps = false

function GM:InitialSpawn()
		
	checked_first_initial = true
	
	starttime = CurTime()
	
	if not ambience and IsValid(LocalPlayer()) then
		ambience = CreateSound(Entity(0),ambiencesound)
	end
	
	CurrentSprint = MaxSprint
	staticamount = 0
	
	//just in case
	if GetGlobalBool("night") and !redownloaded_lightmaps then
		timer.Simple(1, function()
			render.RedownloadAllLightmaps( true ) 
		end)
		redownloaded_lightmaps = true
	end
		
	
end

function FixMotionBlur()
	//Preventing distortion glitch
	if render.GetDXLevel() > 81 then
		RunConsoleCommand("mat_motion_blur_enabled", "1")
	end
end

local NextBeat = 0

//Once again zs based ambient sounds
function GM:PlayAmbient(am)	
	
	if not util.tobool(GetConVarNumber("slender_beats")) then return end
	if RealTime() <= NextBeat then return end
	
	local MySelf = LocalPlayer()

	local beats = Ambient
	if not beats then return end

	local snd = beats[am]
	if snd then
		MySelf:EmitSound(snd, 0, 100, 0.8)
		NextBeat = RealTime() + SoundDuration(snd) - 0.025
	end
end

local scale = {
	["ValveBiped.Bip01_R_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 55.591, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 54.784, 0) }
}

local scale2 = {
	["ValveBiped.Bip01_Head1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 55.591, 0)  },
	["ValveBiped.Bip01_R_Finger01"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger22"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger21"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Forearm"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger12"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger11"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_UpperArm"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger22"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Hand"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger12"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Clavicle"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 55.591, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger11"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Forearm"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger01"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger02"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Neck1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger0"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

local changedbones = false

function GM:Think()
	
	local MySelf = LocalPlayer()
	if not IsValid(MySelf) or not MySelf:IsPlayer() then return end
	
	if not checked_first_initial then
		self:InitialSpawn()
	end
	
	local pages = MySelf.GetPages and MySelf:GetPages() or 0
	local am = (IsValid(Entity(0)) and Entity(0).GetDTInt) and Entity(0):GetDTInt( 1 ) or pages
	
	self:PlayAmbient(am)
	
	if MySelf:Team() == TEAM_HUMENS and MySelf:Alive() then
		if not changedbones then
			for k, v in pairs(scale2) do
				local bone = MySelf:LookupBone(k)
				if (!bone) then continue end
					MySelf:ManipulateBoneScale( bone, v.scale  )
					MySelf:ManipulateBoneAngles( bone, v.angle  )
					MySelf:ManipulateBonePosition( bone, v.pos  )
				end
			changedbones = true
		end
	else
		if changedbones then
			MySelf:ResetBones()
			changedbones = false
		end
	end
	
	self:CheckVoting()	
	
	if MySelf:Team() ~= TEAM_HUMENS then return end
	if !MySelf:Alive() then return end
	
	self:PaintStuff()
	
end

-- Отрендерено в HUDPaint выше

//local lens = Material("models/props_c17/fisheyelens")//
local lens = Material( "effects/strider_pinch_dudv" )
local current = 0
local screenblackout = 0
local static = surface.GetTextureID("filmgrain")

local scoreboard_alpha = 0

function BlackOut( time )
	
	screenblackout = CurTime() + time
	
end

local nextclick = 0
function GM:HUDPaint()
	
	drawhud = true
	

	local MySelf = LocalPlayer()
	if not IsValid(MySelf) or not MySelf:IsPlayer() then return end
	
	local w,h = ScrW(), ScrH()	
	local gap_x = w * 0.04
	local gap_y = h * 0.04
	
	local hudColor = Color(200, 235, 255, 75)
	local hudTextColor = Color(215, 240, 255, 95)
	
	draw.NoTexture()
	
	if MySelf:Team() ~= TEAM_SLENDER then
	
		surface.SetDrawColor(hudColor)
		
		//frame
		surface.DrawRect(gap_x+2, gap_y, w-2*gap_x, 2)
		surface.DrawRect(gap_x, h-gap_y, w-2*gap_x, 2)
		surface.DrawRect(gap_x, gap_y, 2,  h-2*gap_y)
		surface.DrawRect(w-gap_x, gap_y+2, 2,  h-2*gap_y)
		
		//battery
		local batX,batY = gap_x*1.5, gap_y*1.3
		local batW,batH = 110, 45
		
		local target = IsValid(MySelf:GetObserverTarget()) and MySelf:GetObserverTarget():IsPlayer() and MySelf:GetObserverTarget() or MySelf
		
		local am = math.Clamp(target:Health()/100,0,1)
		
		if am <= 0.3 then
			surface.SetDrawColor(Color(255,35,35,70))
		else
			surface.SetDrawColor(hudColor)
		end
		
		surface.DrawRect(batX+3,batY+3,(batW-6)*am,batH-6)
		
		surface.DrawOutlinedRect(batX,batY,batW,batH)
		surface.DrawOutlinedRect(batX-1,batY-1,batW+2,batH+2)
		surface.DrawRect(batX+batW+1,batY+batH/4,6,batH/2)
		
		
		local dead = target.BatteryDead and !target:IsSlenderman() and target:BatteryDead()
		
		if dead then
			draw.SimpleText("BATTERY DEAD", "Tahoma_lines18",batX, batY+batH+5, Color(215,15,15,100), TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		end
		
		//Rec
		local txt = MySelf:Alive() and "REC" or "PLAY"
		local red = MySelf:Alive() and 215 or 15
		local green = MySelf:Alive() and 15 or 215
		
		local time = string.FormattedTime(CurTime() - starttime, "%02i:%02i:%02i")
		draw.SimpleText(txt, "Tahoma_lines50",w-gap_x*1.5+((MySelf:Alive() and 0) or 4), gap_y*1.2, Color(red,green,15,100*math.Round(math.Clamp(math.sin(RealTime()*3.5)*2,0,1))), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		draw.SimpleText(time, "Tahoma_lines18",w-gap_x*1.5, gap_y*1.2+45, hudTextColor, TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		
	end
	//spectator thingy
	if IsValid(MySelf:GetObserverTarget()) then
	
		local name = MySelf:GetObserverTarget().Nick and MySelf:GetObserverTarget():Nick() or MySelf:GetObserverTarget().PrintName or "NONE"
		draw.SimpleText("Spectating "..name, "Tahoma_lines18",w-gap_x*1.5, h-gap_y*1.3-23, hudTextColor, TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
		
		local obs = MySelf:GetObserverTarget()
		local pages = (IsValid(obs) and obs:IsPlayer() and obs.GetPages) and obs:GetPages() or 0
		local maxPages = (IsValid(MySelf) and MySelf.GetMaxPages) and MySelf:GetMaxPages() or 8
		draw.SimpleText("Pages "..pages.."/"..maxPages, "Tahoma_lines18",w-gap_x*1.5, h-gap_y*1.3, hudTextColor, TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
		
	else
		if MySelf:Team() == TEAM_SPECTATOR then
			local dlight = DynamicLight( MySelf:EntIndex() )
			if ( dlight ) then
				dlight.Pos = EyePos()+EyeAngles():Forward()*30
				dlight.r = 255
				dlight.g = 255
				dlight.b = 255
				dlight.Brightness = 3
				dlight.Size = 370
				dlight.Decay = 370 * 5
				dlight.DieTime = CurTime() + 1
				dlight.Style = 0
			end
		end
		if MySelf:Team() ~= TEAM_SLENDER then
			local pages = (IsValid(MySelf) and MySelf.GetPages) and MySelf:GetPages() or 0
			local maxPages = (IsValid(MySelf) and MySelf.GetMaxPages) and MySelf:GetMaxPages() or 8
			draw.SimpleText("Pages "..pages.."/"..maxPages, "Tahoma_lines18",w-gap_x*1.5, h-gap_y*1.3, hudTextColor, TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
		end
	end

	-- Stamina Bar
	if MySelf:Team() != TEAM_SLENDER then
		local ToWatch = IsValid(MySelf:GetObserverTarget()) and MySelf:GetObserverTarget():IsPlayer() and MySelf:GetObserverTarget() or MySelf
		local staminaVal = ToWatch:GetNWFloat("Stamina", 100)
		local isExhausted = ToWatch:GetNWBool("Exhausted", false)

		local targetAlpha = 0
		if staminaVal < 100 or isExhausted then
			targetAlpha = 70
		end
		StaminaBarAlpha = math.Approach(StaminaBarAlpha, targetAlpha, FrameTime() * 150)

		if StaminaBarAlpha > 0 then
			local barW, barH = 200, 20
			local barX = w / 2 - barW / 2
			local barY = h - gap_y * 1.5

			local mainColor = isExhausted and Color(215, 15, 15, StaminaBarAlpha) or Color(200, 235, 255, StaminaBarAlpha)

			-- Draw fill
			surface.SetDrawColor(mainColor)
			surface.DrawRect(barX + 3, barY + 3, (barW - 6) * (staminaVal / 100), barH - 6)

			-- Draw division lines (9 lines for 10 segments)
			surface.SetDrawColor(Color(0, 0, 0, StaminaBarAlpha * 0.5))
			for i = 1, 9 do
				local lineX = barX + (barW / 10) * i
				surface.DrawLine(lineX, barY + 3, lineX, barY + barH - 3)
			end

			-- Draw outlines
			surface.SetDrawColor(mainColor)
			surface.DrawOutlinedRect(barX, barY, barW, barH)
			surface.SetDrawColor(mainColor)
			surface.DrawOutlinedRect(barX - 1, barY - 1, barW + 2, barH + 2)
		end
	end
	
	//zoom
	local wep = IsValid(MySelf:GetActiveWeapon()) and MySelf:GetActiveWeapon():GetClass() == "camera" and MySelf:GetActiveWeapon()
		
	if wep and wep.Zoom then
		surface.SetDrawColor(hudColor)
		
		local zoomW,zoomH = 300, 20
		local zoomX,zoomY = w/2-zoomW/2,gap_y*1.3
		
		local zoom_barW = (zoomW-6)/10
		
		surface.DrawOutlinedRect(zoomX,zoomY,zoomW,zoomH)
		surface.DrawOutlinedRect(zoomX-1,zoomY-1,zoomW+2,zoomH+2)
		
		surface.DrawRect((zoomX+3)+(zoomW-6-zoom_barW)*(wep.Zoom/40),zoomY+3,zoom_barW,zoomH-6)
	end
	
	//scoreboard
	if MySelf:KeyDown(IN_SCORE) then
		if scoreboard_alpha ~= 100 then
			scoreboard_alpha = math.Approach ( scoreboard_alpha, 100, FrameTime()*200 )
		end
		if MySelf:KeyDown(IN_ATTACK2) then
			gui.EnableScreenClicker( true )
		else
			if not (SlenderUI and IsValid(SlenderUI.Frame)) then
				gui.EnableScreenClicker( false )
			end
		end
	else
		if scoreboard_alpha ~= 0 then
			scoreboard_alpha = math.Approach ( scoreboard_alpha, 0, FrameTime()*200 )
		end
		if not (SlenderUI and IsValid(SlenderUI.Frame)) then
			gui.EnableScreenClicker( false )
		end
	end
	
	if scoreboard_alpha > 0 then
		
		local sW,sH = w/4.6, h/2
		local sX,sY = w-gap_x*1.5-sW, h/2-sH/2
		
		surface.SetDrawColor(Color(200, 235, 255, math.Clamp(scoreboard_alpha,0,70)))
		
		surface.DrawOutlinedRect(sX,sY,sW,sH)
		surface.DrawOutlinedRect(sX-1,sY-1,sW+2,sH+2)
		
		
		draw.SimpleText(math.random(40) == 1 and "NO DATA" or "Stop it, Slender! by NECROSSIN", "Tahoma_lines23",sX+sW-6,sY+4-23*2-8, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		draw.SimpleText(math.random(40) == 1 and "NO DATA" or "version "..(self.Version or "error"), "Tahoma_lines23",sX+sW-6,sY+4-23-6, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		
		local offsetY = 0
		
		local allSlenders = {}
		for _, p in ipairs(player.GetAll()) do
			if p:Team() == TEAM_SLENDER then
				table.insert(allSlenders, p)
			end
		end
		for _, b in ipairs(ents.FindByClass("slendy")) do
			table.insert(allSlenders, b)
		end

		local offsetY = 0
		
		for _, slender in ipairs(allSlenders) do
			if IsValid(slender) then
				local name = slender.Nick and slender:Nick() or "Бот Слендер #" .. slender:EntIndex()
				local ping = slender.Ping and slender:Ping() or ""
				local muted = slender.IsMuted and slender:IsMuted() or false

				draw.SimpleText(name, "Tahoma_lines23", sX+6, sY+4+offsetY, Color(215,15,15,scoreboard_alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(ping, "Tahoma_lines23", sX+sW-6, sY+4+offsetY, Color(215,15,15,scoreboard_alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				draw.SimpleText(muted and "MUTED" or "", "Tahoma_lines23", sX+sW-6-45, sY+4+offsetY, Color(215,15,15,scoreboard_alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

				local mx, my = gui.MousePos()
				if mx > sX and mx < sX+sW and my > sY+offsetY and my < sY+offsetY+25 then
					if input.IsMouseDown(MOUSE_LEFT) and nextclick <= CurTime() and slender:IsPlayer() then
						slender:SetMuted(!muted)
						nextclick = CurTime() + 1
					end
				end

				offsetY = offsetY + 23 + 6
			end
		end
		
		for _,pl in ipairs(player.GetAll()) do
		
			if pl == slender then continue end
			
			local name = pl:Nick()
			local ping = pl:Ping() or ""
			
			draw.SimpleText(!pl:Alive() and math.random(30) == 1 and "NO DATA" or name, "Tahoma_lines23",sX+6,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			draw.SimpleText(ping, "Tahoma_lines23",sX+sW-6,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
			draw.SimpleText(pl:IsMuted() and "MUTED" or "", "Tahoma_lines23",sX+sW-6-45,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)

			local mx,my = gui.MousePos()
		
			if mx > sX and mx < sX+sW and my > sY+offsetY and my < sY+offsetY+25 then
			
				if input.IsMouseDown( MOUSE_LEFT ) and nextclick <= CurTime() then
					pl:SetMuted( !pl:IsMuted() )
					nextclick = CurTime() + 1
				end
				draw.SimpleText(!pl:Alive() and math.random(30) == 1 and "NO DATA" or name, "Tahoma_lines23",sX+6,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				draw.SimpleText(ping, "Tahoma_lines23",sX+sW-6,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
				draw.SimpleText(pl:IsMuted() and "MUTED" or "", "Tahoma_lines23",sX+sW-6-45,sY+4+offsetY, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		
			end
	
			offsetY = offsetY + 23 + 2
		end
		
		draw.SimpleText("Click on squeaky player to mute!", "Tahoma_lines23",sX+4,sY+sH-4, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		
		local mx,my = gui.MousePos()
		
		draw.SimpleText("X", "Tahoma_lines23",mx,my, Color(215,15,15,scoreboard_alpha), TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		
		draw.SimpleText("Hold [RIGHT MOUSE BUTTON] to enable mouse cursor", "Tahoma_lines23",w/2,h-gap_y*1.3, Color(215, 240, 255, scoreboard_alpha), TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)
	end
	
	if VotingTime and VotingTime > CurTime() then
	
		local mW,mH = w/7, h/3
		local mX,mY = gap_x*1.5, h/2-mH/2-25
		
		local offsetY = 0
			
		surface.SetDrawColor(hudColor)
		
		draw.SimpleText("Vote for the next map!", "Tahoma_lines23",mX+6,mY+4, Color(215,15,15,70), TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		
		offsetY = offsetY + 23 + 10
		
		local num = 1
		
		for ind = 1 + 8*(vote_cur_page - 1),math.min(#GAMEMODE.Maps,8*vote_cur_page) do
						
			tbl = GAMEMODE.Maps[ind]
			
			if tbl then
			
				draw.SimpleText(num..".", "Tahoma_lines23",mX+6,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				draw.SimpleText((tbl.map or "error!").."  ("..(tbl.votes or 0)..")", "Tahoma_lines23",mX+6+30,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				
				offsetY = offsetY + 23 + 2
				
				num = num + 1
			end
		end
		
		if voting_get_max_pages() > 1 then
			
			offsetY = offsetY + 23*2 + 2
			
			if vote_cur_page > 1 then
				draw.SimpleText("9.", "Tahoma_lines23",mX+6,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				draw.SimpleText("Previous page", "Tahoma_lines23",mX+6+30,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				offsetY = offsetY + 23 + 2
			end
			
			if vote_cur_page < voting_get_max_pages() then
				draw.SimpleText("0.", "Tahoma_lines23",mX+6,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
				draw.SimpleText("Next page", "Tahoma_lines23",mX+6+30,mY+4+offsetY, hudTextColor, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			end
			
		end
		
	end
	
	if screenblackout and screenblackout >= CurTime() then
		
		surface.SetDrawColor(Color(0,0,0,255))
		surface.DrawRect(-w/4,-h/4,w*2,h*2)
		
		surface.SetTexture( static )
		surface.SetDrawColor(Color(255,255,255,15))

		surface.DrawTexturedRect( -w/4,-h/4,w*2,h*2 )

		
		draw.SimpleText("The tape ends there", "Tahoma_lines80",w/2, h/2, Color(255,255,255,100), TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	end
	
end


local slender = NULL
local distortamount = 0

local staticsound = Sound("camera_static/static.wav")
local staticloop

local SpazzSounds = {
	[1] = {min = 401, max = 600, snd = { Sound("camera_static/single1.wav"), Sound("camera_static/single2.wav"), Sound("camera_static/single5.wav") } },
	[2] = {min = 201, max = 400, snd = { Sound("camera_static/single4.wav"),  Sound("camera_static/single6.wav") } },//Sound("camera_static/single3.wav"),
	[3] = {min = 0, max = 200, snd = { Sound("camera_static/single_big1.wav"), Sound("camera_static/single_big2.wav"), Sound("camera_static/single_big3.wav") } },
}

local closeup_sound = Sound("camera_static/closeup_short.wav")

local nextsoundspazz = 0
local spazzplayed = false

//TODO: Remove this blur thingy
local blur = {x = 0, y = 0, f = 0, spin = 0, time = 0}

function MakeBlur(x,y,f,spin,time)
		
	blur.x = x or 0
	blur.y = y or 0
	blur.f = f or 0
	blur.spin = spin or 0
	
	blur.time = CurTime() + time or 0
	
end

function GM:HUDPaintBackground()
	
	local MySelf = LocalPlayer()
	if not IsValid(MySelf) or not MySelf:IsPlayer() then return end
	
	local w,h = ScrW(), ScrH()
	
	if not staticloop then
		staticloop = CreateSound( MySelf, staticsound )
	end

	local allSlenders = {}
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == TEAM_SLENDER and p ~= MySelf then
			table.insert(allSlenders, p)
		end
	end
	for _, b in ipairs(ents.FindByClass("slendy")) do
		table.insert(allSlenders, b)
	end

	local ToWatch = IsValid(MySelf:GetObserverTarget()) and MySelf:GetObserverTarget():IsPlayer() and MySelf:GetObserverTarget():Team() == TEAM_HUMENS and MySelf:GetObserverTarget() or MySelf
	
	local addstatic = 0
	local am = math.Clamp(ToWatch:Health()/100,0,1)
	
	if am <= 0.3 and am > 0 then
		addstatic = math.Clamp(0.5 - am,0,0.5)
	end
	
	local staticX, staticY = w/2, h/2
	local closestDist = 999999

	for _, slender in ipairs(allSlenders) do
		local visible = true
		if slender:IsPlayer() then
			local wep = IsValid(slender:GetActiveWeapon()) and slender:GetActiveWeapon():GetClass() == "slenderman" and slender:GetActiveWeapon()
			if wep and wep.IsVisible then
				visible = wep:IsVisible()
			end
		end

		if visible and ToWatch:Alive() then
			local dist = ToWatch:GetPos():Distance(slender:GetPos())
			local withinStaticDist = dist <= 650
			local lookingAtSlender = ToWatch:SyncAngles():Forward():Dot((ToWatch:GetPos()-slender:GetPos()):GetNormal()) < -0.3
			local hasLOS = TrueVisible(EyePos(), slender:NearestPoint(EyePos()), ToWatch)

			if (withinStaticDist and lookingAtSlender and hasLOS) or dist <= 100 then
				local calculatedStatic = math.Clamp( ((650-dist)/650)^(1/1.1), 0, 1 )
				if calculatedStatic > addstatic then
					addstatic = calculatedStatic
					closestDist = dist
					local pos = (slender:GetPos()+vector_up*60):ToScreen()
					if pos.x > 110 and pos.x < w-110 and pos.y > 110 and pos.y < h-110 then	
						staticX, staticY = pos.x, pos.y
					end
				end
			end
		end
	end
	
	if addstatic > 0 then
		local dist = closestDist
		if not spazzplayed then
				local toplay = nil
				for _ = 1, #SpazzSounds do
					local tbl = SpazzSounds[_]
					if dist <= tbl.max and dist >= tbl.min then
						toplay = tbl.snd and tbl.snd[math.random(1,#tbl.snd)]
						addstatic = _/3
						break
					end
				end
				
				if toplay and ToWatch:Health() > 1 then
					local pitch = math.random(90,105)
					LocalPlayer():EmitSound( toplay,150, pitch,1 )
					LocalPlayer():EmitSound( toplay,0, pitch,1 )
					LocalPlayer():EmitSound( toplay,0, pitch,1 )
					spazzplayed = true
					nextsoundspazz = CurTime() + math.random(5,7)
				end
			end
		else
			if nextsoundspazz <= CurTime() then
				spazzplayed = false
				nextsoundspazz = CurTime() + 10
			end
		end
	
	if GAMEMODE.CloseupTime and GAMEMODE.CloseupTime + 3 > CurTime() then
		local l = math.Clamp((CurTime() - GAMEMODE.CloseupTime)/3, 0, 1)
		addstatic = 0.5 * l
	end
	
	local nodistort = false
	
	if screenblackout and screenblackout >= CurTime() then
		addstatic = 3
		nodistort = true
	end
	
	staticamount = math.Approach ( staticamount, addstatic, FrameTime()/2 )
	local adddistort = math.Rand(-0.09,0.09)*staticamount
	
	distortamount = math.Approach ( math.Clamp(distortamount,-0.09,0.09), adddistort, FrameTime()*10 )

	if staticloop then
		staticloop:PlayEx(staticamount^1.1,math.Rand(75,145))
	end

	local distortions = render.GetDXLevel() > 81
	
	if util.tobool(GetConVarNumber("slender_filmgrain")) then
		distortions = false
	end
	

	if distortions then
		if staticamount > 0 and !nodistort then
			
			lens:SetFloat("$refractamount",	distortamount)
			
			surface.SetMaterial( lens )
			surface.SetDrawColor(Color(255,255,255,1))
			surface.DrawTexturedRectRotated(staticX+math.Rand(-15,15),staticY+math.Rand(-15,15),w*math.Rand(0.8,2),h*math.Rand(0.8,2),0)//w*math.Rand(0.8,2),h*math.Rand(0.8,2)
		end
	else
		if staticamount > 0 and !nodistort then
			surface.SetTexture( static )
			surface.SetDrawColor(Color(255,255,255,staticamount * 10 ))
			for x = 0, w, 1024 do
				for y = 0, h, 512 do
					surface.DrawTexturedRect( x, y, 1024, 512 )
				end
			end
		end
	end
	
	if LocalPlayer():Team() ~= TEAM_SLENDER then
		DrawBloom( 0.03, 0.75, 6, 0, 1, 1, 47/255, 196/255, 255/255 )
	end
	
	
	//TODO: Enable this for dx8 users
	
	//surface.SetTexture( static )
	//surface.SetDrawColor(Color(255,255,255,/*staticamount * 60 + */(am <= 0.5 and 3*(1-am) or 0)))
	//for x = 0, w, 1024 do
		//for y = 0, h, 512 do
			//surface.DrawTexturedRect( x, y, 1024, 512 )
		//end
	//end
end

hook.Add("AdjustMouseSensitivity", "DontLook", function(default_sensitivity)
	local ply = LocalPlayer()
	if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:Team() == TEAM_HUMENS and staticamount and staticamount > 0 then
		return math.Clamp( 1 - staticamount, 0.4,1)
	end
end)

local blur_am = 0
local function GetMotionBlurValues( x, y, fwd, spin )

	local add_am = 0
	
	if blur.time >= CurTime() then
		add_am = 1
	end
	
	blur_am = math.Approach ( blur_am, add_am, 0.001 )

	return x,y,blur.f*blur_am, spin+blur.spin*blur_am
end
//hook.Add( "GetMotionBlurValues", "SlenderBlur", GetMotionBlurValues )


local NotToDraw = { "CHudHealth","CHudBattery", "CHudSecondaryAmmo","CHudAmmo","CHudCrosshair","CHudVoiceStatus"}
hook.Add("HUDShouldDraw","HideDef",function(name)
	for k,v in pairs(NotToDraw) do
		if (v == name) then 
			return false
		end
	end
end)

function GM:PlayerBindPress(ply, bind, pressed)

	if string.find ( bind, "invnext" ) then
		
		local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "camera" and ply:GetActiveWeapon()
		
		if wep and wep.Zoom then
			wep.Zoom = math.Clamp(wep.Zoom-2,0,40)
		end
		
		return true
	end
	
	if string.find ( bind, "invprev" ) then
		
		local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "camera" and ply:GetActiveWeapon()
		
		if wep and wep.Zoom then
			wep.Zoom = math.Clamp(wep.Zoom+2,0,40)
		end
		
		return true
	end
	
	if string.find ( bind, "+forward" ) or string.find ( bind, "+back" ) or string.find ( bind, "+moveleft" ) or string.find ( bind, "+moveright" ) or string.find ( bind, "+jump" ) then
		
		local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "slenderman" and ply:GetActiveWeapon()
		
		if string.find ( bind, "+jump" ) then
			if wep and wep.FreezeMovement and wep.IsVisible then
				return wep:FreezeMovement() or wep:IsVisible()
			end
		end
		
		if wep and wep.FreezeMovement then
			return wep:FreezeMovement()
		end
	end
	
	if ply:Team() == TEAM_HUMENS and ply:Alive() and string.find ( bind, "+speed" ) then
		return (ply.ExhaustedTime and ply.ExhaustedTime > CurTime()) or (ply.Stamina and ply.Stamina <= 0)
	end
	
	if ply:Team() == TEAM_HUMENS and (string.find ( bind, "say_team" ) or string.find ( bind, "messagemode2" )) then
		return true
	end
	
	if ply:Team() == TEAM_SPECTATOR and ((string.find ( bind, "say" ) and not string.find ( bind, "say_team" )) or (string.find ( bind, "messagemode" ) and not string.find ( bind, "messagemode2" ))) then
		return true
	end

end

local function AddSlenderFog()

	render.FogMode( 1 ) 
	render.FogStart( 0 )
	render.FogEnd( 10000  )
	render.FogMaxDensity( 0.9 )

	
	render.FogColor( 1 * 255, 0.1 * 255, 0.1 * 255 )

	return true

end

local function AddSlenderFogSkybox(skyboxscale)

	render.FogMode( 1 ) 
	render.FogStart( 0*skyboxscale )
	render.FogEnd( 10000*skyboxscale  )
	render.FogMaxDensity( 0.9 )

	
	render.FogColor( 1 * 255, 0.1 * 255, 0.1 * 255 )

	return true

end

local function AddNightFog()

	render.FogMode( 1 ) 
	render.FogStart( 0 )
	render.FogEnd( 650  )
	render.FogMaxDensity( 1 )

	
	render.FogColor( 0.0 * 255, 0.0 * 255, 0.0 * 255 )

	return true

end

local function AddNightFogSkybox(skyboxscale)

	render.FogMode( 1 ) 
	render.FogStart( 0*skyboxscale )
	render.FogEnd( 650*skyboxscale  )
	render.FogMaxDensity( 1 )

	
	render.FogColor( 0.0 * 255, 0.0 * 255, 0.0 * 255 )

	return true

end

local drawfog = false
local drawnight = false

hook.Add("Think","SlenderFog",function()
	
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:IsPlayer() or not ply.IsSlenderman then return end
	
	if ply:IsSlenderman() then
		if drawnight then
			hook.Remove( "SetupWorldFog","AddNightFog" )
			hook.Remove( "SetupSkyboxFog","AddNightFogSkybox" )
			drawnight = false
		end
		if not drawfog then
			hook.Add( "SetupWorldFog","AddSlenderFog", AddSlenderFog )
			hook.Add( "SetupSkyboxFog","AddSlenderFogSkybox", AddSlenderFogSkybox )
			drawfog = true
		end
	else
		if drawfog then
			hook.Remove( "SetupWorldFog","AddSlenderFog" )
			hook.Remove( "SetupSkyboxFog","AddSlenderFogSkybox" )
			drawfog = false
		end
		if GAMEMODE:IsNight() and not drawnight then
			hook.Add( "SetupWorldFog","AddNightFog", AddNightFog )
			hook.Add( "SetupSkyboxFog","AddNightFogSkybox", AddNightFogSkybox )
			drawnight = true
		end
	end
	
end)

local colormodulation = false
local drawbody = false
local mat = Material( "models/shiny" )
local vector_down = vector_up * -1

function GM:PrePlayerDraw(pl)
	
	local ply = LocalPlayer()
	if IsValid(ply) and ply:IsPlayer() and ply.IsSlenderman and ply:IsSlenderman() and pl:Team() == TEAM_HUMENS then
		colormodulation = true
		local health = pl:Health() / 100
		cam.IgnoreZ(true)
		render.SuppressEngineLighting( true )
		render.SetColorModulation(1 - health, health, 0)
		render.ModelMaterialOverride( mat )
	end
	if LocalPlayer() == pl and pl:Team() == TEAM_HUMENS and pl:Alive() then
		drawbody = true
		render.EnableClipping( true )
		render.PushCustomClipPlane( vector_down, vector_down:Dot( EyePos() + vector_down*7.5 ) )
	end
end

function GM:PostPlayerDraw(pl)
	if colormodulation then
		render.ModelMaterialOverride()
		render.SetColorModulation(1,1,1)
		render.SuppressEngineLighting( false )
		cam.IgnoreZ(false)
		colormodulation = false
	end
	if drawbody then
		render.PopCustomClipPlane()
		render.EnableClipping( false )
		drawbody = false
	end
end


function GM:CalcView( pl, origin, angles, fov, znear, zfar )
	
	if pl:Team() == TEAM_HUMENS and pl:Alive() then
		
		local att = pl:GetAttachment(pl:LookupAttachment("eyes"))
			
		if att then
		
			angles.pitch = math.Clamp(angles.pitch+att.Ang.pitch*0.65,-90,90)
			angles.roll = att.Ang.roll*0.4
		
			return {origin = att.Pos, angles = angles, drawviewer = true}

		end
	end
	
	return self.BaseClass.CalcView(self, pl, origin, angles, fov, znear, zfar)
end



local function CloseupCalcView(pl, origin, angles, fov, znear, zfar)

	if GAMEMODE.CloseupTime and GAMEMODE.CloseupTime + 3 > CurTime()then
	
		local topos, toang
		
		local slender = Entity(0):GetDTEntity(2) ~= MySelf and Entity(0):GetDTEntity(2) or NULL
		
		if IsValid(slender) then
			local bone = slender:LookupBone("ValveBiped.Bip01_Head1")
			if bone then
				local pos,ang = slender:GetBonePosition(bone)
				
				if pos and ang then
					pos = pos+ang:Right() * 20+ang:Forward()*3
					ang.p = ang.p + 70
					ang.y = ang.y + 180
					ang.r = ang.r - 90
					
					topos, toang = pos, ang
				end	
			end
		end
		
		if topos and toang then
			local l = math.Clamp((CurTime() - GAMEMODE.CloseupTime)/0.22, 0, 1)
			return {origin = LerpVector( l, origin, topos ), angles = LerpAngle( l, angles, toang )}
		end

		return
	end

	hook.Remove("CalcView", "CloseupCalcView")
	
	BlackOut( 5 )
	
end

function ShowCloseup()
	
	GAMEMODE.CloseupTime = CurTime()
	
	LocalPlayer():EmitSound(closeup_sound,0,100,1)
	LocalPlayer():EmitSound(closeup_sound,0,100,1)
	
	hook.Add("CalcView", "CloseupCalcView", CloseupCalcView)
	
end

function GM:RenderScreenspaceEffects()

end

function GM:ScoreboardShow()

end

function GM:ScoreboardHide()

end

hook.Add("OnPlayerChat","Chat Radius",function( player, strText, bTeamOnly, bPlayerIsDead )
	
	if IsValid(LocalPlayer()) and LocalPlayer():Team() ~= TEAM_HUMENS then return false end
	
	if IsValid(player) and player:Team() == TEAM_HUMENS then
		local distance = LocalPlayer():GetPos():Distance(player:GetPos())
		return distance >= 800
	end
	
end)

net.Receive( "InitialSpawn", function( len )
	
	if !IsValid(LocalPlayer()) then 
		checked_first_initial = false
		return 
	end
		
	GAMEMODE:InitialSpawn()
	
end)


function ShowVotingMenu( time )
	
	VotingTime = CurTime() + (time or 15)
	
end


//TODO: Add support for multiple rtv pages on 0 button
local inputs = {
	[KEY_1] = 1, [KEY_2] = 2, [KEY_3] = 3, [KEY_4] = 4, [KEY_5] = 5, [KEY_6] = 6, [KEY_7] = 7, [KEY_8] = 8,
}

local button_delay = 0

function GM:CheckVoting()
	
	if VotingTime <= CurTime() then return end
	
	if button_delay <= CurTime() then
		//prev
		if input.IsKeyDown( KEY_9 ) and vote_cur_page > 1 then
			vote_cur_page = math.Clamp( vote_cur_page - 1, 1, voting_get_max_pages() )
			surface.PlaySound("UI/hint.wav")
			button_delay = CurTime() + 0.5
		end
		//next
		if input.IsKeyDown( KEY_0 ) and vote_cur_page < voting_get_max_pages() then
			vote_cur_page = math.Clamp( vote_cur_page + 1, 1, voting_get_max_pages() )
			surface.PlaySound("UI/hint.wav")
			button_delay = CurTime() + 0.5
		end
	
	end
	
	for key, ind in pairs(inputs) do
		if input.IsKeyDown( key ) and GAMEMODE.Maps[ind+8*(vote_cur_page-1)] and not Voted then
			RunConsoleCommand("vote_map",tostring(ind+8*(vote_cur_page-1)))
			Voted = true
			break
		end	
	end
	
end


util.PrecacheSound("UI/hint.wav")
util.PrecacheSound("buttons/button14.wav")

net.Receive( "UpdateVotes", function( len )
	
	if !IsValid(LocalPlayer()) then return end
	
	local vote = net.ReadInt( 32 )
	
	if GAMEMODE.Maps[vote] then
		GAMEMODE.Maps[vote].votes = GAMEMODE.Maps[vote].votes + 1
		surface.PlaySound("UI/hint.wav")
	end
	
end)

net.Receive( "UpdateMaps", function( len )

	local tbl = net.ReadTable()
	if tbl then
		GAMEMODE.Maps = table.Copy( tbl )
	end
	
end)

function GM:IsNight()
	return GetGlobalBool("night")
end

net.Receive( "PagePickedUp", function( len )
	local ent = net.ReadEntity()
	if IsValid(ent) then
		ent.Taken = true
	end
end)
