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

    local GradientColumns = 24
    local GradientRows = 32
    local GradientCount = GradientColumns * GradientRows

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
        line.Thickness = thickness or 2
        line.Transparency = 1
        return line
    end

    local function NewSquare()
        local square = Drawing.new("Square")
        square.Visible = false
        square.Position = Vector2.new(0, 0)
        square.Size = Vector2.new(0, 0)
        square.Thickness = 0
        square.Filled = true
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

    local function HideObject(object)
        object.Visible = false
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
            return ValidColor(
                plr.TeamColor.Color,
                DefaultBoxColor
            )
        end

        if Settings.Team_Check then
            if plr.TeamColor
                and Player.TeamColor
                and plr.TeamColor == Player.TeamColor then

                return Color3.fromRGB(0, 255, 0)
            end

            return Color3.fromRGB(255, 0, 0)
        end

        return ValidColor(
            Settings.Box_Color,
            DefaultBoxColor
        )
    end

    local function GetTextColor(plr, textType)
        if not Settings.CustomTextColor then
            return GetESPColor(plr)
        end

        if textType == "Name" then
            return ValidColor(
                Settings.Name_Color,
                DefaultTextColor
            )
        end

        return ValidColor(
            Settings.Team_Text_Color,
            DefaultTextColor
        )
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

    local function EnsureGradient(library)
        if #library.Gradient == GradientCount then
            return
        end

        for _, object in ipairs(library.Gradient) do
            object:Remove()
        end

        table.clear(library.Gradient)

        for _ = 1, GradientCount do
            library.Gradient[#library.Gradient + 1] = NewSquare()
        end
    end

    local function UpdateGradientColors(library, rotation)
        local color1 = ValidColor(
            Settings.Gradient_Color_1,
            DefaultBoxColor
        )

        local color2 = ValidColor(
            Settings.Gradient_Color_2,
            DefaultBoxColor
        )

        local angle = math.rad(rotation)
        local cosAngle = math.cos(angle)
        local sinAngle = math.sin(angle)

        local index = 1

        for y = 0, GradientRows - 1 do
            for x = 0, GradientColumns - 1 do
                local nx = ((x + 0.5) / GradientColumns) * 2 - 1
                local ny = ((y + 0.5) / GradientRows) * 2 - 1

                local rotatedY =
                    nx * sinAngle +
                    ny * cosAngle

                local t = math.clamp(
                    rotatedY * 0.5 + 0.5,
                    0,
                    1
                )

                library.Gradient[index].Color =
                    color1:Lerp(color2, t)

                index += 1
            end
        end
    end

    local function UpdateGradientGeometry(
        library,
        left,
        top,
        width,
        height,
        opacity
    )
        local cellWidth = width / GradientColumns
        local cellHeight = height / GradientRows

        local overlapX = math.min(
            0.75,
            cellWidth * 0.12
        )

        local overlapY = math.min(
            0.75,
            cellHeight * 0.12
        )

        local index = 1

        for y = 0, GradientRows - 1 do
            for x = 0, GradientColumns - 1 do
                local positionX =
                    left +
                    x * cellWidth -
                    overlapX * 0.5

                local positionY =
                    top +
                    y * cellHeight -
                    overlapY * 0.5

                local sizeX =
                    cellWidth +
                    overlapX

                local sizeY =
                    cellHeight +
                    overlapY

                if positionX < left then
                    sizeX -= left - positionX
                    positionX = left
                end

                if positionY < top then
                    sizeY -= top - positionY
                    positionY = top
                end

                local right = positionX + sizeX
                local bottom = positionY + sizeY

                if right > left + width then
                    sizeX -= right - (left + width)
                end

                if bottom > top + height then
                    sizeY -= bottom - (top + height)
                end

                local object = library.Gradient[index]

                object.Position = Vector2.new(
                    positionX,
                    positionY
                )

                object.Size = Vector2.new(
                    math.max(sizeX, 0),
                    math.max(sizeY, 0)
                )

                object.Transparency = opacity
                object.Visible = true

                index += 1
            end
        end
    end

    local function CreateObject(plr)
        if plr == Player or Objects[plr] then
            return
        end

        local gradient = {}

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
            Gradient = gradient,

            Name = NewText(),
            Team = NewText(),

            HealthOutline = NewSquare(
                DefaultHealthBorder
            ),

            HealthBar = NewSquare(
                DefaultHealthFill
            )
        }

        library.HealthOutline.Filled = false
        library.HealthOutline.Color = DefaultHealthBorder

        library.HealthBar.Filled = true
        library.HealthBar.Color = DefaultHealthFill

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
            Connection = nil,

            LastGradientRotation = nil,
            LastGradientColor1 = nil,
            LastGradientColor2 = nil
        }

        Objects[plr] = data

        HideLibrary(library)

        data.Connection = RunService.RenderStepped:Connect(function()
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
            local humanoid =
                character and
                character:FindFirstChildOfClass("Humanoid")

            local root =
                character and
                character:FindFirstChild("HumanoidRootPart")

            local head =
                character and
                character:FindFirstChild("Head")

            if not character
                or not humanoid
                or not root
                or not head
                or humanoid.Health <= 0 then

                HideLibrary(library)
                return
            end

            local rootPosition, visible =
                Camera:WorldToViewportPoint(root.Position)

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

            local topLeft =
                Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(
                            sizeX,
                            sizeY,
                            0
                        )
                    ).Position
                )

            local topRight =
                Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(
                            -sizeX,
                            sizeY,
                            0
                        )
                    ).Position
                )

            local bottomLeft =
                Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(
                            sizeX,
                            -sizeY,
                            0
                        )
                    ).Position
                )

            local bottomRight =
                Camera:WorldToViewportPoint(
                    (
                        originPart.CFrame *
                        CFrame.new(
                            -sizeX,
                            -sizeY,
                            0
                        )
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

            local width = math.max(
                right - left,
                1
            )

            local height = math.max(
                bottom - top,
                1
            )

            local distance =
                (
                    Camera.CFrame.Position -
                    root.Position
                ).Magnitude

            local offset =
                math.clamp(
                    1 /
                        math.max(
                            distance,
                            0.01
                        ) *
                        750,
                    2,
                    300
                )

            local boxColor = GetESPColor(plr)

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

            local boxStyle =
                Settings.BoxStyle or "Corner"

            local corner =
                boxStyle == "Corner"

            local normal =
                boxStyle == "Normal"

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

            local opacity =
                tonumber(
                    Settings.Fill_Opacity
                ) or 0.15

            opacity = math.clamp(
                opacity,
                0,
                1
            )

            if Settings.FillBoxGradient then
                library.Fill.Visible = false

                EnsureGradient(library)

                local rotation =
                    tonumber(
                        Settings.Gradient_Rotation
                    ) or 0

                local color1 =
                    ValidColor(
                        Settings.Gradient_Color_1,
                        DefaultBoxColor
                    )

                local color2 =
                    ValidColor(
                        Settings.Gradient_Color_2,
                        DefaultBoxColor
                    )

                if rotation ~=
                        data.LastGradientRotation
                    or color1 ~=
                        data.LastGradientColor1
                    or color2 ~=
                        data.LastGradientColor2 then

                    data.LastGradientRotation =
                        rotation

                    data.LastGradientColor1 =
                        color1

                    data.LastGradientColor2 =
                        color2

                    UpdateGradientColors(
                        library,
                        rotation
                    )
                end

                UpdateGradientGeometry(
                    library,
                    left,
                    top,
                    width,
                    height,
                    opacity
                )
            else
                for _, object in ipairs(
                    library.Gradient
                ) do
                    object.Visible = false
                end

                if Settings.FillBox then
                    library.Fill.Visible = true
                    library.Fill.Color =
                        ValidColor(
                            Settings.Fill_Box_Color,
                            DefaultBoxColor
                        )

                    library.Fill.Transparency =
                        opacity

                    library.Fill.Position =
                        Vector2.new(
                            left,
                            top
                        )

                    library.Fill.Size =
                        Vector2.new(
                            width,
                            height
                        )
                else
                    library.Fill.Visible = false
                end
            end

            local nameScale =
                tonumber(
                    Settings.Name_Scale
                ) or 14

            nameScale =
                math.clamp(
                    nameScale,
                    1,
                    100
                )

            library.Name.Visible =
                Settings.ShowName

            library.Name.Text =
                tostring(plr.Name)

            library.Name.Color =
                GetTextColor(
                    plr,
                    "Name"
                )

            library.Name.Size =
                nameScale

            library.Name.Font =
                Fonts[
                    Settings.Font
                ] or Fonts.UI

            library.Name.Position =
                Vector2.new(
                    (left + right) / 2,
                    top - nameScale - 5
                )

            library.Team.Visible =
                Settings.ShowTeam

            library.Team.Text =
                plr.Team
                    and tostring(
                        plr.Team.Name
                    )
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
                Fonts[
                    Settings.Font
                ] or Fonts.UI

            library.Team.Position =
                Vector2.new(
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

                healthRatio =
                    math.clamp(
                        humanoid.Health /
                            humanoid.MaxHealth,
                        0,
                        1
                    )
            end

            local healthWidth = 5
            local healthGap = 5

            library.HealthOutline.Visible =
                Settings.ShowHealth

            library.HealthOutline.Color =
                ValidColor(
                    Settings.HealthBorder_Color,
                    DefaultHealthBorder
                )

            library.HealthOutline.Position =
                Vector2.new(
                    right + healthGap,
                    top
                )

            library.HealthOutline.Size =
                Vector2.new(
                    healthWidth,
                    height
                )

            library.HealthBar.Visible =
                Settings.ShowHealth

            library.HealthBar.Color =
                ValidColor(
                    Settings.HealthFill_Color,
                    DefaultHealthFill
                )

            library.HealthBar.Position =
                Vector2.new(
                    right + healthGap + 1,
                    bottom -
                        (
                            (height - 2) *
                            healthRatio
                        ) -
                        1
                )

            library.HealthBar.Size =
                Vector2.new(
                    healthWidth - 2,
                    math.max(
                        (height - 2) *
                        healthRatio,
                        0
                    )
                )

            local thickness

            if Settings.Autothickness then
                thickness =
                    math.clamp(
                        1 /
                            math.max(
                                distance,
                                0.01
                            ) *
                            100,
                        1,
                        4
                    )
            else
                thickness =
                    tonumber(
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
                HealthOutline =
                    library.HealthOutline
            }, thickness)
        end)
    end

    local controller = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateObject(plr)
    end

    controller.PlayerAdded =
        Players.PlayerAdded:Connect(
            function(plr)
                CreateObject(plr)
            end
        )

    controller.PlayerRemoving =
        Players.PlayerRemoving:Connect(
            function(plr)
                DestroyObject(plr)
            end
        )

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