AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

util.PrecacheModel("models/slender/sheet.mdl")

ENT.Players = {}

function ENT:Initialize()
	
	
	if CLIENT then 
		self.Taken = false
		return 
	end
	
	local index = #ents.FindByClass("page") + 1
	
	if GAMEMODE.OverrideModel then
		self.Entity:SetModel( GAMEMODE.OverrideModel )
		if GAMEMODE.OverrideSkin then
			self.Entity:SetSkin( GAMEMODE.OverrideSkin )
		end
	else
		if GAMEMODE.PageModels[game.GetMap()] then
			self.Entity:SetModel(GAMEMODE.PageModels[game.GetMap()])
		else
			self.Entity:SetModel("models/slender/sheet.mdl")//
			self.Entity:SetMaterial("models/jason278/slender/sheets/sheet_"..index)
		end
	end

	self.Entity:PhysicsInit(SOLID_VPHYSICS )
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion( false ) 
	end	
	
	self.Players = {}
	
	self.Counted = false
	
end

function ENT:OnRemove()
	
	if SERVER then
		
	end

end

if CLIENT then
function ENT:Draw()
	
	if not self.Taken or !LocalPlayer():Alive() then
		self:DrawModel()
	end

end
end

if SERVER then
	
	function ENT:Use(activator,caller)
		if activator and activator:IsPlayer() and not activator:IsSlenderman() and !table.HasValue(self.Players, activator) then
			
			self.NextUse = self.NextUse or 0
			
			if self.NextUse >= CurTime() then return end
			
			self.NextUse = CurTime() + 0.5
			
			activator:AddPage()
			
			activator:BreakBattery( -13 )
			
			if not FIRST_PAGE then
				FIRST_PAGE = true
			end
			
			if activator:GetPages() > game.GetWorld():GetDTInt( 1 ) then
				
				if game.GetWorld():GetDTInt( 1 ) < 8 then
					SLENDER_TELEPORT_STEP = SLENDER_TELEPORT_STEP
					SLENDER_TELEPORT_FREQUENCY = SLENDER_TELEPORT_FREQUENCY - 0.13
				end
				
				game.GetWorld():SetDTInt( 1, game.GetWorld():GetDTInt( 1 ) + 1 )
			end
			
			activator:SendLua("Entity("..self:EntIndex()..").Taken = true")
			table.insert(self.Players,activator)
			
			if game.GetWorld():GetDTInt( 1 ) >= 3 then
				
				local props = ents.FindByClass("prop_physics")
				
				if #props > 0 then
					props[math.random(1,#props)]:Ignite(900,0)
					props[math.random(1,#props)]:Ignite(900,0)
				end
				
				
			end
			
			//local pages = ents.FindByClass("page")
		
			if activator:GetPages() >= activator:GetMaxPages() then//#pages <= 1
				for k,v in ipairs(player.GetAll()) do
					v:ChatPrint("Humens stole all slenderman's pages! Restarting round...")
				end
				
				ENDROUND = true
			
				timer.Simple(5,function() if ENDROUND then GAMEMODE:RestartRound() end end)
			end
		
			
			//self:Remove()
			
		end
	
	end
	
	ENT.Touch = ENT.Use

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	
end



