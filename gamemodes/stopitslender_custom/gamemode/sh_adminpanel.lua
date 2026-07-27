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