local meta = FindMetaTable( "Player" )
if (!meta) then return end

function meta:IsSlenderman()
	return self:Team() == TEAM_SLENDER
end

function meta:IsSlenderVisible()
	local wep = IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():GetClass() == "slenderman" and self:GetActiveWeapon()
	if wep and wep.GetInvisMode then
		return !wep:GetInvisMode()
	end	
	return false
end

function meta:AddPage()
	self:SetPages( self:GetPages() + 1 )
end

function meta:SetPages( am )
	self:SetDTInt( 0, am )
end

function meta:GetPages()
	return self:GetDTInt( 0 )
end

function meta:SetupBattery()
	self:SetDTInt( 1, BATTERY_LIMIT )
end

function meta:BreakBattery( am )
	self:SetDTInt( 1, math.Clamp( self:GetDTInt(1) - am, 0,BATTERY_LIMIT * 2 ))
end

function meta:BatteryDead()
	return self:GetDTInt(1) <= 0
end

function meta:GetMaxPages()
	if SERVER then
		return game.GetWorld():GetDTInt( 0 )
	end
	if CLIENT then
		return Entity(0):GetDTInt( 0 )
	end
end

function meta:UseRTV()

	if CLIENT then return end
	
	if GAMEMODE.RTV_Players[self:SteamID()] then return end
	
	GAMEMODE.RTV_Players[self:SteamID()] = true
	
	if VOTING then return end
	if TOCHANGE then return end

	RTV_NUM = RTV_NUM + 1
	
	local desired = math.Round(#player.GetAll()*0.6)
	
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint("Player "..self:Nick().." wants to rock the vote ("..RTV_NUM.."/"..desired.."). Type !rtv to participate.")
	end
	
	if RTV_NUM >= desired then
		for k,v in pairs(player.GetAll()) do
			v:ChatPrint("Rock the vote has started!")
		end
		GAMEMODE:StartVoting( VOTING_TIME )
	end
	
end

if SERVER then

util.AddNetworkString( "UpdateMaps" )

function meta:UpdateMaps()
	
	if !UPDATE_MAP_LIST then return end
	
	if self.GotUpdatedMaps then return end
	
	self.GotUpdatedMaps = true
	
	net.Start( "UpdateMaps" )
		net.WriteTable( GAMEMODE.Maps )
	net.Send( self )
	
end

end

local meta = FindMetaTable( "Entity" )
if (!meta) then return end

function meta:ResetBones()
	for i=0, self:GetBoneCount() - 1 do
		self:ManipulateBoneScale(i, Vector(1, 1, 1))
		self:ManipulateBoneAngles(i, Angle(0, 0, 0))
		self:ManipulateBonePosition(i, vector_origin)
	end
end

//Useful fix by Deco Da Man to prevent physics from breaking (using the version from zs)
function meta:CollisionRulesChanged()
	if not self.m_OldCollisionGroup then self.m_OldCollisionGroup = self:GetCollisionGroup() end
	self:SetCollisionGroup(self.m_OldCollisionGroup == COLLISION_GROUP_DEBRIS and COLLISION_GROUP_WORLD or COLLISION_GROUP_DEBRIS)
	self:SetCollisionGroup(self.m_OldCollisionGroup)
	self.m_OldCollisionGroup = nil
end