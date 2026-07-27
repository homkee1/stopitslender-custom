-- ==========================================
--  Stop it, Slender! - Admin Control Panel
--  Разработка: День 1 (База, Сети и Права)
-- ==========================================

local meta = FindMetaTable("Player")
if meta then
	-- Автоматическое определение Создателя (Host на локальном сервере или SuperAdmin на выделенном)
	function meta:IsSlenderOwner()
		if game.SinglePlayer() then return true end
		if self:IsListenServerHost() then return true end
		if game.IsDedicated() and self:IsSuperAdmin() then return true end
		return false
	end

	-- Проверка на Администратора (Создатель автоматически считается админом)
	function meta:IsSlenderAdmin()
		if self:IsSlenderOwner() then return true end
		if SERVER then
			return SLENDER_ADMINS and SLENDER_ADMINS[self:SteamID64()] == true
		else
			return self:GetNWBool("IsSlenderAdmin", false)
		end
	end
end

if SERVER then
	-- Инициализация глобальных переменных баланса людей по умолчанию
	SetGlobalInt("slender_walk_speed", 125)
	SetGlobalInt("slender_sprint_speed", 190)
	SetGlobalFloat("slender_stamina_drain", 10)
	SetGlobalFloat("slender_stamina_regen", 1)
	SetGlobalInt("slender_exhausted_time", 10)
	SetGlobalInt("slender_jump_power", 160)

	-- Новые переменные регенерации рассудка и эффектов страниц (День 3 - Переработка)
	SetGlobalBool("slender_sanity_regen", true)
	SetGlobalBool("slender_sanity_regen_far", true)
	SetGlobalBool("slender_sanity_regen_light", true)
	SetGlobalInt("slender_page_restore_sanity", 15)
	SetGlobalInt("slender_page_restore_battery", 30)

	-- Дополнительные переменные батареи и паники (День 3 - Расширение)
	SetGlobalInt("slender_battery_limit", 100)
	SetGlobalFloat("slender_battery_drain", 1.0)
	SetGlobalFloat("slender_battery_recharge", 0.1)
	SetGlobalInt("slender_battery_lockout", 6)
	SetGlobalInt("slender_battery_overcharge", 150)
	SetGlobalFloat("slender_sanity_speed_coeff", 0.5)

	-- Системные переменные систем RTV, AFK и конфигурационного файла (День 4)
	SetGlobalBool("slender_rtv_enabled", true)
	SetGlobalBool("slender_afk_enabled", true)
	SetGlobalBool("slender_config_use", true)
	SetGlobalBool("slender_config_autosave", false)

	-- Глобальные переменные баланса Слендермена (Бот и Игрок)
	SetGlobalInt("slender_bot_teleport_step", 90)
	SetGlobalFloat("slender_bot_teleport_freq", 1.35)
	SetGlobalInt("slender_bot_stuck_dist", 60)
	SetGlobalInt("slender_bot_attack_dist", 650)
	SetGlobalInt("slender_bot_damage_dist", 650)

	-- Дефолтные эталонные значения для быстрого сброса
	SLENDER_BALANCE_DEFAULTS = {
		slender_walk_speed = 125,
		slender_sprint_speed = 190,
		slender_stamina_drain = 10,
		slender_stamina_regen = 1,
		slender_exhausted_time = 10,
		slender_jump_power = 160,
		slender_sanity_regen = true,
		slender_sanity_regen_far = true,
		slender_sanity_regen_light = true,
		slender_page_restore_sanity = 15,
		slender_page_restore_battery = 30,
		slender_battery_limit = 100,
		slender_battery_drain = 1.0,
		slender_battery_recharge = 0.1,
		slender_battery_lockout = 6,
		slender_battery_overcharge = 150,
		slender_sanity_speed_coeff = 0.5,
		slender_rtv_enabled = true,
		slender_afk_enabled = true,
		slender_config_use = true,
		slender_config_autosave = false,
		slender_bot_teleport_step = 90,
		slender_bot_teleport_freq = 1.35,
		slender_bot_stuck_dist = 60,
		slender_bot_attack_dist = 650,
		slender_bot_damage_dist = 650
	}

	util.AddNetworkString("SlenderAdminSync")

	SLENDER_ADMINS = SLENDER_ADMINS or {}

	-- Загрузка администраторов из JSON файла
	local function LoadAdmins()
		if file.Exists("slender_admins.json", "DATA") then
			local data = file.Read("slender_admins.json", "DATA")
			SLENDER_ADMINS = util.JSONToTable(data) or {}
		else
			SLENDER_ADMINS = {}
		end
	end

	-- Сохранение текущих настроек в JSON-файл
	function SaveSlenderConfig()
		local cfg = {}
		for k, _ in pairs(SLENDER_BALANCE_DEFAULTS) do
			if string.find(k, "enabled") or string.find(k, "regen") or string.find(k, "use") or string.find(k, "autosave") then
				cfg[k] = GetGlobalBool(k)
			elseif k == "slender_stamina_drain" or k == "slender_stamina_regen" or k == "slender_battery_drain" or k == "slender_battery_recharge" or k == "slender_sanity_speed_coeff" then
				cfg[k] = GetGlobalFloat(k)
			else
				cfg[k] = GetGlobalInt(k)
			end
		end
		file.Write("slender_server_config.json", util.TableToJSON(cfg))
	end

	-- Загрузка настроек из JSON-файла
	function LoadSlenderConfig()
		if not GetGlobalBool("slender_config_use", true) then return end

		if file.Exists("slender_server_config.json", "DATA") then
			local data = file.Read("slender_server_config.json", "DATA")
			local cfg = util.JSONToTable(data)
			if cfg then
				for k, v in pairs(cfg) do
					if SLENDER_BALANCE_DEFAULTS[k] ~= nil then
						if string.find(k, "enabled") or string.find(k, "regen") or string.find(k, "use") or string.find(k, "autosave") then
							SetGlobalBool(k, tobool(v))
						elseif k == "slender_stamina_drain" or k == "slender_stamina_regen" or k == "slender_battery_drain" or k == "slender_battery_recharge" or k == "slender_sanity_speed_coeff" then
							SetGlobalFloat(k, tonumber(v))
						else
							SetGlobalInt(k, math.Round(tonumber(v)))
						end
					end
				end
			end
		end
	end

	-- Сброс настроек до дефолтных значений мода и перезапись файла
	function ResetSlenderConfig()
		for k, v in pairs(SLENDER_BALANCE_DEFAULTS) do
			if string.find(k, "enabled") or string.find(k, "regen") or string.find(k, "use") or string.find(k, "autosave") then
				SetGlobalBool(k, v)
			elseif k == "slender_stamina_drain" or k == "slender_stamina_regen" or k == "slender_battery_drain" or k == "slender_battery_recharge" or k == "slender_sanity_speed_coeff" then
				SetGlobalFloat(k, v)
			else
				SetGlobalInt(k, v)
			end
		end

		if file.Exists("slender_server_config.json", "DATA") then
			file.Delete("slender_server_config.json")
		end

		-- Мгновенно применяем дефолтные скорости выживших на сервере
		for _, p in ipairs(player.GetAll()) do
			if IsValid(p) and p:Alive() and p:Team() == TEAM_HUMENS then
				p:SetWalkSpeed(125)
				p:SetRunSpeed(190)
				p:SetJumpPower(160)
			end
		end
	end

	hook.Add("Initialize", "SlenderServerConfigLoad", function()
		timer.Simple(1, function()
			LoadSlenderConfig()
		end)
	end)

	-- Сохранение администраторов в JSON файл
	local function SaveAdmins()
		file.Write("slender_admins.json", util.TableToJSON(SLENDER_ADMINS))
	end

	-- Синхронизация данных с клиентами
	local function SyncAdmins(ply)
		net.Start("SlenderAdminSync")
			net.WriteTable(SLENDER_ADMINS)
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end

		-- Обновление сетевой переменной для быстрой проверки на клиенте
		for _, p in ipairs(player.GetAll()) do
			p:SetNWBool("IsSlenderAdmin", SLENDER_ADMINS[p:SteamID64()] == true)
		end
	end

	hook.Add("Initialize", "SlenderAdminLoad", function()
		LoadAdmins()
	end)

	hook.Add("PlayerInitialSpawn", "SlenderAdminSpawnSync", function(ply)
		timer.Simple(1, function()
			if IsValid(ply) then
				SyncAdmins(ply)
			end
		end)
	end)
end

if SERVER then
	util.AddNetworkString("SlenderAdminCommand")

	net.Receive("SlenderAdminCommand", function(len, ply)
		if not IsValid(ply) or not ply:IsSlenderAdmin() then return end

		local cmd = net.ReadString()

		-- Обработка изменения параметров систем конфигурации
		if cmd == "update_config_bool" then
			local varName = net.ReadString()
			local varVal = net.ReadBool()

			local allowed = {
				slender_config_use = true,
				slender_config_autosave = true
			}

			if allowed[varName] then
				SetGlobalBool(varName, varVal)
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " изменил системный параметр " .. varName .. " на " .. (varVal and "ВКЛ" or "ВЫКЛ") .. ".")
				
				-- Если мы включили использование сохраненных настроек, пробуем их прочесть
				if varName == "slender_config_use" and varVal then
					LoadSlenderConfig()
				-- Если мы выключили использование конфига, временно сбрасываем параметры до дефолта
				elseif varName == "slender_config_use" and not varVal then
					ResetSlenderConfig()
					SetGlobalBool("slender_config_use", false) -- оставляем флаг использования выключенным
				end

				-- Автоматическая перезапись текущего состояния при включении автосохранения
				if GetGlobalBool("slender_config_use", true) and GetGlobalBool("slender_config_autosave", false) then
					SaveSlenderConfig()
				end
			end
			return
		-- Обработка принудительного сброса конфигурации
		elseif cmd == "reset_config" then
			ResetSlenderConfig()
			PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " полностью сбросил файл конфигурации и восстановил эталонные параметры мода.")
			return
		end

		-- Логика управления администраторами (Только для Создателя)
		if cmd == "add_admin" or cmd == "remove_admin" then
			if not ply:IsSlenderOwner() then 
				ply:ChatPrint("[Slender] У вас нет прав Создателя для управления ролями!")
				return 
			end

			local targetSteam64 = net.ReadString()
			if not targetSteam64 or targetSteam64 == "" or string.len(targetSteam64) < 15 then return end

			if cmd == "add_admin" then
				SLENDER_ADMINS[targetSteam64] = true
				ply:ChatPrint("[Slender] Игрок " .. targetSteam64 .. " успешно назначен администратором.")
			else
				SLENDER_ADMINS[targetSteam64] = nil
				ply:ChatPrint("[Slender] Игрок " .. targetSteam64 .. " удален из списка администраторов.")
			end

			SaveAdmins()
			SyncAdmins()
		elseif cmd == "update_balance_var" then
			local varName = net.ReadString()
			local varVal = net.ReadFloat()

			local allowed = {
				slender_walk_speed = true,
				slender_sprint_speed = true,
				slender_stamina_drain = true,
				slender_stamina_regen = true,
				slender_exhausted_time = true,
				slender_jump_power = true,
				slender_page_restore_sanity = true,
				slender_page_restore_battery = true,
				slender_battery_limit = true,
				slender_battery_drain = true,
				slender_battery_recharge = true,
				slender_battery_lockout = true,
				slender_battery_overcharge = true,
				slender_sanity_speed_coeff = true,
				slender_bot_teleport_step = true,
				slender_bot_teleport_freq = true,
				slender_bot_stuck_dist = true,
				slender_bot_attack_dist = true,
				slender_bot_damage_dist = true
			}

			if allowed[varName] then
				if varName == "slender_stamina_drain" or varName == "slender_stamina_regen" or varName == "slender_battery_drain" or varName == "slender_battery_recharge" or varName == "slender_sanity_speed_coeff" or varName == "slender_bot_teleport_freq" then
					SetGlobalFloat(varName, varVal)
				else
					SetGlobalInt(varName, math.Round(varVal))
				end

				-- Мгновенно применяем скорость и высоту прыжка для всех живых людей на сервере
				if varName == "slender_jump_power" or varName == "slender_walk_speed" or varName == "slender_sprint_speed" then
					for _, p in ipairs(player.GetAll()) do
						if IsValid(p) and p:Alive() and p:Team() == TEAM_HUMENS then
							p:SetWalkSpeed(GetGlobalInt("slender_walk_speed", 125))
							p:SetRunSpeed(GetGlobalInt("slender_sprint_speed", 190))
							p:SetJumpPower(GetGlobalInt("slender_jump_power", 160))
						end
					end
				end

				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " изменил параметр " .. varName .. " на " .. varVal .. ".")

				-- Обработка автосохранения
				if GetGlobalBool("slender_config_use", true) and GetGlobalBool("slender_config_autosave", false) then
					SaveSlenderConfig()
				end
			end
		elseif cmd == "update_balance_bool" then
			local varName = net.ReadString()
			local varVal = net.ReadBool()

			local allowed = {
				slender_sanity_regen = true,
				slender_sanity_regen_far = true,
				slender_sanity_regen_light = true,
				slender_rtv_enabled = true,
				slender_afk_enabled = true
			}

			if allowed[varName] then
				SetGlobalBool(varName, varVal)
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " изменил параметр " .. varName .. " на " .. (varVal and "ВКЛ" or "ВЫКЛ") .. ".")

				-- Обработка автосохранения
				if GetGlobalBool("slender_config_use", true) and GetGlobalBool("slender_config_autosave", false) then
					SaveSlenderConfig()
				end
			end
		elseif cmd == "restart_round" or cmd == "force_victory_humans" or cmd == "force_victory_slender" then
			if cmd == "restart_round" then
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " перезапустил раунд.")
				GAMEMODE:RestartRound()
			elseif cmd == "force_victory_humans" then
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " объявил победу Людей! Перезапуск раунда...")
				ENDROUND = true
				timer.Simple(5, function() if ENDROUND then GAMEMODE:RestartRound() end end)
			elseif cmd == "force_victory_slender" then
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " объявил победу Слендермена! Перезапуск раунда...")
				ENDROUND = true
				timer.Simple(5, function() if ENDROUND then GAMEMODE:RestartRound() end end)
			end
		elseif cmd == "spawn_bot" then
			local ent = ents.Create("slendy")
			ent:SetPos(GAMEMODE:GetSlendermanSpawn() or vector_origin)
			ent:Spawn()
			ent:Activate()
			PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " заспавнил бота Слендермена.")
		elseif cmd == "player_kill" or cmd == "player_respawn" or cmd == "player_slender" or cmd == "player_spec" or cmd == "player_heal" or cmd == "player_battery" or cmd == "player_addpage" or cmd == "player_removepage" then
			local target = net.ReadEntity()
			if not IsValid(target) or (not target:IsPlayer() and target:GetClass() ~= "slendy") then return end

			if cmd == "player_kill" then
				if target:IsPlayer() then
					target:Kill()
					PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " убил игрока " .. target:Nick() .. ".")
				else
					PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " уничтожил бота Слендермена #" .. target:EntIndex() .. ".")
					target:Remove()
				end
			elseif cmd == "player_respawn" and target:IsPlayer() then
				target:KillSilent()
				target:SetTeam(TEAM_HUMENS)
				target:Spawn()
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " возродил игрока " .. target:Nick() .. " за Выживших.")
			elseif cmd == "player_slender" and target:IsPlayer() then
				target:KillSilent()
				target:SetTeam(TEAM_SLENDER)
				target:Spawn()
				game.GetWorld():SetDTEntity(2, target)
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " сделал игрока " .. target:Nick() .. " Слендерменом.")
			elseif cmd == "player_spec" and target:IsPlayer() then
				target:KillSilent()
				target:SetTeam(TEAM_SPECTATOR)
				target:Spawn()
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " перевел игрока " .. target:Nick() .. " в зрители.")
			elseif cmd == "player_heal" and target:IsPlayer() then
				target:SetHealth(100)
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " вылечил игрока " .. target:Nick() .. ".")
			elseif cmd == "player_battery" and target:IsPlayer() then
				target:SetupBattery()
				PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " полностью зарядил батарею игроку " .. target:Nick() .. ".")
			elseif cmd == "player_addpage" and target:IsPlayer() then
				local current = target:GetPages()
				local max = target:GetMaxPages() or 8
				if current < max then
					target:SetPages(current + 1)
					
					-- Активируем ботов Слендеров, если это первая полученная записка
					if not FIRST_PAGE then
						FIRST_PAGE = true
					end
					
					-- Синхронизируем счетчик собранных страниц DTInt(1) и скорость телепорта бота
					if target:GetPages() > game.GetWorld():GetDTInt(1) then
						if game.GetWorld():GetDTInt(1) < 8 then
							SLENDER_TELEPORT_FREQUENCY = math.Clamp(SLENDER_TELEPORT_FREQUENCY - 0.13, 0.1, 5)
						end
						game.GetWorld():SetDTInt(1, game.GetWorld():GetDTInt(1) + 1)
					end
					
					-- Эффект поджога случайных физических пропов (если собрано 3 или более страниц)
					if game.GetWorld():GetDTInt(1) >= 3 then
						local props = ents.FindByClass("prop_physics")
						if #props > 0 then
							props[math.random(1,#props)]:Ignite(900,0)
							props[math.random(1,#props)]:Ignite(900,0)
						end
					end
					
					PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " добавил собранную записку игроку " .. target:Nick() .. " (" .. target:GetPages() .. "/" .. max .. ").")
					
					-- Проверяем условия победы (если игрок собрал лимит)
					if target:GetPages() >= max then
						for k, v in ipairs(player.GetAll()) do
							v:ChatPrint("Humens stole all slenderman's pages! Restarting round...")
						end
						ENDROUND = true
						timer.Simple(5, function() if ENDROUND then GAMEMODE:RestartRound() end end)
					end
				end
			elseif cmd == "player_removepage" and target:IsPlayer() then
				local current = target:GetPages()
				if current > 0 then
					target:SetPages(current - 1)
					
					-- Синхронизируем счетчик собранных страниц в меньшую сторону
					if game.GetWorld():GetDTInt(1) > 0 then
						game.GetWorld():SetDTInt(1, math.max(0, game.GetWorld():GetDTInt(1) - 1))
						SLENDER_TELEPORT_FREQUENCY = math.Clamp(SLENDER_TELEPORT_FREQUENCY + 0.13, 0.1, DEFAULT_SLENDER_TELEPORT_FREQUENCY)
					end
					
					-- Если счетчик собранных страниц упал до нуля, деактивируем телепорты ботов-Слендеров
					if game.GetWorld():GetDTInt(1) <= 0 then
						FIRST_PAGE = false
					end
					
					PrintMessage(HUD_PRINTTALK, "[Slender] Администратор " .. ply:Nick() .. " забрал собранную записку у игрока " .. target:Nick() .. " (" .. target:GetPages() .. "/" .. (target:GetMaxPages() or 8) .. ").")
				end
			end
		end
	end)
end

if CLIENT then
	SLENDER_ADMINS = SLENDER_ADMINS or {}

	net.Receive("SlenderAdminSync", function()
		SLENDER_ADMINS = net.ReadTable()
	end)

	-- Регистрация кастомного слайдера с поддержкой сверх-лимитного ввода
	local PANEL = {}
	function PANEL:Init()
		self:SetPaintBackground(false) -- Убираем унылый дефолтный серый фон панели, делая строки прозрачными

		self.Label = vgui.Create("DLabel", self)
		self.Label:Dock(LEFT)
		self.Label:SetWidth(250)
		self.Label:SetFont("Tahoma_lines18")
		self.Label:SetTextColor(SlenderUI.ColorText)

		self.TextEntry = vgui.Create("DTextEntry", self)
		self.TextEntry:Dock(RIGHT)
		self.TextEntry:SetWidth(60)
		self.TextEntry:SetFont("Tahoma_lines18")
		self.TextEntry:SetTextColor(SlenderUI.ColorText)
		self.TextEntry:SetNumeric(true) -- Запрещаем ввод любых символов, кроме чисел
		self.TextEntry.Paint = function(s, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15, 255)) -- Матовый черный фон для поля ввода
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawOutlinedRect(0, 0, w, h)
			
			-- Главное исправление: заставляем движок рисовать белый вводимый текст поверх темного поля
			s:DrawTextEntryText(SlenderUI.ColorText, SlenderUI.ColorTextMuted, SlenderUI.ColorText)
		end

		self.Slider = vgui.Create("DSlider", self)
		self.Slider:Dock(FILL)
		self.Slider:DockMargin(10, 0, 10, 0)
		self.Slider.Paint = function(s, w, h)
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawLine(0, h/2, w, h/2)
		end
		self.Slider.Knob.Paint = function(s, w, h)
			draw.RoundedBox(0, 0, 0, w, h, SlenderUI.ColorAccentRed)
		end

		-- Финальная принудительная отправка точного значения на сервер при отпускании мыши
		local old_released = self.Slider.OnMouseReleased
		self.Slider.OnMouseReleased = function(s, mcode)
			if old_released then old_released(s, mcode) end
			
			local fraction = s:GetSlideX()
			local val = self.Min + fraction * (self.Max - self.Min)
			if self.Decimals == 0 then
				val = math.Round(val)
			else
				val = math.Round(val, self.Decimals)
			end
			self.Value = val
			self.TextEntry:SetText(tostring(val))
			if self.OnValueChanged then
				self:OnValueChanged(val)
			end
		end

		self.Min = 0
		self.Max = 100
		self.Decimals = 0
		self.Value = 0
		self.IsManualChange = false -- Инициализируем флаг обхода рекурсии при ручном вводе

		self.Slider.OnValueChanged = function(s, x, y)
			-- Если сработал флаг ручного ввода, пропускаем пересчет по координате слайдера
			if self.IsManualChange then
				self.IsManualChange = false
				return
			end

			local fraction = x
			local val = self.Min + fraction * (self.Max - self.Min)
			if self.Decimals == 0 then
				val = math.Round(val)
			else
				val = math.Round(val, self.Decimals)
			end
			self.Value = val
			self.TextEntry:SetText(tostring(val))
			if self.OnValueChanged then
				self:OnValueChanged(val)
			end
		end

		-- Сохранение значения при нажатии клавиши Enter
		self.TextEntry.OnEnter = function(s)
			local val = tonumber(s:GetText())
			if not val then return end
			self.Value = val
			local frac = math.Clamp((val - self.Min) / (self.Max - self.Min), 0, 1)
			
			self.IsManualChange = true -- Активируем блокировку перед сдвигом ползунка
			self.Slider:SetSlideX(frac)
			
			if self.OnValueChanged then
				self:OnValueChanged(val)
			end
		end

		-- Удобство: автосохранение значения при клике в любое другое место экрана (потеря фокуса)
		self.TextEntry.OnLoseFocus = function(s)
			local val = tonumber(s:GetText())
			if not val then return end
			self.Value = val
			local frac = math.Clamp((val - self.Min) / (self.Max - self.Min), 0, 1)
			
			self.IsManualChange = true -- Активируем блокировку перед сдвигом ползунка
			self.Slider:SetSlideX(frac)
			
			if self.OnValueChanged then
				self:OnValueChanged(val)
			end
		end
	end
	function PANEL:SetUp(label, varName, minVal, maxVal, decimals)
		self.Min = minVal
		self.Max = maxVal
		self.Decimals = decimals
		self.Label:SetText(label)
		
		local val = decimals > 0 and GetGlobalFloat(varName, minVal) or GetGlobalInt(varName, minVal)
		self.Value = val
		self.TextEntry:SetText(tostring(val))
		local frac = math.Clamp((val - minVal) / (maxVal - minVal), 0, 1)
		
		self.IsManualChange = true -- Блокируем сброс при первичной загрузке значений из файла настроек
		self.Slider:SetSlideX(frac)
	end
	function PANEL:PerformLayout(w, h)
	end
	vgui.Register("SlenderNumSlider", PANEL, "DPanel")

	-- ТАБЛИЦА СТИЛЕЙ (Вариант Б)
	SlenderUI = SlenderUI or {}
	SlenderUI.ColorBg = Color(16, 16, 16, 245)         -- Темный матовый фон
	SlenderUI.ColorBorder = Color(45, 45, 45, 255)       -- Границы элементов
	SlenderUI.ColorAccentRed = Color(185, 20, 20, 255)   -- Красный неон (Слендер)
	SlenderUI.ColorAccentBlue = Color(20, 105, 185, 255) -- Синий неон (Выжившие)
	SlenderUI.ColorBtn = Color(28, 28, 28, 255)          -- Кнопка по умолчанию
	SlenderUI.ColorBtnHover = Color(48, 48, 48, 255)     -- Кнопка при наведении
	SlenderUI.ColorText = Color(225, 225, 225, 255)      -- Светлый текст
	SlenderUI.ColorTextMuted = Color(140, 140, 140, 255) -- Приглушенный текст

	-- Кастомный Paint для Окна
	function SlenderUI.PaintFrame(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, SlenderUI.ColorBg)
		surface.SetDrawColor(SlenderUI.ColorBorder)
		surface.DrawOutlinedRect(0, 0, w, h)

		-- Верхнее неоновое свечение (акцентная полоса)
		surface.SetDrawColor(SlenderUI.ColorAccentRed)
		surface.DrawRect(0, 0, w, 4)

		-- Линия под шапкой окна
		surface.SetDrawColor(SlenderUI.ColorBorder)
		surface.DrawLine(0, 24, w, 24)
	end

	-- Кастомный Paint для Кнопок
	function SlenderUI.PaintButton(self, w, h)
		local bg = SlenderUI.ColorBtn
		if self:IsHovered() then
			bg = SlenderUI.ColorBtnHover
		end
		draw.RoundedBox(0, 0, 0, w, h, bg)
		surface.SetDrawColor(SlenderUI.ColorBorder)
		surface.DrawOutlinedRect(0, 0, w, h)

		-- Боковой неоновый маркер при наведении
		if self:IsHovered() then
			surface.SetDrawColor(SlenderUI.ColorAccentRed)
			surface.DrawRect(0, 0, 3, h)
		end
	end

	-- Кастомный Paint для Вкладок
	function SlenderUI.PaintTab(self, w, h)
		local isActive = self:GetPropertySheet():GetActiveTab() == self
		local bg = isActive and SlenderUI.ColorBg or Color(11, 11, 11, 255)
		draw.RoundedBox(0, 0, 0, w, h, bg)
		surface.SetDrawColor(SlenderUI.ColorBorder)
		surface.DrawOutlinedRect(0, 0, w, h)

		if isActive then
			surface.SetDrawColor(SlenderUI.ColorAccentBlue)
			surface.DrawRect(0, 0, w, 3)
		end
	end
end

if CLIENT then
	-- Инициализация и открытие панели
	function SlenderUI.OpenMenu()
		if IsValid(SlenderUI.Frame) then SlenderUI.Frame:Remove() end

		local frame = vgui.Create("DFrame")
		frame:SetSize(800, 500)
		frame:SetTitle("Stop it, Slender! - Панель Управления")
		frame:Center()
		frame:MakePopup()
		frame.Paint = SlenderUI.PaintFrame

		SlenderUI.Frame = frame

		-- Контейнер для вкладок
		local sheet = vgui.Create("DPropertySheet", frame)
		sheet:Dock(FILL)
		sheet:DockMargin(5, 10, 5, 5)
		sheet.Paint = function(self, w, h)
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		-- Переопределяем поведение вкладок для применения стиля Option B
		local old_active = sheet.SetActiveTab
		sheet.SetActiveTab = function(self, tab)
			old_active(self, tab)
			for _, t in ipairs(self:GetItems()) do
				t.Tab.Paint = SlenderUI.PaintTab
				t.Tab:SetTextColor(SlenderUI.ColorText)
			end
		end

		-- Вкладка управления раундом (День 2)
		local roundPanel = vgui.Create("DPanel", sheet)
		roundPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 255))
		end

		local roundTitle = vgui.Create("DLabel", roundPanel)
		roundTitle:SetText("Управление текущим раундом")
		roundTitle:SetFont("Tahoma_lines23")
		roundTitle:SetTextColor(SlenderUI.ColorText)
		roundTitle:Dock(TOP)
		roundTitle:DockMargin(15, 15, 15, 10)
		roundTitle:SizeToContents()

		local function CreateRoundButton(text, cmd)
			local btn = vgui.Create("DButton", roundPanel)
			btn:SetText(text)
			btn:SetTextColor(SlenderUI.ColorText)
			btn:SetFont("Tahoma_lines18")
			btn:Dock(TOP)
			btn:DockMargin(15, 5, 15, 5)
			btn:SetHeight(40)
			btn.Paint = SlenderUI.PaintButton
			btn.DoClick = function()
				net.Start("SlenderAdminCommand")
					net.WriteString(cmd)
				net.SendToServer()
			end
		end

		CreateRoundButton("Перезапустить раунд", "restart_round")
		CreateRoundButton("Объявить победу Выживших (Людей)", "force_victory_humans")
		CreateRoundButton("Объявить победу Слендермена", "force_victory_slender")

		sheet:AddSheet("Раунд", roundPanel, "icon16/time.png")

		-- Вкладка списка игроков (День 2)
		local playersPanel = vgui.Create("DPanel", sheet)
		playersPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 255))
		end

		local actionPanel = vgui.Create("DPanel", playersPanel)
		actionPanel:SetWidth(240)
		actionPanel:Dock(RIGHT)
		actionPanel:DockMargin(5, 5, 5, 5)
		actionPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15, 255))
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local actionTitle = vgui.Create("DLabel", actionPanel)
		actionTitle:SetText("Действия над игроком")
		actionTitle:SetFont("Tahoma_lines18")
		actionTitle:SetTextColor(SlenderUI.ColorTextMuted)
		actionTitle:Dock(TOP)
		actionTitle:DockMargin(10, 10, 10, 10)
		actionTitle:SetContentAlignment(5)
		actionTitle:SizeToContents()

		local playerList = vgui.Create("DListView", playersPanel)
		playerList:Dock(FILL)
		playerList:DockMargin(5, 5, 5, 5)
		playerList:SetMultiSelect(false)
		playerList:AddColumn("Никнейм")
		playerList:AddColumn("Команда")
		playerList:AddColumn("Здоровье")

		playerList.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(12, 12, 12, 255))
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local function UpdatePlayerList()
			playerList:Clear()
			for _, p in ipairs(player.GetAll()) do
				local tName = "Зритель"
				if p:Team() == TEAM_HUMENS then tName = "Выживший"
				elseif p:Team() == TEAM_SLENDER then tName = "Слендер" end

				local line = playerList:AddLine(p:Nick(), tName, p:Alive() and p:Health() or "Мертв")
				line.PlayerEntity = p

				for _, col in ipairs(line.Columns) do
					col:SetTextColor(SlenderUI.ColorText)
				end
				line.Paint = function(self, w, h)
					if self:IsSelected() then
						draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 255))
					else
						draw.RoundedBox(0, 0, 0, w, h, Color(18, 18, 18, 255))
					end
				end
			end
			for _, b in ipairs(ents.FindByClass("slendy")) do
				local line = playerList:AddLine("Бот Слендер #" .. b:EntIndex(), "Слендер (Бот)", "10000")
				line.PlayerEntity = b

				for _, col in ipairs(line.Columns) do
					col:SetTextColor(SlenderUI.ColorAccentRed)
				end
				line.Paint = function(self, w, h)
					if self:IsSelected() then
						draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 255))
					else
						draw.RoundedBox(0, 0, 0, w, h, Color(18, 18, 18, 255))
					end
				end
			end
		end
		UpdatePlayerList()

		local actionButtons = {}
		local selectedPlayer = nil

		local function CreatePlayerActionButton(text, cmd)
			local btn = vgui.Create("DButton", actionPanel)
			btn:SetText(text)
			btn:SetTextColor(SlenderUI.ColorText)
			btn:SetFont("Tahoma_lines18")
			btn:Dock(TOP)
			btn:DockMargin(10, 4, 10, 4)
			btn:SetHeight(32)
			btn:SetEnabled(false)
			btn.Paint = function(self, w, h)
				if not self:IsEnabled() then
					draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 255))
					surface.SetDrawColor(Color(35, 35, 35, 255))
					surface.DrawOutlinedRect(0, 0, w, h)
					self:SetTextColor(SlenderUI.ColorTextMuted)
				else
					SlenderUI.PaintButton(self, w, h)
					self:SetTextColor(SlenderUI.ColorText)
				end
			end
			btn.DoClick = function()
				if IsValid(selectedPlayer) then
					net.Start("SlenderAdminCommand")
						net.WriteString(cmd)
						net.WriteEntity(selectedPlayer)
					net.SendToServer()

					timer.Simple(0.1, UpdatePlayerList)
				end
			end
			table.insert(actionButtons, btn)
		end

		CreatePlayerActionButton("Убить", "player_kill")
		CreatePlayerActionButton("Возродить за людей", "player_respawn")
		CreatePlayerActionButton("Сделать Слендером", "player_slender")
		CreatePlayerActionButton("Перевести в зрители", "player_spec")
		CreatePlayerActionButton("Вылечить", "player_heal")
		CreatePlayerActionButton("Зарядить батарею", "player_battery")
		CreatePlayerActionButton("Добавить собр. записку (+1)", "player_addpage")
		CreatePlayerActionButton("Забрать собр. записку (-1)", "player_removepage")

		local spawnBotBtn = vgui.Create("DButton", actionPanel)
		spawnBotBtn:SetText("Заспавнить бота Слендермена")
		spawnBotBtn:SetTextColor(SlenderUI.ColorText)
		spawnBotBtn:SetFont("Tahoma_lines18")
		spawnBotBtn:Dock(BOTTOM)
		spawnBotBtn:DockMargin(10, 10, 10, 10)
		spawnBotBtn:SetHeight(40)
		spawnBotBtn.Paint = SlenderUI.PaintButton
		spawnBotBtn.DoClick = function()
			net.Start("SlenderAdminCommand")
				net.WriteString("spawn_bot")
			net.SendToServer()
		end

		playerList.OnRowSelected = function(panel, rowIndex, row)
			selectedPlayer = row.PlayerEntity
			local isBot = IsValid(selectedPlayer) and selectedPlayer:GetClass() == "slendy"
			for _, btn in ipairs(actionButtons) do
				if isBot then
					-- Для ботов разрешена только кнопка "Убить"
					btn:SetEnabled(btn:GetText() == "Убить")
				else
					btn:SetEnabled(IsValid(selectedPlayer))
				end
			end
		end

		sheet:AddSheet("Игроки", playersPanel, "icon16/group.png")

		-- Вкладка настроек баланса людей (День 3)
		local balancePanel = vgui.Create("DPanel", sheet)
		balancePanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 255))
		end

		local balanceScroll = vgui.Create("DScrollPanel", balancePanel)
		balanceScroll:Dock(FILL)
		balanceScroll:DockMargin(10, 10, 10, 10)

		local function CreateSliderSetting(label, varName, minVal, maxVal, decimals)
			local slider = vgui.Create("SlenderNumSlider", balanceScroll)
			slider:Dock(TOP)
			slider:DockMargin(10, 10, 10, 10)
			slider:SetHeight(40)
			slider:SetUp(label, varName, minVal, maxVal, decimals)

			slider.OnValueChanged = function(self, value)
				self.NextUpdate = self.NextUpdate or 0
				if self.NextUpdate < RealTime() then
					net.Start("SlenderAdminCommand")
						net.WriteString("update_balance_var")
						net.WriteString(varName)
						net.WriteFloat(value)
					net.SendToServer()
					self.NextUpdate = RealTime() + 0.1
				end
			end
		end

		local function CreateCheckboxSetting(label, varName)
			local panel = vgui.Create("DPanel", balanceScroll)
			panel:Dock(TOP)
			panel:DockMargin(10, 5, 10, 5)
			panel:SetHeight(30)
			panel.Paint = function(self, w, h) end

			local chk = vgui.Create("DCheckBoxLabel", panel)
			chk:Dock(FILL)
			chk:SetText(label)
			chk:SetFont("Tahoma_lines18")
			chk:SetTextColor(SlenderUI.ColorText)
			chk:SetValue(GetGlobalBool(varName, true))
			
			chk.OnChange = function(self, val)
				net.Start("SlenderAdminCommand")
					net.WriteString("update_balance_bool")
					net.WriteString(varName)
					net.WriteBool(val)
				net.SendToServer()
			end
		end

		-- Верхняя панель конфигурации настроек (День 4)
		local configHeader = vgui.Create("DLabel", balanceScroll)
		configHeader:SetText("Управление файлом конфигурации")
		configHeader:SetFont("Tahoma_lines18")
		configHeader:SetTextColor(SlenderUI.ColorAccentBlue)
		configHeader:Dock(TOP)
		configHeader:DockMargin(10, 10, 10, 5)

		local configPanel = vgui.Create("DPanel", balanceScroll)
		configPanel:Dock(TOP)
		configPanel:DockMargin(10, 0, 10, 15)
		configPanel:SetHeight(115)
		configPanel.Paint = function(s, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15, 255))
			surface.SetDrawColor(SlenderUI.ColorBorder)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local chkUse = vgui.Create("DCheckBoxLabel", configPanel)
		chkUse:SetPos(15, 15)
		chkUse:SetText("Использовать сохраненные настройки")
		chkUse:SetFont("Tahoma_lines18")
		chkUse:SetTextColor(SlenderUI.ColorText)
		chkUse:SetValue(GetGlobalBool("slender_config_use", true))
		chkUse.OnChange = function(s, val)
			net.Start("SlenderAdminCommand")
				net.WriteString("update_config_bool")
				net.WriteString("slender_config_use")
				net.WriteBool(val)
			net.SendToServer()
		end

		local chkAutosave = vgui.Create("DCheckBoxLabel", configPanel)
		chkAutosave:SetPos(15, 45)
		chkAutosave:SetText("Записывать изменения в файл на лету")
		chkAutosave:SetFont("Tahoma_lines18")
		chkAutosave:SetTextColor(SlenderUI.ColorText)
		chkAutosave:SetValue(GetGlobalBool("slender_config_autosave", false))
		chkAutosave.OnChange = function(s, val)
			net.Start("SlenderAdminCommand")
				net.WriteString("update_config_bool")
				net.WriteString("slender_config_autosave")
				net.WriteBool(val)
			net.SendToServer()
		end

		local btnReset = vgui.Create("DButton", configPanel)
		btnReset:SetPos(15, 75)
		btnReset:SetSize(400, 25)
		btnReset:SetText("Сбросить текущие и сохраненные настройки")
		btnReset:SetTextColor(SlenderUI.ColorText)
		btnReset:SetFont("Tahoma_lines18")
		btnReset.Paint = SlenderUI.PaintButton
		btnReset.DoClick = function()
			Derma_Query("Вы действительно хотите полностью сбросить настройки баланса и конфигурационный файл на сервере?", "Подтверждение сброса", "Да", function()
				net.Start("SlenderAdminCommand")
					net.WriteString("reset_config")
				net.SendToServer()
				timer.Simple(0.5, function()
					if IsValid(SlenderUI.Frame) then
						SlenderUI.OpenMenu() -- перезапускаем меню для переинициализации UI новыми значениями
					end
				end)
			end, "Нет")
		end

		CreateSliderSetting("Скорость обычной ходьбы выживших", "slender_walk_speed", 50, 300, 0)
		CreateSliderSetting("Скорость бега со спринтом", "slender_sprint_speed", 100, 400, 0)
		CreateSliderSetting("Высота прыжка выживших", "slender_jump_power", 50, 400, 0)
		CreateSliderSetting("Скорость траты выносливости (ед. в секунду)", "slender_stamina_drain", 1, 50, 1)
		CreateSliderSetting("Скорость регенерации выносливости (ед. в секунду)", "slender_stamina_regen", 0.1, 10, 2)
		CreateSliderSetting("Длительность штрафа истощения (секунд)", "slender_exhausted_time", 1, 30, 0)

		-- Переключатели регенерации и награды страниц (День 3 - Переработка)
		CreateCheckboxSetting("Разрешить пассивную регенерацию рассудка", "slender_sanity_regen")
		CreateCheckboxSetting("Регенерировать рассудок ТОЛЬКО вдали от Слендера", "slender_sanity_regen_far")
		CreateCheckboxSetting("Регенерировать рассудок ТОЛЬКО при включенном фонарике", "slender_sanity_regen_light")

		-- Системные переключатели сессии (День 4)
		CreateCheckboxSetting("Разрешить запуск голосования RTV игроками (!rtv)", "slender_rtv_enabled")
		CreateCheckboxSetting("Активность AFK-контроля (убийство неактивных через 100 сек.)", "slender_afk_enabled")

		CreateSliderSetting("Восстановление рассудка (здоровья) при поднятии страницы", "slender_page_restore_sanity", 0, 100, 0)
		CreateSliderSetting("Заряд фонарика камеры (%) при поднятии страницы", "slender_page_restore_battery", 0, 100, 0)

		-- Тонкие настройки фонарика и паники (День 3 - Расширение)
		CreateSliderSetting("Максимальный заряд батареи фонарика", "slender_battery_limit", 50, 200, 0)
		CreateSliderSetting("Скорость разряда фонарика (сек. на 1%)", "slender_battery_drain", 0.1, 5, 1)
		CreateSliderSetting("Скорость зарядки фонарика (сек. на 1%)", "slender_battery_recharge", 0.01, 1, 2)
		CreateSliderSetting("Время блокировки при полном разряде (сек.)", "slender_battery_lockout", 1, 20, 0)
		CreateSliderSetting("Лимит оверчарджа (перезарядки) батареи (%)", "slender_battery_overcharge", 100, 200, 0)
		CreateSliderSetting("Влияние адреналина/паники на скорость (-1..1)", "slender_sanity_speed_coeff", -1, 1, 2)

		-- Настройки Слендермена (Бот и Игрок) (День 4)
		local slenderHeader = vgui.Create("DLabel", balanceScroll)
		slenderHeader:SetText("Настройки баланса Слендермена")
		slenderHeader:SetFont("Tahoma_lines18")
		slenderHeader:SetTextColor(SlenderUI.ColorAccentRed)
		slenderHeader:Dock(TOP)
		slenderHeader:DockMargin(10, 15, 10, 5)

		CreateSliderSetting("Базовый шаг телепортации бота (юнитов)", "slender_bot_teleport_step", 10, 500, 0)
		CreateSliderSetting("Базовая частота телепортации бота (секунд)", "slender_bot_teleport_freq", 0.1, 5.0, 2)
		CreateSliderSetting("Радиус мгновенной смерти выжившего (юнитов)", "slender_bot_stuck_dist", 10, 200, 0)
		CreateSliderSetting("Дистанция атаки Слендера взглядом (юнитов)", "slender_bot_attack_dist", 100, 1500, 0)
		CreateSliderSetting("Дистанция нанесения урона Слендером (юнитов)", "slender_bot_damage_dist", 100, 1500, 0)

		sheet:AddSheet("Баланс", balancePanel, "icon16/wrench.png")

		-- Фоновое автообновление списка игроков каждые 3 секунды для отображения изменений
		timer.Create("SlenderAdminPlayerListRefresh", 3, 0, function()
			if IsValid(frame) then
				UpdatePlayerList()
			else
				timer.Remove("SlenderAdminPlayerListRefresh")
			end
		end)
	end

	-- Консольная команда для вызова админ-панели
	concommand.Add("slender_admin_menu", function()
		if not LocalPlayer():IsSlenderAdmin() then 
			LocalPlayer():ChatPrint("[Slender] У вас нет доступа к админ-панели!")
			return 
		end

		SlenderUI.OpenMenu()
	end)

	-- Открытие панели через чат-команды (!admin или !menu)
	hook.Add("OnPlayerChat", "SlenderAdminChatCommand", function(ply, text, bTeam, bDead)
		if ply == LocalPlayer() and (string.lower(text) == "!admin" or string.lower(text) == "!menu") then
			if LocalPlayer():IsSlenderAdmin() then
				SlenderUI.OpenMenu()
				return true -- Скрываем саму команду из чата, чтобы не спамить
			else
				LocalPlayer():ChatPrint("[Slender] У вас нет доступа к админ-панели!")
				return true
			end
		end
	end)
end