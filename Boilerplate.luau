-- leetware runtime guard: do not remove. this file only executes inside the official loader.
do
  local function __leet_expected()
    return "442d62f3b029ae4f"
  end
  local function __leet_key()
    return "boilerplate"
  end
  local rt = _G.__leet_rt
  if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
    error("leetware: this script must be executed through the leetware loader.", 0)
  end
  local ok, provided = pcall(rt.verify, __leet_key())
  if not ok or provided ~= __leet_expected() then
    error("leetware: runtime verification failed.", 0)
  end
end
-- leetware runtime guard end

-- Universal boilerplate. Used as the fallback when the current GameId has no
-- dedicated game module. It cannot be executed outside the loader (see the
-- guard above) and is delivered through the authenticated API so its payload
-- can be edited from the dashboard without shipping a loader update.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 6,
		})
	end)
end

notify("leetware", "universal loader active - no dedicated config for this game")

-- The shared modules have already been pulled by the loader and are available
-- on _G.__leet_modules. The boilerplate only runs as a fallback, but it is a
-- convenient place to see the canonical pattern for loading and using modules.

-- GetModule: fetch a loaded module from the loader's module registry. Modules
-- are exposed the same way whether they are classes (with :new, e.g. esp/aimbot)
-- or plain libraries (e.g. utils).
local function GetModule(key)
	local module = _G.__leet_modules and _G.__leet_modules[key]

	if not module or type(module) ~= "table" then
		error("leetware: required module '" .. tostring(key) .. "' was not loaded by the loader.", 0)
	end

	return module
end

-- GET MODULES: list everything the loader pulled in for this session.
local loaded = {}

for key, module in pairs(_G.__leet_modules or {}) do
	if type(module) == "table" then
		table.insert(loaded, key .. (type(module.new) == "function" and " (class)" or " (library)"))
	end
end

if #loaded > 0 then
	notify("leetware", "modules available: " .. table.concat(loaded, ", "))
end

-- LOAD ESP + AIMBOT: pull the module classes from the registry and build
-- controllers from a settings table plus the standard Roblox services.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local Utils = GetModule("utils")
local ESPModule = GetModule("esp")
local AimbotModule = GetModule("aimbot")

-- A minimal settings object. Mirror the shape your game already uses; only the
-- fields the modules read need to be present.
local Settings = {
	FriendCheck = false,
	Box = {
		Enabled = true,
		Style = "Corner",
		Color = Color3.fromRGB(255, 0, 0),
		Thickness = 2,
		TeamCheck = false,
		TeamColor = false,
		AutoThickness = false,
	},
	Fill = {
		Enabled = false,
		Color = Color3.fromRGB(255, 0, 0),
		Opacity = 0.15,
	},
	Information = {
		ShowName = false,
		ShowDisplayName = false,
		ShowWeapon = false,
		ShowTeam = false,
		CustomTextColor = false,
		NameColor = Color3.fromRGB(255, 255, 255),
		WeaponColor = Color3.fromRGB(255, 255, 255),
		TeamTextColor = Color3.fromRGB(255, 255, 255),
		NameScale = 14,
		Font = "UI",
	},
	Health = {
		Enabled = false,
		BorderColor = Color3.fromRGB(0, 0, 0),
		FillColor = Color3.fromRGB(255, 255, 255),
	},
	TeamColor = {
		BoxBorder = false,
		BoxFill = false,
		Text = false,
		HealthBorder = false,
		HealthFill = false,
		DarkenBorders = false,
		DarkenAmount = 0,
	},
	Aimbot = {
		Enabled = true,
		Bind = "MouseButton2",
		Fov = 120,
		FovColor = Color3.fromRGB(255, 255, 255),
		TargetedFovColor = Color3.fromRGB(255, 0, 0),
		WallCheck = false,
		Prediction = 0,
		FriendCheck = false,
		LockAim = false,
		Triggerbot = false,
		TriggerbotDelay = 0,
		TeamCheck = false,
		HealthCheck = false,
		MinHealth = 0,
		Range = 500,
		Smoothing = 5,
		ExcludeTeams = {},
		PrioritizeTeams = {},
		Targeting = "Normal",
	},
}

local ESPController = ESPModule.new({
	Players = Players,
	RunService = RunService,
	Workspace = Workspace,
	Player = Player,
	Settings = Settings,
	UserInputService = UserInputService,
	Utils = Utils,
})

local AimbotController = AimbotModule.new({
	Players = Players,
	RunService = RunService,
	Workspace = Workspace,
	Player = Player,
	UserInputService = UserInputService,
	Settings = Settings.Aimbot,
	Utils = Utils,
})

notify("leetware", "loaded ESP + Aimbot controllers")

-- USE MODULES: drive their per-frame :Update from a single RenderStepped loop.
-- FrameContext is the shared state passed into every controller's Update call.
local FrameContext = {
	Camera = Workspace.CurrentCamera,
	Players = Players:GetPlayers(),
	Tools = {},
}

Players.PlayerAdded:Connect(function()
	FrameContext.Players = Players:GetPlayers()
end)

Players.PlayerRemoving:Connect(function()
	FrameContext.Players = Players:GetPlayers()
end)

RunService.RenderStepped:Connect(function(deltaTime)
	FrameContext.Camera = Workspace.CurrentCamera

	if ESPController and type(ESPController.Update) == "function" then
		ESPController:Update(deltaTime, FrameContext)
	end

	if AimbotController and type(AimbotController.Update) == "function" then
		AimbotController:Update(deltaTime, FrameContext)
	end
end)

-- Quick usage example: toggle the ESP boxes on/off with the F5 key.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F5 then
		Settings.Box.Enabled = not Settings.Box.Enabled
		notify("leetware", "ESP boxes " .. (Settings.Box.Enabled and "enabled" or "disabled"))
	end
end)
