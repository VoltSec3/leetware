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

    local GradientSegments = 48

    local function Color(value, fallback)
        if typeof(value) == "Color3" then
            return value
        end

        return fallback
    end

    local function NewLine(color, thickness)
        local object = Drawing.new("Line")
        object.Visible = false
        object.From = Vector2.new(0, 0)
        object.To = Vector2.new(0, 0)
        object.Color = Color(color, DefaultBoxColor)
        object.Thickness = thickness or 2
        object.Transparency = 1
        return object
    end

    local function NewSquare(color)
        local object = Drawing.new("Square")
        object.Visible = false
        object.Position = Vector2.new(0, 0)
        object.Size = Vector2.new(0, 0)
        object.Thickness = 1
        object.Filled = false
        object.Transparency = 1
        object.Color = Color(color, DefaultBoxColor)
        return object
    end

    local function NewText()
        local object = Drawing.new("Text")
        object.Visible = false
        object.Text = ""
        object.Size = 14
        object.Center = true
        object.Outline = true
        object.OutlineColor = Color3.fromRGB(0, 0, 0)
        object.Position = Vector2.new(0, 0)
        object.Font = Fonts.UI
        object.Transparency = 1
        object.Color = DefaultTextColor
        return object
    end

    local function NewGradientObjects()
        local objects = {}

        for i = 1, GradientSegments do
            local success, object = pcall(function()
                return Drawing.new("Quad")
            end)

            if not success or not object then
                break
            end

            object.Visible = false
            object.PointA = Vector2.new(0, 0)
            object.PointB = Vector2.new(0, 0)
            object.PointC = Vector2.new(0, 0)
            object.PointD = Vector2.new(0, 0)
            object.Thickness = 0
            object.Filled = true
            object.Transparency = 1
            object.Color = DefaultBoxColor

            objects[#objects + 1] = object
        end

        return objects
    end

    local function HideObject(object)
        pcall(function()
            object.Visible = false
        end)
    end

    local function HideLibrary(library)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    HideObject(nested)
                end
            else
                HideObject(object)
            end
        end
    end

    local function SetThickness(library, thickness)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    pcall(function()
                        nested.Thickness = thickness
                    end)
                end
            else
                pcall(function()
                    object.Thickness = thickness
                end)
            end
        end
    end

    local function GetBoxColor(plr)
        if Settings.Rainbow then
            return Color3.fromHSV((tick() % 5) / 5, 0.6, 1)
        end

        if Settings.Team_Color and plr.TeamColor then
            return Color(
                plr.TeamColor.Color,
                DefaultBoxColor
            )
        end

        if Settings.Team_Check then
            if plr.TeamColor and Player.TeamColor and plr.TeamColor == Player.TeamColor then
                return Color3.fromRGB(0, 255, 0)
            end

            return Color3.fromRGB(255, 0, 0)
        end

        return Color(Settings.Box_Color, DefaultBoxColor)
    end

    local function GetTextColor(plr, textType)
        if not Settings.CustomTextColor then
            return GetBoxColor(plr)
        end

        if textType == "Name" then
            return Color(Settings.Name_Color, DefaultTextColor)
        end

        return Color(Settings.Team_Text_Color, DefaultTextColor)
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
                    pcall(function()
                        nested:Remove()
                    end)
                end
            else
                pcall(function()
                    object:Remove()
                end)
            end
        end

        Objects[plr] = nil
    end

    local function UpdateGradient(library, left, top, width, height, opacity)
        if #library.Gradient == 0 then
            return
        end

        local color1 = Color(
            Settings.Gradient_Color_1,
            DefaultBoxColor
        )

        local color2 = Color(
            Settings.Gradient_Color_2,
            DefaultBoxColor
        )

        local rotation = math.rad(
            tonumber(Settings.Gradient_Rotation) or 0
        )

        local cosAngle = math.cos(rotation)
        local sinAngle = math.sin(rotation)

        local centerX = left + width * 0.5
        local centerY = top + height * 0.5

        local diagonal = math.sqrt(
            width * width +
            height * height
        )

        local segmentHeight = (diagonal * 2) / #library.Gradient

        for index, quad in ipairs(library.Gradient) do
            local y1 = -diagonal + segmentHeight * (index - 1)
            local y2 = y1 + segmentHeight + 0.75

            local p1x = -diagonal
            local p2x = diagonal

            local function RotatePoint(x, y)
                return Vector2.new(
                    centerX + x * cosAngle - y * sinAngle,
                    centerY + x * sinAngle + y * cosAngle
                )
            end

            local pointA = RotatePoint(p1x, y1)
            local pointB = RotatePoint(p2x, y1)
            local pointC = RotatePoint(p2x, y2)
            local pointD = RotatePoint(p1x, y2)

            local t = math.clamp(
                (index - 0.5) / #library.Gradient,
                0,
                1
            )

            local gradientColor = color1:Lerp(color2, t)

            quad.PointA = pointA
            quad.PointB = pointB
            quad.PointC = pointC
            quad.PointD = pointD
            quad.Color = gradientColor
            quad.Transparency = opacity
            quad.Visible = true
        end

        local clipLeft = left
        local clipTop = top
        local clipRight = left + width
        local clipBottom = top + height

        for _, quad in ipairs(library.Gradient) do
            local minX = math.min(
                quad.PointA.X,
                quad.PointB.X,
                quad.PointC.X,
                quad.PointD.X
            )

            local maxX = math.max(
                quad.PointA.X,
                quad.PointB.X,
                quad.PointC.X,
                quad.PointD.X
            )

            local minY = math.min(
                quad.PointA.Y,
                quad.PointB.Y,
                quad.PointC.Y,
                quad.PointD.Y
            )

            local maxY = math.max(
                quad.PointA.Y,
                quad.PointB.Y,
                quad.PointC.Y,
                quad.PointD.Y
            )

            if maxX < clipLeft
                or minX > clipRight
                or maxY < clipTop
                or minY > clipBottom then

                quad.Visible = false
            elseif math.abs(rotation % math.pi) < 0.0001 then
                quad.PointA = Vector2.new(
                    math.clamp(quad.PointA.X, clipLeft, clipRight),
                    math.clamp(quad.PointA.Y, clipTop, clipBottom)
                )

                quad.PointB = Vector2.new(
                    math.clamp(quad.PointB.X, clipLeft, clipRight),
                    math.clamp(quad.PointB.Y, clipTop, clipBottom)
                )

                quad.PointC = Vector2.new(
                    math.clamp(quad.PointC.X, clipLeft, clipRight),
                    math.clamp(quad.PointC.Y, clipTop, clipBottom)
                )

                quad.PointD = Vector2.new(
                    math.clamp(quad.PointD.X, clipLeft, clipRight),
                    math.clamp(quad.PointD.Y, clipTop, clipBottom)
                )
            end
        end
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

            Gradient = NewGradientObjects(),

            Name = NewText(),
            Team = NewText(),

            HealthOutline = NewSquare(DefaultHealthColor),
            HealthBar = NewSquare(DefaultHealthColor)
        }

        library.Fill.Filled = true
        library.HealthOutline.Filled = false
        library.HealthBar.Filled = true

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
            local success = pcall(function()
                Camera = Workspace.CurrentCamera

                if not Camera then
                    HideLibrary(library)
                    return
                end

                if not Settings.Enabled then
                    HideLibrary(library)
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

                    HideLibrary(library)
                    return
                end

                local rootPosition, visible = Camera:WorldToViewportPoint(
                    root.Position
                )

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
                    (
                        originPart.CFrame *
                        CFrame.new(sizeX, sizeY, 0)
                    ).Position
                )

                local topRight = Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(-sizeX, sizeY, 0)
                    ).Position
                )

                local bottomLeft = Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(sizeX, -sizeY, 0)
                    ).Position
                )

                local bottomRight = Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(-sizeX, -sizeY, 0)
                    ).Position
                )

                local left = math.min(
                    topLeft.X,
                    topRight.X,
                    bottomLeft.X,
                    bottomRight.X
                )

                local right = math.max(
                    topLeft.X,
                    topRight.X,
                    bottomLeft.X,
                    bottomRight.X
                )

                local top = math.min(
                    topLeft.Y,
                    topRight.Y,
                    bottomLeft.Y,
                    bottomRight.Y
                )

                local bottom = math.max(
                    topLeft.Y,
                    topRight.Y,
                    bottomLeft.Y,
                    bottomRight.Y
                )

                local width = math.max(right - left, 1)
                local height = math.max(bottom - top, 1)

                local distance = (
                    Camera.CFrame.Position -
                    root.Position
                ).Magnitude

                local offset = math.clamp(
                    1 / math.max(distance, 0.01) * 750,
                    2,
                    300
                )

                local boxColor = GetBoxColor(plr)

                library.TL1.Color = boxColor
                library.TL2.Color = boxColor
                library.TR1.Color = boxColor
                library.TR2.Color = boxColor
                library.BL1.Color = boxColor
                library.BL2.Color = boxColor
                library.BR1.Color = boxColor
                library.BR2.Color = boxColor

                library.BoxTop.Color = boxColor
                library.BoxBottom.Color = boxColor
                library.BoxLeft.Color = boxColor
                library.BoxRight.Color = boxColor

                library.TL1.From = Vector2.new(
                    topLeft.X,
                    topLeft.Y
                )

                library.TL1.To = Vector2.new(
                    topLeft.X + offset,
                    topLeft.Y
                )

                library.TL2.From = Vector2.new(
                    topLeft.X,
                    topLeft.Y
                )

                library.TL2.To = Vector2.new(
                    topLeft.X,
                    topLeft.Y + offset
                )

                library.TR1.From = Vector2.new(
                    topRight.X,
                    topRight.Y
                )

                library.TR1.To = Vector2.new(
                    topRight.X - offset,
                    topRight.Y
                )

                library.TR2.From = Vector2.new(
                    topRight.X,
                    topRight.Y
                )

                library.TR2.To = Vector2.new(
                    topRight.X,
                    topRight.Y + offset
                )

                library.BL1.From = Vector2.new(
                    bottomLeft.X,
                    bottomLeft.Y
                )

                library.BL1.To = Vector2.new(
                    bottomLeft.X + offset,
                    bottomLeft.Y
                )

                library.BL2.From = Vector2.new(
                    bottomLeft.X,
                    bottomLeft.Y
                )

                library.BL2.To = Vector2.new(
                    bottomLeft.X,
                    bottomLeft.Y - offset
                )

                library.BR1.From = Vector2.new(
                    bottomRight.X,
                    bottomRight.Y
                )

                library.BR1.To = Vector2.new(
                    bottomRight.X - offset,
                    bottomRight.Y
                )

                library.BR2.From = Vector2.new(
                    bottomRight.X,
                    bottomRight.Y
                )

                library.BR2.To = Vector2.new(
                    bottomRight.X,
                    bottomRight.Y - offset
                )

                library.BoxTop.From = Vector2.new(
                    left,
                    top
                )

                library.BoxTop.To = Vector2.new(
                    right,
                    top
                )

                library.BoxBottom.From = Vector2.new(
                    left,
                    bottom
                )

                library.BoxBottom.To = Vector2.new(
                    right,
                    bottom
                )

                library.BoxLeft.From = Vector2.new(
                    left,
                    top
                )

                library.BoxLeft.To = Vector2.new(
                    left,
                    bottom
                )

                library.BoxRight.From = Vector2.new(
                    right,
                    top
                )

                library.BoxRight.To = Vector2.new(
                    right,
                    bottom
                )

                local boxStyle = Settings.BoxStyle or "Corner"

                local corner = boxStyle == "Corner"
                local normal = boxStyle == "Normal"

                library.TL1.Visible = corner
                library.TL2.Visible = corner
                library.TR1.Visible = corner
                library.TR2.Visible = corner
                library.BL1.Visible = corner
                library.BL2.Visible = corner
                library.BR1.Visible = corner
                library.BR2.Visible = corner

                library.BoxTop.Visible = normal
                library.BoxBottom.Visible = normal
                library.BoxLeft.Visible = normal
                library.BoxRight.Visible = normal

                local opacity = tonumber(
                    Settings.Fill_Opacity
                ) or 0.15

                opacity = math.clamp(opacity, 0, 1)

                if Settings.FillBoxGradient
                    and #library.Gradient > 0 then

                    library.Fill.Visible = false

                    UpdateGradient(
                        library,
                        left,
                        top,
                        width,
                        height,
                        opacity
                    )

                elseif Settings.FillBox then
                    for _, gradientObject in ipairs(library.Gradient) do
                        gradientObject.Visible = false
                    end

                    library.Fill.Visible = true
                    library.Fill.Color = Color(
                        Settings.Fill_Box_Color,
                        DefaultBoxColor
                    )
                    library.Fill.Transparency = opacity
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

                    for _, gradientObject in ipairs(library.Gradient) do
                        gradientObject.Visible = false
                    end
                end

                local nameScale = tonumber(
                    Settings.Name_Scale
                ) or 14

                nameScale = math.clamp(
                    nameScale,
                    1,
                    100
                )

                library.Name.Visible = Settings.ShowName
                library.Name.Text = tostring(plr.Name)
                library.Name.Color = GetTextColor(plr, "Name")
                library.Name.Size = nameScale
                library.Name.Font = Fonts[Settings.Font] or Fonts.UI
                library.Name.Position = Vector2.new(
                    (left + right) / 2,
                    top - nameScale - 5
                )

                library.Team.Visible = Settings.ShowTeam
                library.Team.Text = plr.Team
                    and tostring(plr.Team.Name)
                    or "Neutral"

                library.Team.Color = GetTextColor(plr, "Team")
                library.Team.Size = math.max(
                    nameScale - 1,
                    10
                )

                library.Team.Font = Fonts[Settings.Font] or Fonts.UI

                library.Team.Position = Vector2.new(
                    (left + right) / 2,
                    top - (
                        Settings.ShowName
                        and nameScale + 19
                        or 18
                    )
                )

                local healthRatio = 0

                if humanoid.MaxHealth
                    and humanoid.MaxHealth > 0 then

                    healthRatio = math.clamp(
                        humanoid.Health / humanoid.MaxHealth,
                        0,
                        1
                    )
                end

                local healthWidth = 5
                local healthGap = 5

                library.HealthOutline.Visible = Settings.ShowHealth
                library.HealthOutline.Color = Color(
                    Settings.HealthBorder_Color,
                    DefaultHealthColor
                )

                library.HealthOutline.Position = Vector2.new(
                    right + healthGap,
                    top
                )

                library.HealthOutline.Size = Vector2.new(
                    healthWidth,
                    height
                )

                library.HealthBar.Visible = Settings.ShowHealth
                library.HealthBar.Color = Color(
                    Settings.HealthFill_Color,
                    DefaultHealthColor
                )

                library.HealthBar.Position = Vector2.new(
                    right + healthGap + 1,
                    bottom - ((height - 2) * healthRatio) - 1
                )

                library.HealthBar.Size = Vector2.new(
                    healthWidth - 2,
                    math.max(
                        (height - 2) * healthRatio,
                        0
                    )
                )

                local thickness

                if Settings.Autothickness then
                    thickness = math.clamp(
                        1 / math.max(distance, 0.01) * 100,
                        1,
                        4
                    )
                else
                    thickness = tonumber(
                        Settings.Box_Thickness
                    ) or 2
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

            if not success then
                HideLibrary(library)
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