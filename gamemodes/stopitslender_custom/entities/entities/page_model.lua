AddCSLuaFile()

ENT.Type = "point"

if SERVER then

	function ENT:KeyValue(k, v)
				
		k = string.lower(k)
		
		if k == "path" then
		
			v = tostring(v)
			if not v then return end
			
			self.PageModel = v

		end
		
		if k == "skin" then
		
			v = tonumber(v)
			if not v then return end
			
			self.PageSkin = v

		end

	end

end