local ESP = {}
ESP.__index = ESP

function ESP.new(config)
    local self = setmetatable({}, ESP)

    self.Players = config.Players
    self.RunService = config.RunService
    self.Workspace = config.Workspace
    self.Player = config.Player
    self.Settings = config.Settings
    self.Camera = self.Workspace.CurrentCamera

    self.Objects = {}

    self.Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3
    }

    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "LeetwareESP"
    self.Gui.IgnoreGuiInset = true
    self.Gui.ResetOnSpawn = false
    self.Gui.DisplayOrder = 0
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    pcall(function()
        self.Gui.Parent = game:GetService("CoreGui")
    end)

    if not self.Gui.Parent then
        self.Gui.Parent = self.Player:WaitForChild("PlayerGui")
    end

    self.Connection = self.RunService.RenderStepped:Connect(function()
        self:Update()
    end)

    for _, player in ipairs(self.Players:GetPlayers()) do
        self:AddPlayer(player)
    end

    self.PlayerAddedConnection = self.Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)

    self.PlayerRemovingConnection = self.Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)

    return self
end

function ESP:NewLine()
    local object = Drawing.new("Line")
    object.Visible = false
    object.Transparency = 1
    object.Thickness = 2
    object.Color = Color3.new(1, 1, 1)
    object.From = Vector2.zero
    object.To = Vector2.zero
    return object
end

function ESP:NewText()
    local object = Drawing.new("Text")
    object.Visible = false
    object.Transparency = 1
    object.Color = Color3.new(1, 1, 1)
    object.Outline = true
    object.OutlineColor = Color3.new(0, 0, 0)
    object.Center = true
    object.Size = 14
    object.Font = 0
    object.Position = Vector2.zero
    return object
end

function ESP:NewSquare()
    local object = Drawing.new("Square")
    object.Visible = false
    object.Transparency = 1
    object.Filled = false
    object.Thickness = 1
    object.Color = Color3.new(1, 1, 1)
    object.Position = Vector2.zero
    object.Size = Vector2.zero
    return object
end

function ESP:SetVisible(objects, visible)
    for _, object in pairs(objects) do
        if object then
            object.Visible = visible
        end
    end
end

function ESP:SetColor(objects, color)
    if not color then
        return
    end

    for _, object in pairs(objects) do
        if object then
            object.Color = color
        end
    end
end

function ESP:SetThickness(objects, thickness)
    for _, object in pairs(objects) do
        if object then
            object.Thickness = thickness
        end
    end
end

function ESP:DestroyDrawing(object)
    if object then
        pcall(function()
            object:Remove()
        end)
    end
end

function ESP:CreateFill()
    local frame = Instance.new("Frame")
    frame.Name = "GradientFill"
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Position = UDim2.fromOffset(0, 0)
    frame.Size = UDim2.fromOffset(0, 0)
    frame.ZIndex = 0
    frame.ClipsDescendants = true

    local gradient = Instance.new("UIGradient")
    gradient.Name = "Gradient"
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
    })
    gradient.Rotation = 0
    gradient.Parent = frame

    frame.Parent = self.Gui

    return frame, gradient
end

function ESP:AddPlayer(player)
    if player == self.Player or self.Objects[player] then
        return
    end

    local corners = {
        TL1 = self:NewLine(),
        TL2 = self:NewLine(),
        TR1 = self:NewLine(),
        TR2 = self:NewLine(),
        BL1 = self:NewLine(),
        BL2 = self:NewLine(),
        BR1 = self:NewLine(),
        BR2 = self:NewLine()
    }

    local normalBox = self:NewSquare()

    local name = self:NewText()
    local team = self:NewText()

    local healthBorder = self:NewSquare()
    local healthFill = self:NewSquare()

    local fillFrame, fillGradient = self:CreateFill()

    local object = {
        Player = player,
        Corners = corners,
        NormalBox = normalBox,
        Name = name,
        Team = team,
        HealthBorder = healthBorder,
        HealthFill = healthFill,
        Fill = fillFrame,
        Gradient = fillGradient
    }

    self.Objects[player] = object
end

function ESP:RemovePlayer(player)
    local object = self.Objects[player]

    if not object then
        return
    end

    for _, drawing in pairs(object.Corners) do
        self:DestroyDrawing(drawing)
    end

    self:DestroyDrawing(object.NormalBox)
    self:DestroyDrawing(object.Name)
    self:DestroyDrawing(object.Team)
    self:DestroyDrawing(object.HealthBorder)
    self:DestroyDrawing(object.HealthFill)

    if object.Fill then
        object.Fill:Destroy()
    end

    self.Objects[player] = nil
end

function ESP:GetColor(player)
    local settings = self.Settings

    if settings.Rainbow then
        local hue = (tick() % 5) / 5
        return Color3.fromHSV(hue, 0.6, 1)
    end

    if settings.Team_Color then
        return player.TeamColor.Color
    end

    if settings.Team_Check then
        if player.TeamColor == self.Player.TeamColor then
            return Color3.fromRGB(0, 255, 0)
        end

        return Color3.fromRGB(255, 0, 0)
    end

    return settings.Box_Color
end

function ESP:GetCharacterBounds(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        return nil
    end

    local rootPosition = root.Position

    local height = humanoid.HipHeight + 3.2

    local topPosition = rootPosition + Vector3.new(0, height, 0)
    local bottomPosition = rootPosition - Vector3.new(0, 3, 0)

    local top, topVisible = self.Camera:WorldToViewportPoint(topPosition)
    local bottom, bottomVisible = self.Camera:WorldToViewportPoint(bottomPosition)

    if not topVisible and not bottomVisible then
        return nil
    end

    local center = rootPosition

    local leftWorld = center - self.Camera.CFrame.RightVector * 2
    local rightWorld = center + self.Camera.CFrame.RightVector * 2

    local left = self.Camera:WorldToViewportPoint(leftWorld)
    local right = self.Camera:WorldToViewportPoint(rightWorld)

    local heightPixels = math.abs(bottom.Y - top.Y)
    local widthPixels = math.abs(right.X - left.X)

    local distance = (self.Camera.CFrame.Position - rootPosition).Magnitude

    local scale = math.clamp(45 / math.max(distance, 1), 0.35, 3)

    widthPixels = math.max(widthPixels * scale, heightPixels * 0.32)
    heightPixels = math.max(heightPixels, 20)

    local x = (left.X + right.X) * 0.5
    local y = (top.Y + bottom.Y) * 0.5

    return {
        X = x - widthPixels * 0.5,
        Y = y - heightPixels * 0.5,
        Width = widthPixels,
        Height = heightPixels,
        Distance = distance
    }
end

function ESP:UpdateFill(object, bounds, color)
    local settings = self.Settings
    local fill = object.Fill
    local gradient = object.Gradient

    if not settings.FillBox then
        fill.Visible = false
        return
    end

    fill.Visible = true

    local x = math.floor(bounds.X)
    local y = math.floor(bounds.Y)
    local width = math.ceil(bounds.Width)
    local height = math.ceil(bounds.Height)

    fill.Position = UDim2.fromOffset(x, y)
    fill.Size = UDim2.fromOffset(width, height)

    fill.BackgroundTransparency = math.clamp(settings.Fill_Opacity, 0, 1)

    if settings.FillBoxGradient then
        fill.BackgroundColor3 = Color3.new(1, 1, 1)

        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, settings.Gradient_Color_1),
            ColorSequenceKeypoint.new(1, settings.Gradient_Color_2)
        })

        gradient.Rotation = settings.Gradient_Rotation or 0

        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0)
        })
    else
        fill.BackgroundColor3 = settings.Fill_Box_Color

        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        })

        gradient.Rotation = 0
    end
end

function ESP:UpdateCorners(object, bounds, color)
    local settings = self.Settings
    local corners = object.Corners

    if not settings.CornerBox then
        self:SetVisible(corners, false)
        return
    end

    local x1 = bounds.X
    local y1 = bounds.Y
    local x2 = bounds.X + bounds.Width
    local y2 = bounds.Y + bounds.Height

    local cornerLength = math.clamp(
        math.min(bounds.Width, bounds.Height) * 0.25,
        4,
        18
    )

    corners.TL1.From = Vector2.new(x1, y1)
    corners.TL1.To = Vector2.new(x1 + cornerLength, y1)

    corners.TL2.From = Vector2.new(x1, y1)
    corners.TL2.To = Vector2.new(x1, y1 + cornerLength)

    corners.TR1.From = Vector2.new(x2, y1)
    corners.TR1.To = Vector2.new(x2 - cornerLength, y1)

    corners.TR2.From = Vector2.new(x2, y1)
    corners.TR2.To = Vector2.new(x2, y1 + cornerLength)

    corners.BL1.From = Vector2.new(x1, y2)
    corners.BL1.To = Vector2.new(x1 + cornerLength, y2)

    corners.BL2.From = Vector2.new(x1, y2)
    corners.BL2.To = Vector2.new(x1, y2 - cornerLength)

    corners.BR1.From = Vector2.new(x2, y2)
    corners.BR1.To = Vector2.new(x2 - cornerLength, y2)

    corners.BR2.From = Vector2.new(x2, y2)
    corners.BR2.To = Vector2.new(x2, y2 - cornerLength)

    self:SetColor(corners, color)
    self:SetVisible(corners, true)
end

function ESP:UpdateNormalBox(object, bounds, color)
    local settings = self.Settings

    if not settings.NormalBox then
        object.NormalBox.Visible = false
        return
    end

    object.NormalBox.Position = Vector2.new(
        math.floor(bounds.X),
        math.floor(bounds.Y)
    )

    object.NormalBox.Size = Vector2.new(
        math.ceil(bounds.Width),
        math.ceil(bounds.Height)
    )

    object.NormalBox.Color = color
    object.NormalBox.Thickness = settings.Box_Thickness
    object.NormalBox.Visible = true
end

function ESP:UpdateText(object, bounds, character, color)
    local settings = self.Settings

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    local textColor = color

    if settings.CustomTextColor then
        textColor = settings.Name_Color
    end

    if settings.ShowName then
        object.Name.Text = object.Player.DisplayName ~= object.Player.Name
            and object.Player.DisplayName .. " [" .. object.Player.Name .. "]"
            or object.Player.Name

        object.Name.Size = settings.Name_Scale
        object.Name.Font = self.Fonts[settings.Font] or 0
        object.Name.Color = textColor
        object.Name.Outline = true
        object.Name.OutlineColor = color
        object.Name.Position = Vector2.new(
            bounds.X + bounds.Width * 0.5,
            bounds.Y - settings.Name_Scale - 2
        )
        object.Name.Visible = true
    else
        object.Name.Visible = false
    end

    if settings.ShowTeam then
        local teamColor = color

        if settings.CustomTextColor then
            teamColor = settings.Team_Text_Color
        end

        local teamName = object.Player.Team and object.Player.Team.Name or "Neutral"

        object.Team.Text = teamName
        object.Team.Size = math.max(settings.Name_Scale - 2, 10)
        object.Team.Font = self.Fonts[settings.Font] or 0
        object.Team.Color = teamColor
        object.Team.Outline = true
        object.Team.OutlineColor = color
        object.Team.Position = Vector2.new(
            bounds.X + bounds.Width * 0.5,
            bounds.Y + settings.Name_Scale
        )
        object.Team.Visible = true
    else
        object.Team.Visible = false
    end
end

function ESP:UpdateHealth(object, bounds, humanoid, color)
    local settings = self.Settings

    if not settings.ShowHealth then
        object.HealthBorder.Visible = false
        object.HealthFill.Visible = false
        return
    end

    local health = math.clamp(
        humanoid.Health / math.max(humanoid.MaxHealth, 1),
        0,
        1
    )

    local barWidth = 4
    local gap = 3

    local x = bounds.X + bounds.Width + gap
    local y = bounds.Y
    local height = bounds.Height

    object.HealthBorder.Position = Vector2.new(
        math.floor(x),
        math.floor(y)
    )

    object.HealthBorder.Size = Vector2.new(
        barWidth,
        math.ceil(height)
    )

    object.HealthBorder.Filled = true
    object.HealthBorder.Color = settings.HealthBorder_Color
    object.HealthBorder.Thickness = 1
    object.HealthBorder.Visible = true

    local padding = 1

    local fillHeight = math.max(
        0,
        (height - padding * 2) * health
    )

    object.HealthFill.Position = Vector2.new(
        math.floor(x + padding),
        math.floor(y + height - padding - fillHeight)
    )

    object.HealthFill.Size = Vector2.new(
        math.max(1, barWidth - padding * 2),
        math.ceil(fillHeight)
    )

    object.HealthFill.Filled = true
    object.HealthFill.Color = settings.HealthFill_Color
    object.HealthFill.Thickness = 1
    object.HealthFill.Visible = health > 0
end

function ESP:UpdatePlayer(object)
    local settings = self.Settings

    if not settings.Enabled then
        self:SetVisible(object.Corners, false)
        object.NormalBox.Visible = false
        object.Name.Visible = false
        object.Team.Visible = false
        object.HealthBorder.Visible = false
        object.HealthFill.Visible = false
        object.Fill.Visible = false
        return
    end

    local player = object.Player
    local character = player.Character

    if not character then
        self:SetVisible(object.Corners, false)
        object.NormalBox.Visible = false
        object.Name.Visible = false
        object.Team.Visible = false
        object.HealthBorder.Visible = false
        object.HealthFill.Visible = false
        object.Fill.Visible = false
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        self:SetVisible(object.Corners, false)
        object.NormalBox.Visible = false
        object.Name.Visible = false
        object.Team.Visible = false
        object.HealthBorder.Visible = false
        object.HealthFill.Visible = false
        object.Fill.Visible = false
        return
    end

    local bounds = self:GetCharacterBounds(character)

    if not bounds then
        self:SetVisible(object.Corners, false)
        object.NormalBox.Visible = false
        object.Name.Visible = false
        object.Team.Visible = false
        object.HealthBorder.Visible = false
        object.HealthFill.Visible = false
        object.Fill.Visible = false
        return
    end

    local color = self:GetColor(player)

    self:UpdateFill(object, bounds, color)
    self:UpdateCorners(object, bounds, color)
    self:UpdateNormalBox(object, bounds, color)
    self:UpdateText(object, bounds, character, color)
    self:UpdateHealth(object, bounds, humanoid, color)

    if settings.Autothickness then
        local thickness = math.clamp(
            100 / math.max(bounds.Distance, 1),
            1,
            4
        )

        self:SetThickness(object.Corners, thickness)
        object.NormalBox.Thickness = thickness
    else
        self:SetThickness(object.Corners, settings.Box_Thickness)
        object.NormalBox.Thickness = settings.Box_Thickness
    end
end

function ESP:Update()
    self.Camera = self.Workspace.CurrentCamera

    for _, object in pairs(self.Objects) do
        self:UpdatePlayer(object)
    end
end

function ESP:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    if self.PlayerAddedConnection then
        self.PlayerAddedConnection:Disconnect()
        self.PlayerAddedConnection = nil
    end

    if self.PlayerRemovingConnection then
        self.PlayerRemovingConnection:Disconnect()
        self.PlayerRemovingConnection = nil
    end

    for player in pairs(self.Objects) do
        self:RemovePlayer(player)
    end

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end

    self.Objects = {}
end

return ESP