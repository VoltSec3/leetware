local Tracers = {}

function Tracers.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local Settings = config.Settings

    local Camera = Workspace.CurrentCamera
    local Objects = {}

    local DefaultColor = Color3.fromRGB(255, 0, 0)

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

        return ValidColor(Settings.Tracer_Color, DefaultColor)
    end

    local function Hide(line)
        line.Visible = false
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
        end

        if data.Line then
            data.Line:Remove()
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
            Connection = nil
        }

        Objects[plr] = data

        data.Connection = RunService.RenderStepped:Connect(function()
            Camera = Workspace.CurrentCamera

            if not Camera then
                Hide(line)
                return
            end

            if not Settings.Enabled or not Settings.Tracers then
                Hide(line)
                return
            end

            local character = plr.Character

            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            local root = character and character:FindFirstChild("HumanoidRootPart")

            local head = character and character:FindFirstChild("Head")

            if not character
                or not humanoid
                or not root
                or not head
                or humanoid.Health <= 0 then
                Hide(line)
                return
            end

            local position, visible = Camera:WorldToViewportPoint(root.Position)

            if not visible or position.Z <= 0 then
                Hide(line)
                return
            end

            local viewport = Camera.ViewportSize

            local origin

            if Settings.Tracer_Origin == "Top" then
                origin = Vector2.new(
                    viewport.X / 2,
                    0
                )
            elseif Settings.Tracer_Origin == "Center" then
                origin = Vector2.new(
                    viewport.X / 2,
                    viewport.Y / 2
                )
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
            line.Thickness = math.clamp(
                tonumber(Settings.Tracer_Thickness) or 1,
                1,
                10
            )
            line.Transparency = 1
            line.Visible = true
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

return Tracers