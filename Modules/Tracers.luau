--[[ leetware runtime guard: do not remove. this file only executes inside the official loader. ]]
do
	local function __leet_runtime_token()
		local seed = {0x6C,0x65,0x65,0x74,0x77,0x61,0x72,0x65,0x2D,0x72,0x74,0x2D,0x76,0x31}
		local key = {0x1F,0x3A,0x9C,0x55,0x7B,0x02,0xC4,0xED,0x36,0x88,0x4D,0x0B,0x91,0x5E}
		local out = {}
		for i = 1, #seed do
			out[i] = string.char(bit32.bxor(seed[i], key[((i - 1) % #key) + 1]))
		end
		return table.concat(out)
	end

	local rt = _G.__leet_rt
	if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
		error("leetware: this script must be executed through the leetware loader.", 0)
	end

	local ok, provided = pcall(rt.verify)
	if not ok or provided ~= __leet_runtime_token() then
		error("leetware: runtime verification failed.", 0)
	end
end
--[[ end leetware runtime guard ]]

local Tracers = {}

function Tracers.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local Settings = config.Settings
    local Utils = config.Utils
    local UserInputService =
        config.UserInputService
        or game:GetService("UserInputService")

    local Camera = Workspace.CurrentCamera
    local Objects = {}

    local DefaultColor = Color3.fromRGB(255, 0, 0)

    local function ValidColor(value, fallback)
        if typeof(value) == "Color3" then
            return value
        end

        return fallback
    end

    local function IsFriendBlocked(plr)
        if not Settings.FriendCheck then
            return false
        end

        return Utils.IsFriend(Player, plr)
    end

    local function GetColor(plr)
        local tracerSettings = Settings.Tracers

        if Settings.TeamColor
            and Settings.TeamColor.BoxBorder
            and plr.TeamColor then
            return ValidColor(
                plr.TeamColor.Color,
                DefaultColor
            )
        end

        return ValidColor(
            tracerSettings.Color,
            DefaultColor
        )
    end

    local function Hide(line)
        line.Visible = false
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Line then
            pcall(function()
                data.Line:Remove()
            end)
        end

        Objects[plr] = nil
    end

    local function CreateObject(plr)
        if plr == Player or Objects[plr] then
            return
        end

        local line = Drawing.new("Line")

        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = DefaultColor
        line.Thickness = 1
        line.Transparency = 1

        local data = {
            Line = line,
            Update = nil
        }

        Objects[plr] = data

        data.Update = function(context)
                local settings = Settings.Tracers

                if not settings.Enabled then
                    Hide(line)
                    return
                end

                Camera = context and context.Camera or Workspace.CurrentCamera

                if not Camera then
                    Hide(line)
                    return
                end

                local character = plr.Character

                local humanoid = Utils.GetHumanoid(plr)

                local root = Utils.GetRootPart(plr)

                if not character
                    or not humanoid
                    or not root
                    or humanoid.Health <= 0 then
                    Hide(line)
                    return
                end

                if Settings.Box.TeamCheck
                    and Player.TeamColor
                    and plr.TeamColor
                    and Player.TeamColor == plr.TeamColor then
                    Hide(line)
                    return
                end

                if IsFriendBlocked(plr) then
                    Hide(line)
                    return
                end

                local position =
                    Camera:WorldToViewportPoint(
                        root.Position
                    )

                if position.Z <= 0 and not settings.ShowNotInView then
                    Hide(line)
                    return
                end

                local viewport =
                    Camera.ViewportSize

                local origin

                if settings.Origin == "Top" then
                    origin = Vector2.new(
                        viewport.X / 2,
                        0
                    )
                elseif settings.Origin == "Center" then
                    origin = Vector2.new(
                        viewport.X / 2,
                        viewport.Y / 2
                    )
                elseif settings.Origin == "Mouse" then
                    origin =
                        UserInputService:GetMouseLocation()
                else
                    origin = Vector2.new(
                        viewport.X / 2,
                        viewport.Y
                    )
                end

                line.From = origin

                line.To = Vector2.new(
                    position.X,
                    position.Y
                )

                line.Color = GetColor(plr)

                line.Thickness =
                    math.clamp(
                        tonumber(settings.Thickness) or 1,
                        1,
                        10
                    )

                line.Transparency =
                    math.clamp(
                        tonumber(settings.Transparency) or 1,
                        0,
                        1
                    )

                line.Visible = true
            end
    end

    local controller = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateObject(plr)
    end

    local wasEnabled = false

    function controller:Update(deltaTime,context)
        if not Settings.Tracers.Enabled then
            if wasEnabled then
                for _, data in pairs(Objects) do
                    Hide(data.Line)
                end

                wasEnabled = false
            end

            return
        end

        wasEnabled = true

        for _, data in pairs(Objects) do
            if data.Update then
                data.Update(context)
            end
        end
    end

    controller.PlayerAdded =
        Players.PlayerAdded:Connect(function(plr)
            CreateObject(plr)
        end)

    controller.PlayerRemoving =
        Players.PlayerRemoving:Connect(function(plr)
            DestroyObject(plr)
        end)

    function controller:Destroy()
        if controller.PlayerAdded then
            controller.PlayerAdded:Disconnect()
            controller.PlayerAdded = nil
        end

        if controller.PlayerRemoving then
            controller.PlayerRemoving:Disconnect()
            controller.PlayerRemoving = nil
        end

        for plr in pairs(Objects) do
            DestroyObject(plr)
        end
    end

    return controller
end

return Tracers