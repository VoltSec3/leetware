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

    local function NewLine(color, thickness)
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = color
        line.Thickness = thickness
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
        return text
    end

    local function SetLibraryVisible(library, state)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    nested.Visible = state
                end
            else
                object.Visible = state
            end
        end
    end

    local function SetColor(library, color)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    nested.Color = color
                end
            else
                object.Color = color
            end
        end
    end

    local function SetThickness(library, thickness)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    if nested.Thickness then
                        nested.Thickness = thickness
                    end
                end
            else
                if object.Thickness then
                    object.Thickness = thickness
                end
            end
        end
    end

    local function GetESPColor(plr)
        if Settings.Rainbow then
            local hue = (tick() % 5) / 5
            return Color3.fromHSV(hue, 0.6, 1)
        end

        if Settings.Team_Color then
            return plr.TeamColor.Color
        end

        if Settings.Team_Check then
            if plr.TeamColor == Player.TeamColor then
                return Color3.fromRGB(0, 255, 0)
            end

            return Color3.fromRGB(255, 0, 0)
        end

        return Settings.Box_Color
    end

    local function GetTextColor(plr, type)
        if not Settings.CustomTextColor then
            return GetESPColor(plr)
        end

        if type == "Name" then
            return Settings.Name_Color
        end

        return Settings.Team_Text_Color
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
        if plr == Player then
            return
        end

        if Objects[plr] then
            return
        end

        local gradientObjects = {}

        for i = 1, 24 do
            local square = NewSquare()
            square.Filled = true
            square.Transparency = Settings.Fill_Opacity
            gradientObjects[i] = square
        end

        local library = {
            TL1 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            TL2 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            TR1 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            TR2 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BL1 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BL2 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BR1 = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BR2 = NewLine(Settings.Box_Color, Settings.Box_Thickness),

            BoxTop = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BoxBottom = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BoxLeft = NewLine(Settings.Box_Color, Settings.Box_Thickness),
            BoxRight = NewLine(Settings.Box_Color, Settings.Box_Thickness),

            Fill = NewSquare(),
            Gradient = gradientObjects,

            Name = NewText(),
            Team = NewText(),

            HealthOutline = NewSquare(),
            HealthBar = NewSquare()
        }

        library.Fill.Filled = true
        library.Fill.Transparency = Settings.Fill_Opacity

        library.HealthOutline.Filled = false
        library.HealthOutline.Transparency = 1

        library.HealthBar.Filled = true
        library.HealthBar.Transparency = 1
        library.HealthBar.Color = Settings.HealthBar_Color

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

        SetLibraryVisible(library, false)

        data.Connection = RunService.RenderStepped:Connect(function()
            Camera = Workspace.CurrentCamera

            if not Camera then
                SetLibraryVisible(library, false)
                return
            end

            if not Settings.Enabled then
                SetLibraryVisible(library, false)
                return
            end

            local character = plr.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local head = character and character:FindFirstChild("Head")

            if not character or not humanoid or not root or not head or humanoid.Health <= 0 then
                SetLibraryVisible(library, false)
                return
            end

            local rootPosition, visible = Camera:WorldToViewportPoint(root.Position)

            if not visible or rootPosition.Z <= 0 then
                SetLibraryVisible(library, false)
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
            local offset = math.clamp(1 / distance * 750, 2, 300)

            local color = GetESPColor(plr)

            SetColor({
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
            }, color)

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

            library.Fill.Transparency = Settings.Fill_Opacity

            for _, object in ipairs(library.Gradient) do
                object.Transparency = Settings.Fill_Opacity
            end

            if Settings.FillBoxGradient then
                library.Fill.Visible = false

                for i = 1, #library.Gradient do
                    local alpha = (i - 1) / (#library.Gradient - 1)
                    local gradientColor = Settings.Gradient_Color_1:Lerp(Settings.Gradient_Color_2, alpha)
                    local stripHeight = height / #library.Gradient

                    library.Gradient[i].Visible = true
                    library.Gradient[i].Color = gradientColor
                    library.Gradient[i].Position = Vector2.new(left, top + ((i - 1) * stripHeight))
                    library.Gradient[i].Size = Vector2.new(width, stripHeight + 1)
                end
            elseif Settings.FillBox then
                library.Fill.Visible = true
                library.Fill.Color = Settings.Fill_Box_Color
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

            local nameColor = GetTextColor(plr, "Name")
            local teamColor = GetTextColor(plr, "Team")

            library.Name.Visible = Settings.ShowName
            library.Team.Visible = Settings.ShowTeam

            library.Name.Text = plr.Name
            library.Name.Color = nameColor
            library.Name.Size = Settings.Name_Scale
            library.Name.Font = Fonts[Settings.Font] or Fonts.UI
            library.Name.Position = Vector2.new(
                (left + right) / 2,
                top - (Settings.Name_Scale + 5)
            )

            library.Team.Text = plr.Team and plr.Team.Name or "Neutral"
            library.Team.Color = teamColor
            library.Team.Size = math.max(Settings.Name_Scale - 1, 10)
            library.Team.Font = Fonts[Settings.Font] or Fonts.UI
            library.Team.Position = Vector2.new(
                (left + right) / 2,
                top - (Settings.ShowName and (Settings.Name_Scale + 19) or 18)
            )

            local healthRatio = 0

            if humanoid.MaxHealth > 0 then
                healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            end

            local healthWidth = 5
            local healthGap = 5

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

            library.HealthBar.Color = Settings.HealthBar_Color

            if Settings.Autothickness then
                local value = math.clamp(1 / distance * 100, 1, 4)

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
                }, value)
            else
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
                }, Settings.Box_Thickness)
            end
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