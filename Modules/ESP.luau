local ESP = {}

function ESP.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player

    local Settings = config.Settings
    local Camera = Workspace.CurrentCamera
    local Objects = {}

    local Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3
    }

    local DefaultBoxColor = Color3.fromRGB(255, 0, 0)
    local DefaultTextColor = Color3.fromRGB(255, 255, 255)
    local DefaultHealthBorder = Color3.fromRGB(0, 0, 0)
    local DefaultHealthFill = Color3.fromRGB(255, 255, 255)

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

        local success, isFriend = pcall(function()
            return Player:IsFriendsWith(plr.UserId)
        end)

        return success and isFriend
    end

    local function GetTeamColor(plr, fallback)
        if plr.TeamColor then
            return ValidColor(plr.TeamColor.Color, fallback)
        end

        return fallback
    end

    local function DarkenColor(color)
        local teamSettings = Settings.TeamColor or {}
        local amount = math.clamp(
            tonumber(teamSettings.DarkenAmount) or 0,
            0,
            100
        ) / 100

        return Color3.new(
            color.R * (1 - amount),
            color.G * (1 - amount),
            color.B * (1 - amount)
        )
    end

    local function NewLine()
        local line = Drawing.new("Line")

        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = DefaultBoxColor
        line.Thickness = 2
        line.Transparency = 1

        return line
    end

    local function NewSquare(color)
        local square = Drawing.new("Square")

        square.Visible = false
        square.Position = Vector2.new(0, 0)
        square.Size = Vector2.new(0, 0)
        square.Thickness = 1
        square.Filled = true
        square.Transparency = 1
        square.Color = ValidColor(color, DefaultBoxColor)

        return square
    end

    local function NewText()
        local text = Drawing.new("Text")

        text.Visible = false
        text.Text = ""
        text.Size = 14
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.fromRGB(0, 0, 0)
        text.Position = Vector2.new(0, 0)
        text.Font = Fonts.UI
        text.Transparency = 1
        text.Color = DefaultTextColor

        return text
    end

    local function Hide(object)
        if object then
            object.Visible = false
        end
    end

    local function HideLibrary(library)
        for _, object in pairs(library) do
            Hide(object)
        end
    end

    local function DestroyDrawing(object)
        if object then
            pcall(function()
                object:Remove()
            end)
        end
    end

    local function SetThickness(library, thickness)
        for _, object in pairs(library) do
            if object and object.Thickness ~= nil then
                object.Thickness = thickness
            end
        end
    end

    local function GetColor(plr)
        local boxSettings = Settings.Box

        if boxSettings.Rainbow then
            return Color3.fromHSV(
                (tick() % 5) / 5,
                0.6,
                1
            )
        end

        if boxSettings.TeamColor and plr.TeamColor then
            return ValidColor(
                plr.TeamColor.Color,
                DefaultBoxColor
            )
        end

        return ValidColor(
            boxSettings.Color,
            DefaultBoxColor
        )
    end

    local function GetElementColor(plr, element, fallback)
        local teamSettings = Settings.TeamColor or {}
        local color = ValidColor(fallback, DefaultBoxColor)

        if teamSettings[element] then
            color = GetTeamColor(plr, color)

            if (element == "BoxBorder" or element == "HealthBorder")
                and teamSettings.DarkenBorders then
                color = DarkenColor(color)
            end
        end

        return color
    end

    local function IsTeamBlocked(plr)
        local boxSettings = Settings.Box

        if not boxSettings.TeamCheck then
            return false
        end

        if not plr.TeamColor or not Player.TeamColor then
            return false
        end

        return plr.TeamColor == Player.TeamColor
    end

    local function GetTextColor(plr, textType)
        local infoSettings = Settings.Information

        if Settings.TeamColor.Text then
            return GetElementColor(
                plr,
                "Text",
                DefaultTextColor
            )
        end

        if not infoSettings.CustomTextColor then
            return GetColor(plr)
        end

        if textType == "Name" then
            return ValidColor(
                infoSettings.NameColor,
                DefaultTextColor
            )
        end

        return ValidColor(
            infoSettings.TeamTextColor,
            DefaultTextColor
        )
    end

    local function GetBounds(character)
        local minX = math.huge
        local minY = math.huge
        local maxX = -math.huge
        local maxY = -math.huge
        local found = false

        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                local half = object.Size / 2
                local cf = object.CFrame

                local corners = {
                    cf * Vector3.new(-half.X, -half.Y, -half.Z),
                    cf * Vector3.new(-half.X, -half.Y, half.Z),
                    cf * Vector3.new(-half.X, half.Y, -half.Z),
                    cf * Vector3.new(-half.X, half.Y, half.Z),
                    cf * Vector3.new(half.X, -half.Y, -half.Z),
                    cf * Vector3.new(half.X, -half.Y, half.Z),
                    cf * Vector3.new(half.X, half.Y, -half.Z),
                    cf * Vector3.new(half.X, half.Y, half.Z)
                }

                for _, corner in ipairs(corners) do
                    local position = Camera:WorldToViewportPoint(corner)

                    if position.Z > 0 then
                        found = true

                        minX = math.min(minX, position.X)
                        minY = math.min(minY, position.Y)
                        maxX = math.max(maxX, position.X)
                        maxY = math.max(maxY, position.Y)
                    end
                end
            end
        end

        if not found then
            return nil
        end

        return minX, minY, maxX, maxY
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
        end

        for _, object in pairs(data.Library) do
            DestroyDrawing(object)
        end

        Objects[plr] = nil
    end

    local function CreateObject(plr)
        if plr == Player or Objects[plr] then
            return
        end

        local library = {
            TL1 = NewLine(),
            TL2 = NewLine(),
            TR1 = NewLine(),
            TR2 = NewLine(),
            BL1 = NewLine(),
            BL2 = NewLine(),
            BR1 = NewLine(),
            BR2 = NewLine(),
            BoxTop = NewLine(),
            BoxBottom = NewLine(),
            BoxLeft = NewLine(),
            BoxRight = NewLine(),
            Fill = NewSquare(),
            Name = NewText(),
            Team = NewText(),
            HealthOutline = NewSquare(DefaultHealthBorder),
            HealthBar = NewSquare(DefaultHealthFill)
        }

        library.HealthOutline.Filled = false

        local data = {
            Library = library,
            Connection = nil
        }

        Objects[plr] = data

        data.Connection = RunService.RenderStepped:Connect(function()
            Camera = Workspace.CurrentCamera

            local boxSettings = Settings.Box
            local fillSettings = Settings.Fill
            local infoSettings = Settings.Information
            local healthSettings = Settings.Health

            if not Camera or not boxSettings.Enabled then
                HideLibrary(library)
                return
            end

            local character = plr.Character

            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")

            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if not character
                or not humanoid
                or not root
                or humanoid.Health <= 0 then
                HideLibrary(library)
                return
            end

            if IsTeamBlocked(plr) then
                HideLibrary(library)
                return
            end

            if IsFriendBlocked(plr) then
                HideLibrary(library)
                return
            end

            local rootPosition = Camera:WorldToViewportPoint(
                root.Position
            )

            local distance = (
                root.Position - Camera.CFrame.Position
            ).Magnitude

            if rootPosition.Z <= 0 then
                HideLibrary(library)
                return
            end

            local left, top, right, bottom = GetBounds(character)

            if not left then
                HideLibrary(library)
                return
            end

            local width = math.max(right - left, 1)
            local height = math.max(bottom - top, 1)
            local color = GetElementColor(
                plr,
                "BoxBorder",
                GetColor(plr)
            )

            local cornerLength =
                math.min(width, height) * 0.25

            cornerLength = math.max(
                cornerLength,
                2
            )

            cornerLength = math.min(
                cornerLength,
                width / 2,
                height / 2
            )

            library.TL1.Color = color
            library.TL2.Color = color
            library.TR1.Color = color
            library.TR2.Color = color
            library.BL1.Color = color
            library.BL2.Color = color
            library.BR1.Color = color
            library.BR2.Color = color
            library.BoxTop.Color = color
            library.BoxBottom.Color = color
            library.BoxLeft.Color = color
            library.BoxRight.Color = color

            library.TL1.From = Vector2.new(left, top)
            library.TL1.To = Vector2.new(
                left + cornerLength,
                top
            )

            library.TL2.From = Vector2.new(left, top)
            library.TL2.To = Vector2.new(
                left,
                top + cornerLength
            )

            library.TR1.From = Vector2.new(right, top)
            library.TR1.To = Vector2.new(
                right - cornerLength,
                top
            )

            library.TR2.From = Vector2.new(right, top)
            library.TR2.To = Vector2.new(
                right,
                top + cornerLength
            )

            library.BL1.From = Vector2.new(left, bottom)
            library.BL1.To = Vector2.new(
                left + cornerLength,
                bottom
            )

            library.BL2.From = Vector2.new(left, bottom)
            library.BL2.To = Vector2.new(
                left,
                bottom - cornerLength
            )

            library.BR1.From = Vector2.new(right, bottom)
            library.BR1.To = Vector2.new(
                right - cornerLength,
                bottom
            )

            library.BR2.From = Vector2.new(right, bottom)
            library.BR2.To = Vector2.new(
                right,
                bottom - cornerLength
            )

            library.BoxTop.From = Vector2.new(left, top)
            library.BoxTop.To = Vector2.new(right, top)

            library.BoxBottom.From = Vector2.new(left, bottom)
            library.BoxBottom.To = Vector2.new(right, bottom)

            library.BoxLeft.From = Vector2.new(left, top)
            library.BoxLeft.To = Vector2.new(left, bottom)

            library.BoxRight.From = Vector2.new(right, top)
            library.BoxRight.To = Vector2.new(right, bottom)

            local isCorner = boxSettings.Style == "Corner"

            library.TL1.Visible = isCorner
            library.TL2.Visible = isCorner
            library.TR1.Visible = isCorner
            library.TR2.Visible = isCorner
            library.BL1.Visible = isCorner
            library.BL2.Visible = isCorner
            library.BR1.Visible = isCorner
            library.BR2.Visible = isCorner

            library.BoxTop.Visible = not isCorner
            library.BoxBottom.Visible = not isCorner
            library.BoxLeft.Visible = not isCorner
            library.BoxRight.Visible = not isCorner

            if fillSettings.Enabled then
                library.Fill.Visible = true
                library.Fill.Color = GetElementColor(
                    plr,
                    "BoxFill",
                    ValidColor(
                        fillSettings.Color,
                        DefaultBoxColor
                    )
                )
                library.Fill.Transparency =
                    math.clamp(
                        fillSettings.Opacity,
                        0,
                        1
                    )
                library.Fill.Position = Vector2.new(
                    left,
                    top
                )
                library.Fill.Size = Vector2.new(
                    width,
                    height
                )
            else
                library.Fill.Visible = false
            end

            local nameScale = math.clamp(
                tonumber(infoSettings.NameScale) or 14,
                1,
                100
            )

            library.Name.Visible =
                infoSettings.ShowName

            library.Name.Text =
                tostring(
                    infoSettings.ShowDisplayName
                    and plr.DisplayName
                    or plr.Name
                )

            library.Name.Color =
                GetTextColor(
                    plr,
                    "Name"
                )

            library.Name.Size =
                nameScale

            library.Name.Font =
                Fonts[infoSettings.Font] or Fonts.UI

            library.Name.Position =
                Vector2.new(
                    (left + right) / 2,
                    top - nameScale - 5
                )

            library.Team.Visible =
                infoSettings.ShowTeam

            library.Team.Text =
                plr.Team
                and tostring(plr.Team.Name)
                or "Neutral"

            library.Team.Color =
                GetTextColor(
                    plr,
                    "Team"
                )

            library.Team.Size =
                math.max(
                    nameScale - 1,
                    10
                )

            library.Team.Font =
                Fonts[infoSettings.Font] or Fonts.UI

            library.Team.Position =
                Vector2.new(
                    (left + right) / 2,
                    top - (
                        infoSettings.ShowName
                        and nameScale + 19
                        or 18
                    )
                )

            local healthRatio = 0

            if humanoid.MaxHealth > 0 then
                healthRatio = math.clamp(
                    humanoid.Health /
                        humanoid.MaxHealth,
                    0,
                    1
                )
            end

            library.HealthOutline.Visible =
                healthSettings.Enabled

            library.HealthOutline.Color =
                GetElementColor(
                    plr,
                    "HealthBorder",
                    healthSettings.BorderColor
                )

            library.HealthOutline.Position =
                Vector2.new(
                    right + 5,
                    top
                )

            library.HealthOutline.Size =
                Vector2.new(
                    5,
                    height
                )

            library.HealthBar.Visible =
                healthSettings.Enabled

            library.HealthBar.Color =
                GetElementColor(
                    plr,
                    "HealthFill",
                    healthSettings.FillColor
                )

            library.HealthBar.Position =
                Vector2.new(
                    right + 6,
                    bottom -
                        ((height - 2) * healthRatio) -
                        1
                )

            library.HealthBar.Size =
                Vector2.new(
                    3,
                    math.max(
                        (height - 2) * healthRatio,
                        0
                    )
                )

            local thickness

            if boxSettings.AutoThickness then
                thickness = math.clamp(
                    100 /
                        math.max(
                            distance or 1,
                            1
                        ),
                    1,
                    4
                )
            else
                thickness = math.clamp(
                    tonumber(boxSettings.Thickness) or 2,
                    1,
                    20
                )
            end

            SetThickness(
                {
                    TL1 = library.TL1,
                    TL2 = library.TL2,
                    TR1 = library.TR1,
                    TR2 = library.TR2,
                    BL1 = library.BL1,
                    BL2 = library.BL2,
                    BR1 = library.BR1,
                    BR2 = library.BR2,
                    BoxTop = library.BoxTop,
                    BoxBottom = library.BoxBottom,
                    BoxLeft = library.BoxLeft,
                    BoxRight = library.BoxRight
                },
                thickness
            )
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

return ESP