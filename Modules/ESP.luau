local ESP = {}

function ESP.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local Settings = config.Settings
    local UserInputService = config.UserInputService or game:GetService("UserInputService")

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

    local function NewHighlight()
        local highlight = Instance.new("Highlight")
        highlight.Enabled = false
        highlight.FillColor = DefaultBoxColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = nil
        highlight.Parent = nil
        return highlight
    end

    local function HideObject(object)
        if not object then
            return
        end

        if typeof(object) == "Instance" then
            if object:IsA("Highlight") then
                object.Enabled = false
            end
        else
            object.Visible = false
        end
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
                    if nested and nested.Thickness ~= nil then
                        nested.Thickness = thickness
                    end
                end
            elseif object and object.Thickness ~= nil then
                object.Thickness = thickness
            end
        end
    end

    local function GetESPColor(plr)
        if Settings.Rainbow then
            return Color3.fromHSV((tick() % 5) / 5, 0.6, 1)
        end

        if Settings.Team_Color and plr.TeamColor then
            return ValidColor(plr.TeamColor.Color, DefaultBoxColor)
        end

        if Settings.Team_Check then
            if plr.TeamColor
                and Player.TeamColor
                and plr.TeamColor == Player.TeamColor then
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

    local function IsTeamBlocked(plr)
        if not Settings.Team_Check then
            return false
        end

        if not plr.TeamColor or not Player.TeamColor then
            return false
        end

        return plr.TeamColor == Player.TeamColor
    end

    local function DestroyDrawing(object)
        if object then
            pcall(function()
                object:Remove()
            end)
        end
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
            data.Connection = nil
        end

        if data.OriginPart then
            data.OriginPart:Destroy()
            data.OriginPart = nil
        end

        if data.Chams then
            data.Chams:Destroy()
            data.Chams = nil
        end

        if data.Library then
            for _, object in pairs(data.Library) do
                if typeof(object) == "table" then
                    for _, nested in pairs(object) do
                        DestroyDrawing(nested)
                    end
                else
                    DestroyDrawing(object)
                end
            end
        end

        Objects[plr] = nil
    end

    local function GetTracerOrigin()
        local viewport = Camera.ViewportSize
        local tracerSettings = Settings.Tracers or {}
        local origin = tracerSettings.Origin or "Bottom"

        if origin == "Center" then
            return Vector2.new(
                viewport.X / 2,
                viewport.Y / 2
            )
        end

        if origin == "Mouse" then
            return UserInputService:GetMouseLocation()
        end

        return Vector2.new(
            viewport.X / 2,
            viewport.Y
        )
    end

    local function GetCharacterBounds(character)
        local parts = {}

        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("BasePart") then
                table.insert(parts, object)
            end
        end

        if #parts == 0 then
            return nil
        end

        local minX = math.huge
        local minY = math.huge
        local maxX = -math.huge
        local maxY = -math.huge
        local anyVisible = false

        for _, part in ipairs(parts) do
            local cf = part.CFrame
            local half = part.Size / 2

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
                local position, visible = Camera:WorldToViewportPoint(corner)

                if position.Z > 0 then
                    anyVisible = anyVisible or visible
                    minX = math.min(minX, position.X)
                    minY = math.min(minY, position.Y)
                    maxX = math.max(maxX, position.X)
                    maxY = math.max(maxY, position.Y)
                end
            end
        end

        if not anyVisible or minX == math.huge then
            return nil
        end

        return minX, minY, maxX, maxY
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
            HealthBar = NewSquare(DefaultHealthFill),
            Tracer = NewLine()
        }

        library.HealthOutline.Filled = false
        library.HealthOutline.Color = DefaultHealthBorder
        library.HealthBar.Filled = true
        library.HealthBar.Color = DefaultHealthFill

        local chams = NewHighlight()

        local data = {
            Library = library,
            Chams = chams,
            Connection = nil
        }

        Objects[plr] = data

        HideLibrary(library)

        data.Connection = RunService.RenderStepped:Connect(function()
            Camera = Workspace.CurrentCamera

            if not Camera then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            if not Settings.Enabled then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            local character = plr.Character

            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")

            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            local head = character
                and character:FindFirstChild("Head")

            if not character
                or not humanoid
                or not root
                or not head
                or humanoid.Health <= 0 then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            if IsTeamBlocked(plr) then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            local rootPosition, rootVisible =
                Camera:WorldToViewportPoint(root.Position)

            if rootPosition.Z <= 0 then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            local bounds = GetCharacterBounds(character)

            if not bounds then
                HideLibrary(library)
                chams.Enabled = false
                return
            end

            local left, top, right, bottom = bounds

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

            local cornerLength = math.clamp(
                tonumber(Settings.Corner_Length) or math.min(width, height) * 0.25,
                1,
                math.max(width, height)
            )

            cornerLength = math.min(
                cornerLength,
                width / 2,
                height / 2
            )

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

            local opacity = tonumber(Settings.Fill_Opacity) or 0.15

            opacity = math.clamp(
                opacity,
                0,
                1
            )

            if Settings.FillBox then
                library.Fill.Visible = true
                library.Fill.Color = ValidColor(
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
            end

            local nameScale =
                tonumber(Settings.Name_Scale) or 14

            nameScale = math.clamp(
                nameScale,
                1,
                100
            )

            library.Name.Visible =
                Settings.ShowName == true

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
                Fonts[Settings.Font] or Fonts.UI

            library.Name.Position =
                Vector2.new(
                    (left + right) / 2,
                    top - nameScale - 5
                )

            library.Team.Visible =
                Settings.ShowTeam == true

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
                Fonts[Settings.Font] or Fonts.UI

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
                Settings.ShowHealth == true

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
                Settings.ShowHealth == true

            library.HealthBar.Color =
                ValidColor(
                    Settings.HealthFill_Color,
                    DefaultHealthFill
                )

            library.HealthBar.Position =
                Vector2.new(
                    right + healthGap + 1,
                    bottom -
                        ((height - 2) * healthRatio) -
                        1
                )

            library.HealthBar.Size =
                Vector2.new(
                    healthWidth - 2,
                    math.max(
                        (height - 2) * healthRatio,
                        0
                    )
                )

            local tracerSettings =
                typeof(Settings.Tracers) == "table"
                and Settings.Tracers
                or {}

            local tracerEnabled =
                tracerSettings.Enabled == true

            library.Tracer.Visible = tracerEnabled

            if tracerEnabled then
                local tracerOrigin =
                    GetTracerOrigin()

                library.Tracer.From =
                    tracerOrigin

                library.Tracer.To =
                    Vector2.new(
                        rootPosition.X,
                        rootPosition.Y
                    )

                library.Tracer.Color =
                    Settings.Rainbow
                    and Color3.fromHSV(
                        (tick() % 5) / 5,
                        0.6,
                        1
                    )
                    or ValidColor(
                        tracerSettings.Color,
                        DefaultBoxColor
                    )

                library.Tracer.Thickness =
                    math.max(
                        tonumber(
                            tracerSettings.Thickness
                        ) or 1,
                        1
                    )

                library.Tracer.Transparency =
                    math.clamp(
                        tonumber(
                            tracerSettings.Transparency
                        ) or 1,
                        0,
                        1
                    )
            end

            local chamsSettings =
                typeof(Settings.Chams) == "table"
                and Settings.Chams
                or {}

            if chamsSettings.Enabled == true then
                if chams.Parent ~= Workspace then
                    chams.Parent = Workspace
                end

                chams.Adornee = character

                chams.FillColor =
                    Settings.Rainbow
                    and Color3.fromHSV(
                        (tick() % 5) / 5,
                        0.6,
                        1
                    )
                    or ValidColor(
                        chamsSettings.FillColor,
                        boxColor
                    )

                chams.FillTransparency =
                    math.clamp(
                        tonumber(
                            chamsSettings.FillTransparency
                        ) or 0.5,
                        0,
                        1
                    )

                chams.OutlineColor =
                    Settings.Rainbow
                    and Color3.fromHSV(
                        (tick() % 5) / 5,
                        0.6,
                        1
                    )
                    or ValidColor(
                        chamsSettings.OutlineColor,
                        boxColor
                    )

                chams.OutlineTransparency =
                    math.clamp(
                        tonumber(
                            chamsSettings.OutlineTransparency
                        ) or 0,
                        0,
                        1
                    )

                chams.DepthMode =
                    chamsSettings.AlwaysOnTop == true
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or Enum.HighlightDepthMode.Occluded

                chams.Enabled = true
            else
                chams.Enabled = false
                chams.Adornee = nil
            end

            local thickness

            if Settings.Autothickness == true then
                thickness =
                    math.clamp(
                        100 /
                            math.max(
                                distance,
                                0.01
                            ),
                        1,
                        4
                    )
            else
                thickness =
                    tonumber(
                        Settings.Box_Thickness
                    ) or 2
            end

            thickness = math.max(
                thickness,
                1
            )

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

            library.HealthOutline.Thickness = 1
            library.Tracer.Thickness =
                math.max(
                    tonumber(tracerSettings.Thickness) or 1,
                    1
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