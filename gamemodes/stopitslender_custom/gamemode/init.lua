AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("obj_player_extend.lua")

include("shared.lua")
include("options_server.lua")


local a,b = file.Find("materials/models/slenderman/*.*" , "GAME") 
for _, filename in pairs(a) do
	resource.AddFile("materials/models/slenderman/"..string.lower(filename))
end

local a,b = file.Find("materials/models/jason278/slender/sheets/*.*" , "GAME") 
for _, filename in pairs(a) do
	resource.AddFile("materials/models/jason278/slender/sheets/"..string.lower(filename))
end

local a,b = file.Find("models/slenderman/*.*" , "GAME") 
for _, filename in pairs(a) do
	resource.AddFile("models/slenderman/"..string.lower(filename))
end

local a,b = file.Find("models/slender/*.*" , "GAME") 
for _, filename in pairs(a) do
	resource.AddFile("models/slender/"..string.lower(filename))
end

GM.IncludeAvalaibleMaps = util.tobool( CreateConVar("slender_includemaps", 1, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Should server look up for other 'slender_' maps that are not in the map cycle?"):GetInt() )
cvars.AddChangeCallback("slender_includemaps", function(cvar, oldvalue, newvalue)
	GAMEMODE.IncludeAvalaibleMaps = util.tobool( newvalue )
end)

GM.VersusMode = util.tobool( CreateConVar("slender_versusmode", 1, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Allow players to become slenderman, at the round start. Disable this, if you want to always have bot slenderman."):GetInt() )
cvars.AddChangeCallback("slender_versusmode", function(cvar, oldvalue, newvalue)
	GAMEMODE.VersusMode = util.tobool( newvalue )
end)

// resource.AddWorkshop( "171728689" ) //I know it's silly, but just in case
resource.AddWorkshop( "142020889" ) //slender_forest
resource.AddWorkshop( "172051449" ) //segments
resource.AddWorkshop( "179792391" ) //mansion v3
resource.AddWorkshop( "173885481" ) //outland v3

resource.AddFile("sound/onetwo.wav")
resource.AddFile("sound/threefour.wav")
resource.AddFile("sound/fivesix.wav")
resource.AddFile("sound/seven.wav")

local a,b = file.Find("sound/camera_static/*.*" , "GAME") 
for _, filename in pairs(a) do
	resource.AddFile("sound/camera_static/"..string.lower(filename))
end

RTV_NUM = 0

GM.RTV_Players = {}
GM.Voted_Players = {}

UPDATE_MAP_LIST = false

function change_map(pl,cmd,args)
	
	if !pl:IsAdmin() then return end
	
	local map = args[1]
	if not map then return end
	
	game.ConsoleCommand("changelevel "..map.."\n");
	
end
concommand.Add("admin_changelevel",change_map)

util.AddNetworkString( "UpdateVotes" )

concommand.Add("vote_map",function(pl,cmg,args)
	
	if GAMEMODE.Voted_Players[pl:SteamID()] then return end
	local vote = tonumber(args[1])
	
	if not vote then return end
	if not VOTING then return end
	
	if GAMEMODE.Maps[vote] then
		GAMEMODE.Maps[vote].votes = GAMEMODE.Maps[vote].votes + 1

		net.Start( "UpdateVotes" )
			net.WriteInt( vote, 32 )
		net.Broadcast()
		
		GAMEMODE.Voted_Players[pl:SteamID()] = true
	end
	
	
end)

//Used when player is afk and is slenderman at same time
concommand.Add("afk_slender",function(pl,cmg,args)
	
	if pl:Team() ~= TEAM_SLENDER then return end
	if !pl:Alive() then return end
	
	pl:KillSilent()
	
	pl:SetTeam(TEAM_SPECTATOR)
	
	timer.Simple(3,function()
		GAMEMODE:CheckSlenderman()
	end)

end)

function GM:StartVoting( time )
	
	if VOTING then return end
	
	VOTING = true
	
	for k,v in pairs(player.GetAll()) do
		v:SendLua("ShowVotingMenu( "..time.." )")
	end
	
	timer.Simple(time,function() if self then self:EndVoting() end end)
	

end

function GM:EndVoting()
	
	VOTING = false
	
	
	local max = 0
	local winner = "slender_forest"
	
	for ind,tbl in pairs(self.Maps) do
		local current = tbl.votes
		if current > max then
			max = current
			winner = tbl.map
		end
	end
	
	TOCHANGE = winner

	for k,v in pairs(player.GetAll()) do
		v:SendLua("surface.PlaySound(\"buttons/button14.wav\")")
		v:ChatPrint("Voting has ended! Next map will be "..TOCHANGE)
	end
end

function GM:CheckSlenderman()
	
	if #player.GetAll() <= 1 or #team.GetPlayers(TEAM_SLENDER) <= 0 and #ents.FindByClass("slendy") <=0 then
		local ent = ents.Create( "slendy" )
		ent:SetPos(self:GetSlendermanSpawn() or vector_origin)
		ent:Spawn()
		ent:Activate()
		print"Slenderman is bot!"
		game.GetWorld():SetDTEntity(2,ent)
		//self.LastSlender = ent
	end
	
end

//If you want to add maps on fly or if you are one of these lazy server owners. 
function GM:CheckUnlistedMaps()
	
	if !self.IncludeAvalaibleMaps then return end
	
	local needed_maps = {}
	local all_maps = file.Find( "maps/*.bsp", "GAME" )
	
	for _,mapname in pairs( all_maps ) do
		if string.find( mapname, "slender_" ) then
			local cleanname = string.sub(mapname, 1, -5)
			table.insert( needed_maps, cleanname )
		end
	end
	
	local current_maps = {}
	
	for k,v in pairs( self.Maps ) do
		if v and v.map then
			table.insert( current_maps, v.map )
		end
	end
	
	for k, v in pairs( needed_maps ) do
		if !table.HasValue( current_maps, v ) then
			self.Maps[ #self.Maps + 1 ] = {map = v, votes = 0}
			UPDATE_MAP_LIST = true
		end
	end
		
end

function GM:Initialize()
	
	if self.NightMaps and self.NightMaps[game.GetMap()] then
		self.Night = true
		self:SetNight(self:IsNight())
	end
	
	self:CheckUnlistedMaps()
	
end

function GM:GetSlendermanSpawn()
	
	if self.SlenderSpawn[game.GetMap()] then
		return self.SlenderSpawn[game.GetMap()][math.random(1,#self.SlenderSpawn[game.GetMap()])]
	end
	
	local spawns = ents.FindByClass("slender_spawn")
	
	if #spawns > 0 then
		return spawns[math.random(1,#spawns)]:GetPos()+vector_up*2
	end
	
	return 	
end

//Actually it was really stupid idea to avoid adding this from begining
function GM:GetDefaultPageSpawns()
	
	//check for custom model shit and etc
	
	local mdl = ents.FindByClass( "page_model" )
	
	if #mdl > 0 then
		local info = mdl[1]
		
		if info and info:IsValid() then
			
			if info.PageModel then
				self.OverrideModel = info.PageModel
			end
			
			if info.PageSkin then
				self.OverrideSkin = info.PageSkin
			end
			
		end
		
	end
	
	if not self.Pages[game.GetMap()] then
		
		//check if we actually have any stuff to collect
		local spawns = ents.FindByClass( "page_spawn" )
				
		if #spawns > 0 then
			
			local map = game.GetMap()
			self.Pages[map] = {}
			
			for _, page in pairs( spawns ) do

				if page and page:IsValid() and page.Number then
					
					self.Pages[map][page.Number] = self.Pages[map][page.Number] or {}
					local toadd = { page:GetPos(), page:GetAngles() }
					
					table.insert( self.Pages[map][page.Number], toadd )
					
				end
			end
		
		end
				
	end
	
end

function GM:RestartRound()

	if TOCHANGE then
		RunConsoleCommand("changelevel",TOCHANGE)
		//just to prevent round from getting stuck, in case if map is missing
		timer.Simple( 10, function() RunConsoleCommand("changelevel","slender_forest") end )
		return
	end

	game.CleanUpMap()
	self:InitPostEntity()
	
	for k, v in pairs(player.GetAll()) do
		v:SetTeam(TEAM_SPECTATOR)
		self:PlayerInitialSpawn(v)
		v:Spawn()
	end
	
	SLENDER_TELEPORT_STEP = DEFAULT_SLENDER_TELEPORT_STEP
	SLENDER_TELEPORT_FREQUENCY = DEFAULT_SLENDER_TELEPORT_FREQUENCY
	
end

function GM:InitPostEntity()
	
	ROUNDTIME = CurTime()
	ENDROUND = false
	
	game.GetWorld():SetDTInt( 1, 0 )
	
	FIRST_PAGE = false
	
	self:CreateFlashLight()
	
	local check_time = self.VersusMode and 20 or 5
	
	timer.Simple( check_time, function()
		GAMEMODE:CheckSlenderman()
	end)
	
	//just in case
	for k,v in pairs(ents.FindByClass("prop_physics*")) do
		if IsValid(v) then
			v:CollisionRulesChanged()
		end
	end

	for k,v in pairs(ents.FindByClass("prop_dynamic")) do
		if v:GetModel() == "models/slender/sheet.mdl" then
			v:Remove()
		end
	end
	
	if self.MapPostEntity[game.GetMap()] then
		self.MapPostEntity[game.GetMap()]()
	end
	
	//check for map placed page spawns
	self:GetDefaultPageSpawns()
	
	if not self.Pages[game.GetMap()] then return end
	
	for i=1, #self.Pages[game.GetMap()] do
		local pagetbl = self.Pages[game.GetMap()][i]
		
		local postbl = pagetbl[math.random(1,#pagetbl)]
		
		local pos,ang = postbl[1], postbl[2]
				
		if pos and ang then
			local ent = ents.Create( "page" )
			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:Spawn()
			ent:Activate()
		end
		
	end
	
	game.GetWorld():SetDTInt( 0, #ents.FindByClass("page") )
	
	
	
end

util.AddNetworkString( "InitialSpawn" )

GM.LastSlender = nil
function GM:PlayerInitialSpawn( pl )

	if CurTime() - ROUNDTIME <= 2*60 or #player.GetAll() <= 1 then
	
		if #player.GetAll() > 1 and #team.GetPlayers(TEAM_SLENDER) <= 0 and #ents.FindByClass("slendy") <=0 then
		
			local slendy = player.GetAll()[math.random(1,#player.GetAll())]
					
			if self.VersusMode and !pl:IsBot() and self.LastSlender ~= pl then
				pl:SetTeam(TEAM_SLENDER)
				self.LastSlender = pl
				game.GetWorld():SetDTEntity(2,pl)
				pl:CollisionRulesChanged()
			else
				pl:SetTeam(TEAM_HUMENS)
				pl:CollisionRulesChanged()
			end
			
		else
			pl:SetTeam(TEAM_HUMENS)
			pl:CollisionRulesChanged()			
		end
		
	else
		pl:SetTeam(TEAM_SPECTATOR)
		pl:CollisionRulesChanged()
	end
	
	pl:SetCustomCollisionCheck(true)

	pl:SetFrags(0)
	pl:SetDeaths(0)
	
	pl:SetPages( 0 )

	net.Start( "InitialSpawn" )
	net.Send(pl)
	
	pl:UpdateMaps()
	
	pl:SendLua("FixMotionBlur()")
end

function GM:PlayerSpray(pl)
	return true
end

//DSP:
// 115, 117, 125

function GM:PlayerSpawn( pl )

	local name = pl:GetInfo("cl_playermodel")
	local modelname = player_manager.TranslatePlayerModel(#name == 0 and "models/player/kleiner.mdl" or name)
	local lowermodelname = string.lower(modelname)
			
	if lowermodelname == "models/player/zombie_classic.mdl" or lowermodelname == "models/player/chell.mdl" then
		lowermodelname = "models/player/kleiner.mdl"
	end
			
	pl:SetModel(lowermodelname)
	pl:SetCanZoom(false)
	pl:Freeze(false)

	
	if pl:Team() == TEAM_HUMENS then
	
		//pl:SetDSP(115)//115
		
		pl:ResetBones()
		pl:SetRenderMode(RENDERMODE_NORMAL)
		pl:StripWeapons()
		pl:ShouldDropWeapon( false )
		pl:SprintEnable()

		pl:UnSpectate()

		pl:SetWalkSpeed(125)
		pl:SetRunSpeed(190)
		
		pl:SetJumpPower(160)
			
		pl:SetHealth( 100 )
		pl:SetMaxHealth( 100 )
		
		pl:SetupBattery()
		
		pl:Give("camera")
		
		pl:ChatPrint("Tired of current map? Type !rtv to rock the vote!")
	end
	
	if pl:Team() == TEAM_SLENDER then
		
		pl:SetDSP(0)
		
		pl:SetModel("models/slenderman/slenderman.mdl")
		
		for i=1, 2 do
			for k, v in pairs( self.SlenderBoneMods ) do
				local bone = pl:LookupBone(k)
				if (!bone) then continue end
				pl:ManipulateBoneScale( bone, v.scale  )
				pl:ManipulateBoneAngles( bone, v.angle  )
				pl:ManipulateBonePosition( bone, v.pos  )
			end
		end
		
		pl:StripWeapons()
		pl:ShouldDropWeapon( false )
		pl:SprintEnable()

		pl:UnSpectate()

		pl:SetWalkSpeed(260)
		pl:SetRunSpeed(260)
		
		pl:SetJumpPower(210)
			
		pl:SetHealth( 10000 )
		pl:SetMaxHealth( 10000 )
		
		pl:Give("slenderman")
		
		pl:SetPos(self:GetSlendermanSpawn() or vector_origin)
		
	end
	
	if pl:Team() == TEAM_SPECTATOR then
	
		pl:SetDSP(0)
		pl:ResetBones()
		pl:KillSilent()
	
	end
	
	pl:CollisionRulesChanged()
	
end

function GM:AllowPlayerPickup( pl, ent)
	return self.PickupProps[game.GetMap()] and ent:GetModel() == self.PickupProps[game.GetMap()] and pl:Team() == TEAM_HUMENS
end

function GM:SetNight(bl)

	self.Night = bl
	
	SetGlobalBool("night", self.Night)
	
	if bl then
		local skypaints = ents.FindByClass("env_skypaint")
		
		local env_skypaint
		if #skypaints > 0 then
			env_skypaint = skypaints[1]
		else
			env_skypaint = ents.Create("env_skypaint")
			env_skypaint:Spawn()
			env_skypaint:Activate()
		end

		env_skypaint:SetTopColor(Vector(0,0,0))
		env_skypaint:SetBottomColor(Vector(0,0,0))
		env_skypaint:SetDuskIntensity(0)
		env_skypaint:SetSunColor(Vector(0,0,0))
		env_skypaint:SetStarScale(1.1)
	
	
		game.ConsoleCommand("sv_skyname painted\n");
		
		timer.Simple(1,function() engine.LightStyle(0,"a") end)
	end
	
end

function GM:IsNight()
	return self.Night or false
end

function GM:PlayerReady ( pl )
	if self:IsNight() then
		pl:SendLua("SetGlobalBool(\"night\", true)")
	end
end

function GM:CreateFlashLight()
	local ent = ents.Create("env_projectedtexture")
	if ent:IsValid() then
		ent:SetLocalPos(Vector(16000, 16000, 16000))
		ent:SetKeyValue("enableshadows", 1)
		ent:SetKeyValue("farz", 500)//1024
		ent:SetKeyValue("nearz", 8)
		ent:SetKeyValue("lightfov", 70)//60
		ent:SetKeyValue("lightcolor", "205 205 205 115")
		ent:Spawn()
		ent:Activate()
		ent:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")		

		game.GetWorld():SetDTEntity(0,ent)
	end
	//second one
	local ent = ents.Create("env_projectedtexture")
	if ent:IsValid() then
		ent:SetLocalPos(Vector(16000, 16000, 16000))
		ent:SetKeyValue("enableshadows", 1)
		ent:SetKeyValue("farz", 684)//1024
		ent:SetKeyValue("nearz", 8)
		ent:SetKeyValue("lightfov", 20)//60
		ent:SetKeyValue("lightcolor", "255 255 255 255")
		ent:Spawn()
		ent:Activate()
		ent:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")

		game.GetWorld():SetDTEntity(1,ent)
	end
	//slender
	local ent = ents.Create("env_projectedtexture")
	if ent:IsValid() then
		ent:SetLocalPos(Vector(16000, 16000, 16000))
		ent:SetKeyValue("enableshadows", 0)
		ent:SetKeyValue("farz", 2048)//1024
		ent:SetKeyValue("nearz", 8)
		ent:SetKeyValue("lightfov", 90)//60
		ent:SetKeyValue("lightcolor", "255 55 55 255")
		ent:Spawn()
		ent:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")

		game.GetWorld():SetDTEntity(3,ent)
	end
	
end

function GM:PlayerCanHearPlayersVoice( pListener, pTalker )
	
	local sv_alltalk = GetConVar( "sv_alltalk" )
	
	local alltalk = sv_alltalk:GetInt()
	if ( alltalk > 0 ) then return true, alltalk == 2 end

	if pTalker:Team() == TEAM_HUMENS and pListener:Team() == TEAM_HUMENS then
		return true, true //3d for humans
	end
	
	if pTalker:Team() == TEAM_HUMENS and pListener:Team() == TEAM_SLENDER then
		return true, false
	end
	
	if pTalker:Team() == TEAM_HUMENS and pListener:Team() == TEAM_SPECTATOR then
		return true, false
	end
	
	if pTalker:Team() == TEAM_SPECTATOR and pListener:Team() == TEAM_HUMENS then
		return false, false
	end
	
	if pTalker:Team() == TEAM_SPECTATOR and pListener:Team() == TEAM_SLENDER then
		return true, false
	end
	
	return pListener:Team() == pTalker:Team(), false
	
end

function GM:CanPlayerSuicide( ply )
	
	return ply:Team() ~= TEAM_SLENDER
	
end

function GM:PlayerDeathSound()
	return true
end 

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	
	ply:CreateRagdoll()
	
	ply:SetTeam(TEAM_SPECTATOR)	
	
	ply:CollisionRulesChanged()
	
	ply:Spectate(OBS_MODE_ROAMING)
	
	ply:Freeze(false)
	
	sound.Play( self.DeathSounds[math.random(1,#self.DeathSounds)], ply:GetPos(), 500, 100, 1 )
	
	local humens = team.GetPlayers(TEAM_HUMENS)
	
	if #humens <= 0 then
		
		for k,v in ipairs(player.GetAll()) do
			v:ChatPrint("Slenderman has stopped silly humens! Restarting round...")
		end
		
		ENDROUND = true
		
		timer.Simple(5,function() if ENDROUND then GAMEMODE:RestartRound() end end)
		
	end
	
end

function GM:PlayerDisconnected(pl)

	if pl:Team() == TEAM_SLENDER then
		timer.Simple(3,function()
			self:CheckSlenderman()
		end)
	end
	
	timer.Simple(1, function()
	
		local humens = team.GetPlayers(TEAM_HUMENS)
		if #humens <= 0 then
			
			for k,v in ipairs(player.GetAll()) do
				v:ChatPrint("Slenderman has stopped silly humens! Restarting round...")
			end
			
			ENDROUND = true
			
			timer.Simple(5,function() if ENDROUND then GAMEMODE:RestartRound() end end)
			
		end
	end)
	
end

function GM:PlayerDeath( Victim, Inflictor, Attacker )

end

hook.Add( "PlayerShouldTaunt", "Disable Acts", function( ply )
    return false
end )

function GM:PlayerDeathThink( pl )
	
	if pl:Team() ~= TEAM_SPECTATOR then return end
	
	if pl:KeyPressed( IN_ATTACK ) then
	
		pl.Spectated = (pl.Spectated or 0) + 1
		
		local tospec = {}
		for k, v in pairs(team.GetPlayers(TEAM_HUMENS)) do
			if v:Alive() then 
				table.insert(tospec, v) 
			end
		end
		tospec = table.Add( tospec , ents.FindByClass("slendy") )
		tospec = table.Add( tospec , team.GetPlayers(TEAM_SLENDER) )
		
		local spec = tospec[pl.Spectated]
		
		if spec then
			if spec:IsPlayer() then
				pl:Spectate(OBS_MODE_IN_EYE)
			else
				pl:Spectate(OBS_MODE_CHASE)
			end
			
			pl:SpectateEntity(spec)
		else
			pl:Spectate(OBS_MODE_ROAMING)
			pl:SpectateEntity(NULL)
			pl.Spectated = nil
		end
		
	end
	
end

function GM:PlayerSay(ply, text, team_only)
	if not IsValid(ply) then return end
	
	if string.lower(string.sub(text,1, 4)) == "!rtv" then
		ply:UseRTV()
	end

	if ply:Team() == TEAM_HUMENS and team_only then
		return ""
	end
   
	if ply:Team() == TEAM_SPECTATOR and !team_only then
		return ""
	end
   
   return text
end

function GM:PlayerNoClip( pl, on )
	
	return false
	
end