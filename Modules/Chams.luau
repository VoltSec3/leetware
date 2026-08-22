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

        if chamsSettings.Rainbow then
            return Color3.fromHSV(
                (tick() % 5) / 5,
                0.6,
                1
            )
        end

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

        data.Update = function()
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

                local camera = Workspace.CurrentCamera

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

    local renderConnection = RunService.RenderStepped:Connect(function()
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
                data.Update()
            end
        end
    end)

    controller.PlayerAdded =
        Players.PlayerAdded:Connect(function(plr)
            CreateObject(plr)
        end)

    controller.PlayerRemoving =
        Players.PlayerRemoving:Connect(function(plr)
            DestroyObject(plr)
        end)

    function controller:Destroy()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

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