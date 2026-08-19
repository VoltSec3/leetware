local Chams = {}

function Chams.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Player = config.Player
    local Settings = config.Settings

    local Objects = {}

    local DefaultColor = Color3.fromRGB(255, 0, 0)
    local DefaultOutline = Color3.fromRGB(255, 255, 255)

    local function ValidColor(value, fallback)
        if typeof(value) == "Color3" then
            return value
        end

        return fallback
    end

    local function GetColor(plr)
        if Settings.Rainbow then
            return Color3.fromHSV((tick() % 5) / 5, 0.6, 1)
        end

        if Settings.Team_Color and plr.TeamColor then
            return ValidColor(plr.TeamColor.Color, DefaultColor)
        end

        if Settings.Team_Check then
            if plr.TeamColor
                and Player.TeamColor
                and plr.TeamColor == Player.TeamColor then
                return Color3.fromRGB(0, 255, 0)
            end

            return Color3.fromRGB(255, 0, 0)
        end

        return ValidColor(Settings.Chams_Color, DefaultColor)
    end

    local function Hide(highlight)
        if highlight then
            highlight.Enabled = false
        end
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
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
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = DefaultColor
        highlight.OutlineColor = DefaultOutline
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = game:GetService("CoreGui")

        local data = {
            Highlight = highlight,
            Connection = nil
        }

        Objects[plr] = data

        data.Connection = RunService.RenderStepped:Connect(function()
            if not Settings.Enabled or not Settings.Chams then
                Hide(highlight)
                highlight.Adornee = nil
                return
            end

            local character = plr.Character

            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            local root = character and character:FindFirstChild("HumanoidRootPart")

            if not character
                or not humanoid
                or not root
                or humanoid.Health <= 0 then
                Hide(highlight)
                highlight.Adornee = nil
                return
            end

            local camera = workspace.CurrentCamera

            if not camera then
                Hide(highlight)
                highlight.Adornee = nil
                return
            end

            local position, visible = camera:WorldToViewportPoint(root.Position)

            if not visible or position.Z <= 0 then
                Hide(highlight)
                highlight.Adornee = nil
                return
            end

            local color = GetColor(plr)

            highlight.Adornee = character
            highlight.Enabled = true
            highlight.FillColor = color
            highlight.FillTransparency = math.clamp(
                tonumber(Settings.Chams_Transparency) or 0.5,
                0,
                1
            )
            highlight.OutlineColor = ValidColor(
                Settings.Chams_Outline_Color,
                DefaultOutline
            )
            highlight.OutlineTransparency = Settings.Chams_Outline and 0 or 1
        end)
    end

    local controller = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateObject(plr)
    end

    controller.PlayerAdded = Players.PlayerAdded:Connect(function(plr)
        CreateObject(plr)
    end)

    controller.PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
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