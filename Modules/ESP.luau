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
    local DefaultHealthColor = Color3.fromRGB(255, 255, 255)

    local function ValidColor(value, fallback)
        if typeof(value) == "Color3" then
            return value
        end

        return fallback
    end

    local function NewLine(color, thickness)
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = ValidColor(color, DefaultBoxColor)
        line.Thickness = thickness or 1
        line.Transparency = 1
        return line
    end

    local function NewSquare()
        local square = Drawing.new("Square")
        square.Visible = false
        square.Position = Vector2.new(0, 0)
        square.Size = Vector2.new(0, 0)
        square.Thickness = 1
        square.Filled = false
        square.Transparency = 1
        square.Color = DefaultBoxColor
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

    local function HideLibrary(library)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    nested.Visible = false
                end
            else
                object.Visible = false
            end
        end
    end

    local function SetThickness(library, thickness)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    if nested.Thickness ~= nil then
                        nested.Thickness = thickness
                    end
                end
            elseif object.Thickness ~= nil then
                object.Thickness = thickness
            end
        end
    end

    local function GetESPColor(plr)
        if Settings.Rainbow then
            return Color3.fromHSV((tick() % 5) / 5, 0.6, 1)
        end

        if Settings.Team_Color and plr.TeamColor then
            local teamColor = plr.TeamColor.Color

            if typeof(teamColor) == "Color3" then
                return teamColor
            end
        end

        if Settings.Team_Check then
            if plr.TeamColor and Player.TeamColor and plr.TeamColor == Player.TeamColor then
                return Color3.fromRGB(0, 255, 0)
            end

            return Color3.fromRGB(255, 0, 0)
        end

        return ValidColor(Settings.Box_Color, DefaultBoxColor)
    end

    local function GetTextColor(plr, textType)
        if not Settings.CustomTextColor then
            return GetESPColor(plr)
        end

        if textType == "Name" then
            return ValidColor(Settings.Name_Color, DefaultTextColor)
        end

        return ValidColor(Settings.Team_Text_Color, DefaultTextColor)
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
        end

        if data.OriginPart then
            data.OriginPart:Destroy()
        end

        for _, object in pairs(data.Library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    nested:Remove()
                end
            else
                object:Remove()
            end
        end

        Objects[plr] = nil
    end

    local function CreateObject(plr)
        if plr == Player or Objects[plr] then
            return
        end

        local gradientObjects = {}

        for i = 1, 24 do
            local square = NewSquare()
            square.Filled = true
            square.Transparency = 0.15
            gradientObjects[i] = square
        end

        local library = {
            TL1 = NewLine(DefaultBoxColor, 2),
            TL2 = NewLine(DefaultBoxColor, 2),
            TR1 = NewLine(DefaultBoxColor, 2),
            TR2 = NewLine(DefaultBoxColor, 2),
            BL1 = NewLine(DefaultBoxColor, 2),
            BL2 = NewLine(DefaultBoxColor, 2),
            BR1 = NewLine(DefaultBoxColor, 2),
            BR2 = NewLine(DefaultBoxColor, 2),

            BoxTop = NewLine(DefaultBoxColor, 2),
            BoxBottom = NewLine(DefaultBoxColor, 2),
            BoxLeft = NewLine(DefaultBoxColor, 2),
            BoxRight = NewLine(DefaultBoxColor, 2),

            Fill = NewSquare(),
            Gradient = gradientObjects,

            Name = NewText(),
            Team = NewText(),

            HealthOutline = NewSquare(),
            HealthBar = NewSquare()
        }

        library.Fill.Filled = true
        library.Fill.Transparency = 0.15

        library.HealthOutline.Filled = false
        library.HealthOutline.Transparency = 1
        library.HealthOutline.Color = DefaultHealthColor

        library.HealthBar.Filled = true
        library.HealthBar.Transparency = 1
        library.HealthBar.Color = DefaultHealthColor

        local originPart = Instance.new("Part")
        originPart.Parent = Workspace
        originPart.Transparency = 1
        originPart.CanCollide = false
        originPart.CanQuery = false
        originPart.CanTouch = false
        originPart.Anchored = true
        originPart.Size = Vector3.new(1, 1, 1)

        local data = {
            Library = library,
            OriginPart = originPart,
            Connection = nil
        }

        Objects[plr] = data

        HideLibrary(library)

        data.Connection = RunService.RenderStepped:Connect(function()
            Camera = Workspace.CurrentCamera

            if not Camera or not Settings.Enabled then
                HideLibrary(library)
                return
            end

            local character = plr.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local head = character and character:FindFirstChild("Head")

            if not character or not humanoid or not root or not head or humanoid.Health <= 0 then
                HideLibrary(library)
                return
            end

            local rootPosition, visible = Camera:WorldToViewportPoint(root.Position)

            if not visible or rootPosition.Z <= 0 then
                HideLibrary(library)
                return
            end

            originPart.Size = Vector3.new(
                root.Size.X,
                root.Size.Y * 1.5,
                root.Size.Z
            )

            originPart.CFrame = CFrame.new(
                root.Position,
                Camera.CFrame.Position
            )

            local sizeX = originPart.Size.X
            local sizeY = originPart.Size.Y

            local topLeft = Camera:WorldToViewportPoint(
                (originPart.CFrame * CFrame.new(sizeX, sizeY, 0)).Position
            )

            local topRight = Camera:WorldToViewportPoint(
                (originPart.CFrame * CFrame.new(-sizeX, sizeY, 0)).Position
            )

            local bottomLeft = Camera:WorldToViewportPoint(
                (originPart.CFrame * CFrame.new(sizeX, -sizeY, 0)).Position
            )

            local bottomRight = Camera:WorldToViewportPoint(
                (originPart.CFrame * CFrame.new(-sizeX, -sizeY, 0)).Position
            )

            local left = math.min(topLeft.X, topRight.X, bottomLeft.X, bottomRight.X)
            local right = math.max(topLeft.X, topRight.X, bottomLeft.X, bottomRight.X)
            local top = math.min(topLeft.Y, topRight.Y, bottomLeft.Y, bottomRight.Y)
            local bottom = math.max(topLeft.Y, topRight.Y, bottomLeft.Y, bottomRight.Y)

            local width = math.max(right - left, 1)
            local height = math.max(bottom - top, 1)

            local distance = (Camera.CFrame.Position - root.Position).Magnitude
            local offset = math.clamp(
                1 / math.max(distance, 0.01) * 750,
                2,
                300
            )

            local color = ValidColor(
                GetESPColor(plr),
                DefaultBoxColor
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

            library.TL1.From = Vector2.new(topLeft.X, topLeft.Y)
            library.TL1.To = Vector2.new(topLeft.X + offset, topLeft.Y)

            library.TL2.From = Vector2.new(topLeft.X, topLeft.Y)
            library.TL2.To = Vector2.new(topLeft.X, topLeft.Y + offset)

            library.TR1.From = Vector2.new(topRight.X, topRight.Y)
            library.TR1.To = Vector2.new(topRight.X - offset, topRight.Y)

            library.TR2.From = Vector2.new(topRight.X, topRight.Y)
            library.TR2.To = Vector2.new(topRight.X, topRight.Y + offset)

            library.BL1.From = Vector2.new(bottomLeft.X, bottomLeft.Y)
            library.BL1.To = Vector2.new(bottomLeft.X + offset, bottomLeft.Y)

            library.BL2.From = Vector2.new(bottomLeft.X, bottomLeft.Y)
            library.BL2.To = Vector2.new(bottomLeft.X, bottomLeft.Y - offset)

            library.BR1.From = Vector2.new(bottomRight.X, bottomRight.Y)
            library.BR1.To = Vector2.new(bottomRight.X - offset, bottomRight.Y)

            library.BR2.From = Vector2.new(bottomRight.X, bottomRight.Y)
            library.BR2.To = Vector2.new(bottomRight.X, bottomRight.Y - offset)

            library.BoxTop.From = Vector2.new(left, top)
            library.BoxTop.To = Vector2.new(right, top)

            library.BoxBottom.From = Vector2.new(left, bottom)
            library.BoxBottom.To = Vector2.new(right, bottom)

            library.BoxLeft.From = Vector2.new(left, top)
            library.BoxLeft.To = Vector2.new(left, bottom)

            library.BoxRight.From = Vector2.new(right, top)
            library.BoxRight.To = Vector2.new(right, bottom)

            library.TL1.Visible = Settings.CornerBox
            library.TL2.Visible = Settings.CornerBox
            library.TR1.Visible = Settings.CornerBox
            library.TR2.Visible = Settings.CornerBox
            library.BL1.Visible = Settings.CornerBox
            library.BL2.Visible = Settings.CornerBox
            library.BR1.Visible = Settings.CornerBox
            library.BR2.Visible = Settings.CornerBox

            library.BoxTop.Visible = Settings.NormalBox
            library.BoxBottom.Visible = Settings.NormalBox
            library.BoxLeft.Visible = Settings.NormalBox
            library.BoxRight.Visible = Settings.NormalBox

            local fillTransparency = tonumber(Settings.Fill_Opacity) or 0.15
            fillTransparency = math.clamp(fillTransparency, 0, 1)

            library.Fill.Transparency = fillTransparency

            for _, object in ipairs(library.Gradient) do
                object.Transparency = fillTransparency
            end

            if Settings.FillBoxGradient then
                library.Fill.Visible = false

                local color1 = ValidColor(
                    Settings.Gradient_Color_1,
                    DefaultBoxColor
                )

                local color2 = ValidColor(
                    Settings.Gradient_Color_2,
                    DefaultBoxColor
                )

                for i = 1, #library.Gradient do
                    local alpha = (i - 1) / (#library.Gradient - 1)
                    local gradientColor = color1:Lerp(color2, alpha)
                    local stripHeight = height / #library.Gradient

                    library.Gradient[i].Visible = true
                    library.Gradient[i].Color = gradientColor
                    library.Gradient[i].Position = Vector2.new(
                        left,
                        top + ((i - 1) * stripHeight)
                    )
                    library.Gradient[i].Size = Vector2.new(
                        width,
                        stripHeight + 1
                    )
                end
            elseif Settings.FillBox then
                library.Fill.Visible = true
                library.Fill.Color = ValidColor(
                    Settings.Fill_Box_Color,
                    DefaultBoxColor
                )
                library.Fill.Position = Vector2.new(left, top)
                library.Fill.Size = Vector2.new(width, height)

                for _, object in ipairs(library.Gradient) do
                    object.Visible = false
                end
            else
                library.Fill.Visible = false

                for _, object in ipairs(library.Gradient) do
                    object.Visible = false
                end
            end

            local nameColor = ValidColor(
                GetTextColor(plr, "Name"),
                DefaultTextColor
            )

            local teamColor = ValidColor(
                GetTextColor(plr, "Team"),
                DefaultTextColor
            )

            local nameScale = tonumber(Settings.Name_Scale) or 14
            nameScale = math.clamp(nameScale, 1, 100)

            library.Name.Visible = Settings.ShowName
            library.Team.Visible = Settings.ShowTeam

            library.Name.Text = tostring(plr.Name)
            library.Name.Color = nameColor
            library.Name.Size = nameScale
            library.Name.Font = Fonts[Settings.Font] or Fonts.UI
            library.Name.Position = Vector2.new(
                (left + right) / 2,
                top - (nameScale + 5)
            )

            local teamName = "Neutral"

            if plr.Team then
                teamName = tostring(plr.Team.Name)
            end

            library.Team.Text = teamName
            library.Team.Color = teamColor
            library.Team.Size = math.max(nameScale - 1, 10)
            library.Team.Font = Fonts[Settings.Font] or Fonts.UI
            library.Team.Position = Vector2.new(
                (left + right) / 2,
                top - (Settings.ShowName and (nameScale + 19) or 18)
            )

            local healthRatio = 0

            if humanoid.MaxHealth and humanoid.MaxHealth > 0 then
                healthRatio = math.clamp(
                    humanoid.Health / humanoid.MaxHealth,
                    0,
                    1
                )
            end

            local healthWidth = 5
            local healthGap = 5

            library.HealthOutline.Color = ValidColor(
                Settings.HealthBorder_Color,
                DefaultHealthColor
            )

            library.HealthBar.Color = ValidColor(
                Settings.HealthFill_Color,
                DefaultHealthColor
            )

            library.HealthOutline.Visible = Settings.ShowHealth
            library.HealthBar.Visible = Settings.ShowHealth

            library.HealthOutline.Position = Vector2.new(
                right + healthGap,
                top
            )

            library.HealthOutline.Size = Vector2.new(
                healthWidth,
                height
            )

            library.HealthBar.Position = Vector2.new(
                right + healthGap + 1,
                bottom - ((height - 2) * healthRatio) - 1
            )

            library.HealthBar.Size = Vector2.new(
                healthWidth - 2,
                math.max((height - 2) * healthRatio, 0)
            )

            local thickness

            if Settings.Autothickness then
                thickness = math.clamp(
                    1 / math.max(distance, 0.01) * 100,
                    1,
                    4
                )
            else
                thickness = tonumber(Settings.Box_Thickness) or 2
            end

            SetThickness({
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
                BoxRight = library.BoxRight,
                HealthOutline = library.HealthOutline
            }, thickness)
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

return ESP