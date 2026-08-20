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

        if tracerSettings.Rainbow then
            return Color3.fromHSV(
                (tick() % 5) / 5,
                0.6,
                1
            )
        end

        if boxSettings.TeamColor and plr.TeamColor then
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

        if data.Connection then
            data.Connection:Disconnect()
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
            Connection = nil
        }

        Objects[plr] = data

        data.Connection =
            RunService.RenderStepped:Connect(function()
                local settings = Settings.Tracers

                if not settings.Enabled then
                    Hide(line)
                    return
                end

                Camera = Workspace.CurrentCamera

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

                if position.Z <= 0 then
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
            end)
    end

    local controller = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateObject(plr)
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