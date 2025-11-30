--[[
	Triggerbot Module [AirHub] by Exunys + улучшено для тебя © CC0 1.0 Universal (2025)
]]

if not getgenv().AirHub or getgenv().AirHub.Triggerbot then return end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().AirHub.Triggerbot = {
	Settings = {
		Enabled = false,
		TeamCheck = true,
		AliveCheck = true,
		WallCheck = true,
		Delay = 0,              -- миллисекунды перед выстрелом
		Randomization = 0,      -- ± ms рандомизация задержки
		HoldMode = false,       -- false = стреляет один раз, true = держит ЛКМ пока на цели
	},

	LastShot = 0
}

local Triggerbot = getgenv().AirHub.Triggerbot
local Aimbot = getgenv().AirHub.Aimbot

--// Основная проверка (используем ту же логику, что и в Aimbot)
local function IsTargetValid(Player)
	if not Player or Player == LocalPlayer then return false end
	if not Player.Character or not Player.Character:FindFirstChild(Aimbot.Settings.LockPart or "Head") then return false end

	local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
	if Triggerbot.Settings.AliveCheck and (not Humanoid or Humanoid.Health <= 0) then return false end
	if Triggerbot.Settings.TeamCheck and Player.Team == LocalPlayer.Team then return false end

	if Triggerbot.Settings.WallCheck then
		local Origin = Camera.CFrame.Position
		local TargetPos = Player.Character[Aimbot.Settings.LockPart].Position
		local Ray = Ray.new(Origin, (TargetPos - Origin).Unit * 500)
		local Hit = workspace:FindPartOnRayWithIgnoreList(Ray, {LocalPlayer.Character, Camera})
		if Hit and Hit:IsDescendantOf(Player.Character) == false then
			return false
		end
	end

	return true
end

--// Проверка, находится ли игрок под прицелом
local function GetTargetUnderMouse()
	local MousePos = UserInputService:GetMouseLocation()
	for _, Player in ipairs(Players:GetPlayers()) do
		if IsTargetValid(Player) then
			local Head = Player.Character:FindFirstChild(Aimbot.Settings.LockPart or "Head")
			if Head then
				local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
				if OnScreen then
					local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
					if Distance < (Aimbot.FOVSettings.Enabled and Aimbot.FOVSettings.Amount or 100) then
						return Player
					end
				end
			end
		end
	end
	return nil
end

--// Основной цикл
RunService.RenderStepped:Connect(function()
	if not Triggerbot.Settings.Enabled then return end
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not Triggerbot.Settings.HoldMode then return end

	local Target = GetTargetUnderMouse()

	if Target then
		local Now = tick()
		local Delay = Triggerbot.Settings.Delay / 1000
		if Triggerbot.Settings.Randomization > 0 then
			Delay = Delay + (math.random(-Triggerbot.Settings.Randomization, Triggerbot.Settings.Randomization) / 1000)
		end

		if Now - Triggerbot.LastShot >= Delay then
			if Triggerbot.Settings.HoldMode then
				if not isbuttondown("MouseButton1") then
					mouse1press()
				end
			else
				mouse1press()
				mouse1release()
				Triggerbot.LastShot = Now
			end
		end
	else
		if Triggerbot.Settings.HoldMode and isbuttondown("MouseButton1") then
			mouse1release()
		end
	end
end)

--// Функции для UI
Triggerbot.Functions = {
	ResetSettings = function()
		Triggerbot.Settings = {
			Enabled = false,
			TeamCheck = true,
			AliveCheck = true,
			WallCheck = true,
			Delay = 0,
			Randomization = 0,
			HoldMode = false,
		}
	end
}
