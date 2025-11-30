--[[
	Triggerbot Module [AirHub] — улучшенная версия для автоматической стрельбы под прицелом
	Совместимо с Xeno executor (mouse1press/release, isbuttondown).
]]

--// Проверки запуска
if not getgenv().AirHub or getgenv().AirHub.Triggerbot then return end

--// Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Переменные
local Aimbot = getgenv().AirHub.Aimbot or { Settings = { LockPart = "Head" }, FOVSettings = { Enabled = true, Amount = 90 } }
local Triggerbot = {
	Settings = {
		Enabled = false,
		FOVSync = true,         -- Синхронизировать FOV с Aimbot
		TeamCheck = true,
		AliveCheck = true,
		WallCheck = true,
		Delay = 50,             -- Задержка перед выстрелом (мс)
		Randomization = 30,     -- Рандомизация (± мс) для реализма
		HoldMode = false,       -- Hold: держать ЛКМ; false: одиночный клик
	},
	LastShot = 0,
	CurrentFOV = 90  -- По умолчанию
}

getgenv().AirHub.Triggerbot = Triggerbot

--// Улучшенная проверка валидности цели (синхронизировано с Aimbot)
local function IsTargetValid(Player)
	if not Player or Player == LocalPlayer then return false end
	if not Player.Character then return false end
	local LockPart = Player.Character:FindFirstChild(Aimbot.Settings.LockPart)
	if not LockPart then return false end

	local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
	if Triggerbot.Settings.AliveCheck and (not Humanoid or Humanoid.Health <= 0) then return false end

	if Triggerbot.Settings.TeamCheck and Player.TeamColor == LocalPlayer.TeamColor then return false end

	-- Улучшенный WallCheck (лучше, чем в базовом: игнорирует локального игрока)
	if Triggerbot.Settings.WallCheck then
		local Origin = Camera.CFrame.Position
		local TargetPos = LockPart.Position
		local Direction = (TargetPos - Origin).Unit * 500
		local RaycastParams = RaycastParams.new()
		RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character or {}}
		local RaycastResult = workspace:Raycast(Origin, Direction, RaycastParams)
		if RaycastResult and not RaycastResult.Instance:IsDescendantOf(Player.Character) then
			return false
		end
	end

	return true
end

--// Проверка цели под прицелом (улучшено: пиксельная точность < 5px)
local function GetTargetUnderCrosshair()
	local MousePos = UserInputService:GetMouseLocation()
	local CurrentFOV = Triggerbot.Settings.FOVSync and (Aimbot.FOVSettings.Enabled and Aimbot.FOVSettings.Amount or 2000) or Triggerbot.CurrentFOV

	for _, Player in ipairs(Players:GetPlayers()) do
		if IsTargetValid(Player) then
			local LockPart = Player.Character:FindFirstChild(Aimbot.Settings.LockPart)
			if LockPart then
				local ScreenPos, OnScreen = Camera:WorldToViewportPoint(LockPart.Position)
				if OnScreen then
					local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
					if Distance <= CurrentFOV and Distance < 5 then  -- Точная проверка под прицелом
						return Player
					end
				end
			end
		end
	end
	return nil
end

--// Основной цикл (RenderStepped для минимальной задержки)
RunService.RenderStepped:Connect(function()
	if not Triggerbot.Settings.Enabled then return end

	local Target = GetTargetUnderCrosshair()
	local Now = tick()

	if Target then
		local BaseDelay = Triggerbot.Settings.Delay / 1000
		local RandomDelta = Triggerbot.Settings.Randomization > 0 and (math.random(-Triggerbot.Settings.Randomization, Triggerbot.Settings.Randomization) / 1000) or 0
		local TotalDelay = BaseDelay + RandomDelta

		if Now - Triggerbot.LastShot >= TotalDelay then
			if Triggerbot.Settings.HoldMode then
				if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then  -- Проверка для Xeno
					mouse1press()
				end
			else
				mouse1press()
				wait(0.01)  -- Короткая пауза для симуляции клика
				mouse1release()
				Triggerbot.LastShot = Now
			end
		end
	else
		if Triggerbot.Settings.HoldMode and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			mouse1release()
		end
	end
end)

--// Функции для UI и сброса
Triggerbot.Functions = {
	ResetSettings = function()
		Triggerbot.Settings = {
			Enabled = false,
			FOVSync = true,
			TeamCheck = true,
			AliveCheck = true,
			WallCheck = true,
			Delay = 50,
			Randomization = 30,
			HoldMode = false,
		}
	end
}
