  --[[
	Triggerbot Module [AirHub] by Exunys © CC0 1.0 Universal (2025)
]]

--// Launching checks
if not getgenv().AirHub or getgenv().AirHub.Triggerbot then return end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local Shooting = false
local Connections = {}

--// Environment
getgenv().AirHub.Triggerbot = {
	Settings = {
		Enabled = false,
		Delay = 0, -- Задержка перед выстрелом (мс), 0 = мгновенно
		TeamCheck = true,
		WallCheck = true,
		AliveCheck = true
	}
}

local Environment = getgenv().AirHub.Triggerbot
local AimbotEnv = getgenv().AirHub.Aimbot

--// Core Functions
local function IsValidTarget(Player)
	if not Player or Player == LocalPlayer then return false end
	if not Player.Character or not Player.Character:FindFirstChild("Head") then return false end
	if not Player.Character:FindFirstChildOfClass("Humanoid") then return false end

	local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
	if Environment.Settings.AliveCheck and Humanoid.Health <= 0 then return false end
	if Environment.Settings.TeamCheck and Player.Team == LocalPlayer.Team then return false end

	if Environment.Settings.WallCheck then
		local Parts = {}
		for _, Part in ipairs(Player.Character:GetChildren()) do
			if Part:IsA("BasePart") then
				table.insert(Parts, Part)
			end
		end
		if #Camera:GetPartsObscuringTarget(Parts, {Camera, LocalPlayer.Character}) > 0 then
			return false
		end
	end

	return true
end

local function StartShooting()
	if Shooting then return end
	Shooting = true
	mouse1press()
end

local function StopShooting()
	if not Shooting then return end
	Shooting = false
	mouse1release()
end

--// Main Loop
Connections.Heartbeat = RunService.Heartbeat:Connect(function()
	if not Environment.Settings.Enabled then
		if Shooting then StopShooting() end
		return
	end

	if not AimbotEnv or not AimbotEnv.Locked then
		if Shooting then StopShooting() end
		return
	end

	local Target = AimbotEnv.Locked
	if IsValidTarget(Target) then
		local ScreenPos = Camera:WorldToViewportPoint(Target.Character.Head.Position)
		local MousePos = UserInputService:GetMouseLocation()
		local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude

		-- Проверяем, что прицел действительно на цели (в пределах FOV или очень близко)
		local MaxDistance = AimbotEnv.FOVSettings.Enabled and AimbotEnv.FOVSettings.Amount or 100
		if Distance <= MaxDistance + 30 then -- +30 пикселей допуск
			if Environment.Settings.Delay > 0 then
				task.wait(Environment.Settings.Delay / 1000)
			end
			StartShooting()
		else
			StopShooting()
		end
	else
		StopShooting()
	end
end)

--// Cleanup
Environment.Functions = {}

function Environment.Functions:Exit()
	for _, Connection in pairs(Connections) do
		Connection:Disconnect()
	end
	StopShooting()
	getgenv().AirHub.Triggerbot = nil
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = false,
		Delay = 0,
		TeamCheck = true,
		WallCheck = true,
		AliveCheck = true
	}
end
