AddCSLuaFile()

ENT.Type = "point"

if SERVER then

	function ENT:KeyValue(k, v)
				
		k = string.lower(k)
		
		if k == "number" then
		
			v = tonumber(v)
			if not v then return end
			
			self.Number = v

		end

	end

end