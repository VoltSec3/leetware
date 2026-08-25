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

local Chams = {}

function Chams.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local Settings = config.Settings
    local Utils = config.Utils

    local Objects = {}

    local DefaultColor = Color3.fromRGB(255, 0, 0)
    local DefaultOutline = Color3.fromRGB(255, 255, 255)

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
        local chamsSettings = Settings.Chams

        if Settings.TeamColor
            and Settings.TeamColor.BoxFill
            and plr.TeamColor then
            return ValidColor(
                plr.TeamColor.Color,
                DefaultColor
            )
        end

        return ValidColor(
            chamsSettings.Color,
            DefaultColor
        )
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Highlight then
            data.Highlight:Destroy()
        end

        Objects[plr] = nil
    end

    local function CreateObject(plr)
        if plr == Player or Objects[plr] then
            return
        end

        local highlight = Instance.new("Highlight")

        highlight.Name = "leetware_Chams"
        highlight.Enabled = false
        highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = DefaultColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = DefaultOutline
        highlight.OutlineTransparency = 0

        highlight.Parent = game:GetService("CoreGui")

        local data = {
            Highlight = highlight,
            Update = nil
        }

        Objects[plr] = data

        data.Update = function(camera)
                local settings = Settings.Chams

                if not settings.Enabled then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                local character = plr.Character

                local humanoid = Utils.GetHumanoid(plr)

                local root = Utils.GetRootPart(plr)

                if not character
                    or not humanoid
                    or not root
                    or humanoid.Health <= 0 then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                if not camera then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                local position =
                    camera:WorldToViewportPoint(
                        root.Position
                    )

                if position.Z <= 0 then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                if Settings.Box.TeamCheck
                    and Player.TeamColor
                    and plr.TeamColor
                    and Player.TeamColor == plr.TeamColor then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                if IsFriendBlocked(plr) then
                    highlight.Enabled = false
                    highlight.Adornee = nil
                    return
                end

                local color = GetColor(plr)

                highlight.Adornee = character
                highlight.Enabled = true
                highlight.FillColor = color
                highlight.FillTransparency =
                    math.clamp(
                        tonumber(
                            settings.Transparency
                        ) or 0.5,
                        0,
                        1
                    )

                highlight.OutlineColor =
                    ValidColor(
                        settings.OutlineColor,
                        DefaultOutline
                    )

                highlight.OutlineTransparency =
                    settings.Outline
                    and math.clamp(
                        tonumber(
                            settings.OutlineTransparency
                        ) or 0,
                        0,
                        1
                    )
                    or 1

                highlight.DepthMode =
                    settings.AlwaysOnTop
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or Enum.HighlightDepthMode.Occluded
            end
    end

    local controller = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateObject(plr)
    end

    local wasEnabled = false

    function controller:Update(deltaTime,context)
        local camera=context and context.Camera or Workspace.CurrentCamera

        if not Settings.Chams.Enabled then
            if wasEnabled then
                for _, data in pairs(Objects) do
                    data.Highlight.Enabled = false
                    data.Highlight.Adornee = nil
                end

                wasEnabled = false
            end

            return
        end

        wasEnabled = true

        for _, data in pairs(Objects) do
            if data.Update then
                data.Update(camera)
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

return Chams