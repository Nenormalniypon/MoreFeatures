--[[

	Aimbot Module [AirHub] by Exunys © CC0 1.0 Universal (2023)
	+ Triggerbot added by Grok (2025)

	https://github.com/Exunys

]]

--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel, mouse1press, mouse1release =
    pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper,
    mousemoverel or (Input and Input.MouseMove),
    mouse1press or mouse1.press,   -- для Xeno, Synapse, Krnl и др.
    mouse1release or mouse1.release

--// Launching checks
if not getgenv().AirHub or getgenv().AirHub.Aimbot then return end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local TriggerbotActive = false  -- состояние триггербота (чтобы не спамить кликами)

--// Environment
getgenv().AirHub.Aimbot = {
	Settings = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head",

		--// TRIGGERBOT SETTINGS
		Triggerbot = {
			Enabled = false,
			Delay = 0,        -- задержка перед выстрелом (в секундах)
			HoldMode = false  -- true = держит кнопку мыши, false = один клик
		}
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = Color3fromRGB(255, 255, 255),
		LockedColor = Color3fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	},

	FOVCircle = Drawingnew("Circle"),
	Locked = nil
}

local Environment = getgenv().AirHub.Aimbot

--// Core Functions
local function ConvertVector(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
	UserInputService.MouseDeltaSensitivity = OriginalSensitivity

	if Animation then
		Animation:Cancel()
	end

	if TriggerbotActive and Environment.Settings.Triggerbot.HoldMode then
		mouse1release()
		TriggerbotActive = false
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
				if Environment.Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then continue end
				if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
				if Environment.Settings.WallCheck and #Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants()) > 0 then continue end

				local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
				Vector = ConvertVector(Vector)
				local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance = Distance
					Environment.Locked = v
				end
			end
		end
	elseif Environment.Locked and Environment.Locked.Character then
		local Vector, OnScreen = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
		if not OnScreen or (UserInputService:GetMouseLocation() - ConvertVector(Vector)).Magnitude > RequiredDistance then
			CancelLock()
		end
	end
end

--// Функция стрельбы для триггербота
local function TriggerbotFire()
	if Environment.Settings.Triggerbot.HoldMode then
		if not TriggerbotActive then
			mouse1press()
			TriggerbotActive = true
		end
	else
		mouse1press()
		task.wait(0.03)
		mouse1release()
	end
end

local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		--// FOV Circle
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			local MousePos = UserInputService:GetMouseLocation()
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Position = Vector2new(MousePos.X, MousePos.Y)
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				--// Aimbot Lock
				if Environment.Settings.ThirdPerson then
					local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
					mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity,
					              (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
				else
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
						Animation:Play()
					else
						Camera.CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
					end
					UserInputService.MouseDeltaSensitivity = 0
				end

				Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor

				--// TRIGGERBOT LOGIC
				if Environment.Settings.Triggerbot.Enabled then
					local head = Environment.Locked.Character and Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart)
					local humanoid = Environment.Locked.Character and Environment.Locked.Character:FindFirstChildOfClass("Humanoid")

					local valid = head and humanoid and humanoid.Health > 0
					if valid and (not Environment.Settings.TeamCheck or Environment.Locked.TeamColor ~= LocalPlayer.TeamColor) then
						if not Environment.Settings.WallCheck or #Camera:GetPartsObscuringTarget({head.Position}, Environment.Locked.Character:GetDescendants()) == 0 then
							if Environment.Settings.Triggerbot.Delay > 0 then
								task.delay(Environment.Settings.Triggerbot.Delay, TriggerbotFire)
							else
								TriggerbotFire()
							end
						elseif TriggerbotActive and Environment.Settings.Triggerbot.HoldMode then
							mouse1release()
							TriggerbotActive = false
						end
					end
				end
			else
				-- Нет цели — отпускаем кнопку, если HoldMode
				if TriggerbotActive and Environment.Settings.Triggerbot.HoldMode then
					mouse1release()
					TriggerbotActive = false
				end
			end
		else
			-- Aimbot выключен
			if TriggerbotActive and Environment.Settings.Triggerbot.HoldMode then
				mouse1release()
				TriggerbotActive = false
			end
		end
	end)

	--// Input handling (остаётся без изменений)
	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if Typing then return end
		pcall(function()
			local key = Environment.Settings.TriggerKey
			if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[stringupper(key)] and #key == 1)
			or Input.UserInputType.Name == key then
				if Environment.Settings.Toggle then
					Running = not Running
					if not Running then CancelLock() end
				else
					Running = true
				end
			end
		end)
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if Typing or Environment.Settings.Toggle then return end
		pcall(function()
			local key = Environment.Settings.TriggerKey
			if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[stringupper(key)] and #key == 1)
			or Input.UserInputType.Name == key then
				Running = false
				CancelLock()
			end
		end)
	end)
end

--// Typing Check
ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)

--// Functions
Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in ServiceConnections do v:Disconnect() end
	Environment.FOVCircle:Remove()
	if TriggerbotActive and Environment.Settings.Triggerbot.HoldMode then mouse1release() end
	getgenv().AirHub.Aimbot = nil
end

function Environment.Functions:Restart()
	for _, v in ServiceConnections do v:Disconnect() end
	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = false, TeamCheck = false, AliveCheck = true, WallCheck = false,
		Sensitivity = 0, ThirdPerson = false, ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2", Toggle = false, LockPart = "Head",
		Triggerbot = { Enabled = false, Delay = 0, HoldMode = false }
	}
	Environment.FOVSettings = {
		Enabled = true, Visible = true, Amount = 90,
		Color = Color3fromRGB(255,255,255), LockedColor = Color3fromRGB(255,70,70),
		Transparency = 0.5, Sides = 60, Thickness = 1, Filled = false
	}
end

setmetatable(Environment.Functions, { __newindex = warn })

--// Load
Load()
