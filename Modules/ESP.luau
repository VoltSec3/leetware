local ESP = {}
ESP.__index = ESP

local Drawing = Drawing
local Vector2 = Vector2
local Vector3 = Vector3
local Color3 = Color3
local CFrame = CFrame
local math = math

local GRADIENT_STRIPS = 48
local GRADIENT_OVERLAP = 2

local FONT_MAP = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3
}

local function newLine()
    local object = Drawing.new("Line")
    object.Visible = false
    object.Transparency = 1
    object.Thickness = 2
    return object
end

local function newSquare()
    local object = Drawing.new("Square")
    object.Visible = false
    object.Filled = true
    object.Transparency = 1
    object.Thickness = 0
    return object
end

local function newText()
    local object = Drawing.new("Text")
    object.Visible = false
    object.Center = true
    object.Outline = true
    object.OutlineColor = Color3.fromRGB(0, 0, 0)
    object.Transparency = 1
    object.Font = 0
    object.Size = 14
    return object
end

local function hide(object)
    if object then
        object.Visible = false
    end
end

local function hideList(list)
    for _, object in pairs(list) do
        object.Visible = false
    end
end

local function destroyList(list)
    for _, object in pairs(list) do
        if object then
            pcall(function()
                object:Remove()
            end)
        end
    end
end

local function lerpColor(a, b, alpha)
    return a:Lerp(b, math.clamp(alpha, 0, 1))
end

local function getGradientColor(settings, alpha)
    local color1 = settings.Gradient_Color_1 or Color3.fromRGB(255, 0, 0)
    local color2 = settings.Gradient_Color_2 or Color3.fromRGB(0, 0, 255)

    return lerpColor(color1, color2, alpha)
end

local function getBoxColor(settings, player, localPlayer)
    if settings.Rainbow then
        local hue = (os.clock() % 5) / 5
        return Color3.fromHSV(hue, 0.6, 1)
    end

    if settings.Team_Color and player.TeamColor then
        return player.TeamColor.Color
    end

    if settings.Team_Check then
        if player.TeamColor == localPlayer.TeamColor then
            return Color3.fromRGB(0, 255, 0)
        end

        return Color3.fromRGB(255, 0, 0)
    end

    return settings.Box_Color or Color3.fromRGB(255, 0, 0)
end

local function getCharacterBounds(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not head or not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local rootPosition = root.Position
    local rootSize = root.Size

    local height = math.max(rootSize.Y * 1.5, 4)
    local width = math.max(rootSize.X * 2.25, 2)

    local top = rootPosition + Vector3.new(0, height * 0.5, 0)
    local bottom = rootPosition - Vector3.new(0, height * 0.5, 0)

    return {
        Root = root,
        Head = head,
        Humanoid = humanoid,
        Position = rootPosition,
        Width = width,
        Height = height,
        Top = top,
        Bottom = bottom
    }
end

function ESP.new(options)
    local self = setmetatable({}, ESP)

    self.Players = options.Players
    self.RunService = options.RunService
    self.Workspace = options.Workspace
    self.Player = options.Player
    self.Settings = options.Settings

    self.Camera = self.Workspace.CurrentCamera
    self.Objects = {}
    self.Destroyed = false

    self:_createPlayers()

    self.PlayerAddedConnection = self.Players.PlayerAdded:Connect(function(player)
        self:_createPlayer(player)
    end)

    self.PlayerRemovingConnection = self.Players.PlayerRemoving:Connect(function(player)
        self:_removePlayer(player)
    end)

    self.RenderConnection = self.RunService.RenderStepped:Connect(function()
        if self.Destroyed then
            return
        end

        self.Camera = self.Workspace.CurrentCamera

        if not self.Camera then
            return
        end

        for player, data in pairs(self.Objects) do
            self:_updatePlayer(player, data)
        end
    end)

    return self
end

function ESP:_createPlayers()
    for _, player in ipairs(self.Players:GetPlayers()) do
        self:_createPlayer(player)
    end
end

function ESP:_createPlayer(player)
    if player == self.Player then
        return
    end

    if self.Objects[player] then
        return
    end

    local data = {
        Lines = {},
        Gradient = {},
        Name = newText(),
        Team = newText(),
        HealthBorder = newSquare(),
        HealthFill = newSquare(),
        Origin = Instance.new("Part")
    }

    data.Lines.TL1 = newLine()
    data.Lines.TL2 = newLine()
    data.Lines.TR1 = newLine()
    data.Lines.TR2 = newLine()
    data.Lines.BL1 = newLine()
    data.Lines.BL2 = newLine()
    data.Lines.BR1 = newLine()
    data.Lines.BR2 = newLine()

    data.NormalBox = newSquare()

    for i = 1, GRADIENT_STRIPS do
        data.Gradient[i] = newSquare()
    end

    data.Origin.Name = "leetware_ESP"
    data.Origin.Parent = self.Workspace
    data.Origin.Anchored = true
    data.Origin.CanCollide = false
    data.Origin.CanTouch = false
    data.Origin.CanQuery = false
    data.Origin.Transparency = 1
    data.Origin.Size = Vector3.new(1, 1, 1)

    self.Objects[player] = data
end

function ESP:_hide(data)
    hideList(data.Lines)
    hide(data.NormalBox)

    for _, square in ipairs(data.Gradient) do
        hide(square)
    end

    hide(data.Name)
    hide(data.Team)
    hide(data.HealthBorder)
    hide(data.HealthFill)
end

function ESP:_removePlayer(player)
    local data = self.Objects[player]

    if not data then
        return
    end

    self:_hide(data)

    destroyList(data.Lines)
    destroyList(data.Gradient)

    if data.NormalBox then
        pcall(function()
            data.NormalBox:Remove()
        end)
    end

    if data.Name then
        pcall(function()
            data.Name:Remove()
        end)
    end

    if data.Team then
        pcall(function()
            data.Team:Remove()
        end)
    end

    if data.HealthBorder then
        pcall(function()
            data.HealthBorder:Remove()
        end)
    end

    if data.HealthFill then
        pcall(function()
            data.HealthFill:Remove()
        end)
    end

    if data.Origin then
        data.Origin:Destroy()
    end

    self.Objects[player] = nil
end

function ESP:_updateBoxLines(data, left, top, right, bottom, color, thickness)
    local width = right - left
    local height = bottom - top

    local cornerSize = math.clamp(math.min(width, height) * 0.25, 4, 20)

    data.Lines.TL1.From = Vector2.new(left, top)
    data.Lines.TL1.To = Vector2.new(left + cornerSize, top)

    data.Lines.TL2.From = Vector2.new(left, top)
    data.Lines.TL2.To = Vector2.new(left, top + cornerSize)

    data.Lines.TR1.From = Vector2.new(right, top)
    data.Lines.TR1.To = Vector2.new(right - cornerSize, top)

    data.Lines.TR2.From = Vector2.new(right, top)
    data.Lines.TR2.To = Vector2.new(right, top + cornerSize)

    data.Lines.BL1.From = Vector2.new(left, bottom)
    data.Lines.BL1.To = Vector2.new(left + cornerSize, bottom)

    data.Lines.BL2.From = Vector2.new(left, bottom)
    data.Lines.BL2.To = Vector2.new(left, bottom - cornerSize)

    data.Lines.BR1.From = Vector2.new(right, bottom)
    data.Lines.BR1.To = Vector2.new(right - cornerSize, bottom)

    data.Lines.BR2.From = Vector2.new(right, bottom)
    data.Lines.BR2.To = Vector2.new(right, bottom - cornerSize)

    for _, line in pairs(data.Lines) do
        line.Color = color
        line.Thickness = thickness
        line.Visible = true
    end
end

function ESP:_updateNormalBox(data, left, top, right, bottom, color, thickness)
    data.NormalBox.Position = Vector2.new(left, top)
    data.NormalBox.Size = Vector2.new(right - left, bottom - top)
    data.NormalBox.Color = color
    data.NormalBox.Thickness = thickness
    data.NormalBox.Filled = false
    data.NormalBox.Visible = true
end

function ESP:_updateGradient(data, left, top, right, bottom)
    local settings = self.Settings

    local width = right - left
    local height = bottom - top

    if width <= 1 or height <= 1 then
        for _, square in ipairs(data.Gradient) do
            square.Visible = false
        end

        return
    end

    local rotation = math.rad(settings.Gradient_Rotation or 0)
    local cosine = math.cos(rotation)
    local sine = math.sin(rotation)

    local centerX = 0.5
    local centerY = 0.5

    local corners = {
        { -0.5, -0.5 },
        { 0.5, -0.5 },
        { -0.5, 0.5 },
        { 0.5, 0.5 }
    }

    local minProjection = math.huge
    local maxProjection = -math.huge

    for _, corner in ipairs(corners) do
        local x = corner[1]
        local y = corner[2]

        local rotatedX = x * cosine - y * sine
        local rotatedY = x * sine + y * cosine

        local projection = rotatedX + rotatedY

        if projection < minProjection then
            minProjection = projection
        end

        if projection > maxProjection then
            maxProjection = projection
        end
    end

    local projectionRange = maxProjection - minProjection

    if projectionRange <= 0 then
        projectionRange = 1
    end

    local stripHeight = height / GRADIENT_STRIPS
    local overlap = math.min(GRADIENT_OVERLAP, stripHeight * 0.5)

    for i = 1, GRADIENT_STRIPS do
        local y0 = top + (i - 1) * stripHeight
        local y1 = top + i * stripHeight

        local stripTop = math.max(top, y0 - overlap)
        local stripBottom = math.min(bottom, y1 + overlap)

        local centerScreenY = (stripTop + stripBottom) * 0.5
        local normalizedY = ((centerScreenY - top) / height) - centerY

        local normalizedX = 0

        local rotatedX = normalizedX * cosine - normalizedY * sine
        local rotatedY = normalizedX * sine + normalizedY * cosine

        local projection = rotatedX + rotatedY
        local alpha = (projection - minProjection) / projectionRange

        alpha = math.clamp(alpha, 0, 1)

        local square = data.Gradient[i]

        square.Position = Vector2.new(left, stripTop)
        square.Size = Vector2.new(width, math.max(1, stripBottom - stripTop))
        square.Color = getGradientColor(settings, alpha)
        square.Transparency = settings.Fill_Opacity or 0.15
        square.Filled = true
        square.Visible = true
    end
end

function ESP:_updateSolidFill(data, left, top, right, bottom)
    local settings = self.Settings

    local width = right - left
    local height = bottom - top

    for _, square in ipairs(data.Gradient) do
        square.Visible = false
    end

    if width <= 1 or height <= 1 then
        data.NormalBox.Visible = false
        return
    end

    data.NormalBox.Position = Vector2.new(left, top)
    data.NormalBox.Size = Vector2.new(width, height)
    data.NormalBox.Color = settings.Fill_Box_Color or Color3.fromRGB(255, 0, 0)
    data.NormalBox.Transparency = settings.Fill_Opacity or 0.15
    data.NormalBox.Thickness = 0
    data.NormalBox.Filled = true
    data.NormalBox.Visible = true
end

function ESP:_updateText(data, bounds, left, top, right)
    local settings = self.Settings

    local textColor = settings.CustomTextColor
        and (settings.Name_Color or Color3.fromRGB(255, 255, 255))
        or getBoxColor(settings, bounds.Player, self.Player)

    local nameVisible = settings.ShowName == true
    local teamVisible = settings.ShowTeam == true

    if nameVisible then
        local nameSize = settings.Name_Scale or 14

        data.Name.Text = bounds.Player.DisplayName or bounds.Player.Name
        data.Name.Size = nameSize
        data.Name.Font = FONT_MAP[settings.Font] or 0
        data.Name.Color = textColor
        data.Name.Outline = true
        data.Name.OutlineColor = getBoxColor(settings, bounds.Player, self.Player)
        data.Name.Position = Vector2.new((left + right) * 0.5, top - nameSize - 2)
        data.Name.Visible = true
    else
        data.Name.Visible = false
    end

    if teamVisible then
        local teamName = "Neutral"

        if bounds.Player.Team then
            teamName = bounds.Player.Team.Name
        end

        local teamColor = settings.CustomTextColor
            and (settings.Team_Text_Color or Color3.fromRGB(255, 255, 255))
            or getBoxColor(settings, bounds.Player, self.Player)

        local teamOffset = nameVisible and ((settings.Name_Scale or 14) + 2) or 0

        data.Team.Text = teamName
        data.Team.Size = math.max(10, (settings.Name_Scale or 14) - 2)
        data.Team.Font = FONT_MAP[settings.Font] or 0
        data.Team.Color = teamColor
        data.Team.Outline = true
        data.Team.OutlineColor = getBoxColor(settings, bounds.Player, self.Player)
        data.Team.Position = Vector2.new((left + right) * 0.5, top - teamOffset - 2)
        data.Team.Visible = true
    else
        data.Team.Visible = false
    end
end

function ESP:_updateHealth(data, bounds, right, top, bottom)
    local settings = self.Settings

    if not settings.ShowHealth then
        data.HealthBorder.Visible = false
        data.HealthFill.Visible = false
        return
    end

    local health = math.clamp(bounds.Humanoid.Health / math.max(bounds.Humanoid.MaxHealth, 1), 0, 1)

    local barWidth = 4
    local gap = 3
    local borderThickness = 1

    local borderX = right + gap
    local borderY = top
    local borderHeight = bottom - top

    data.HealthBorder.Position = Vector2.new(
        borderX,
        borderY
    )

    data.HealthBorder.Size = Vector2.new(
        barWidth + borderThickness * 2,
        borderHeight
    )

    data.HealthBorder.Color = settings.HealthBorder_Color or Color3.fromRGB(0, 0, 0)
    data.HealthBorder.Transparency = 0
    data.HealthBorder.Filled = true
    data.HealthBorder.Visible = true

    local fillHeight = math.max(0, borderHeight * health)

    data.HealthFill.Position = Vector2.new(
        borderX + borderThickness,
        borderY + borderHeight - fillHeight
    )

    data.HealthFill.Size = Vector2.new(
        barWidth,
        fillHeight
    )

    data.HealthFill.Color = settings.HealthFill_Color or Color3.fromRGB(255, 255, 255)
    data.HealthFill.Transparency = 0
    data.HealthFill.Filled = true
    data.HealthFill.Visible = fillHeight > 0
end

function ESP:_updatePlayer(player, data)
    local settings = self.Settings

    if not settings.Enabled then
        self:_hide(data)
        return
    end

    if player == self.Player then
        self:_hide(data)
        return
    end

    local character = player.Character

    if not character then
        self:_hide(data)
        return
    end

    local characterBounds = getCharacterBounds(character)

    if not characterBounds then
        self:_hide(data)
        return
    end

    characterBounds.Player = player

    local camera = self.Camera

    if not camera then
        self:_hide(data)
        return
    end

    local rootPosition = characterBounds.Position

    local rootScreen, rootVisible = camera:WorldToViewportPoint(rootPosition)

    if not rootVisible or rootScreen.Z <= 0 then
        self:_hide(data)
        return
    end

    local topWorld = characterBounds.Top
    local bottomWorld = characterBounds.Bottom

    local topScreen, topVisible = camera:WorldToViewportPoint(topWorld)
    local bottomScreen, bottomVisible = camera:WorldToViewportPoint(bottomWorld)

    if not topVisible or not bottomVisible then
        self:_hide(data)
        return
    end

    local centerX = rootScreen.X

    local screenHeight = math.abs(bottomScreen.Y - topScreen.Y)

    if screenHeight <= 1 then
        self:_hide(data)
        return
    end

    local screenWidth = screenHeight * (characterBounds.Width / characterBounds.Height)

    local left = centerX - screenWidth * 0.5
    local right = centerX + screenWidth * 0.5
    local top = math.min(topScreen.Y, bottomScreen.Y)
    local bottom = math.max(topScreen.Y, bottomScreen.Y)

    local viewport = camera.ViewportSize

    if right < 0 or left > viewport.X or bottom < 0 or top > viewport.Y then
        self:_hide(data)
        return
    end

    local distance = (camera.CFrame.Position - rootPosition).Magnitude

    local thickness

    if settings.Autothickness then
        thickness = math.clamp(100 / math.max(distance, 1), 1, 4)
    else
        thickness = settings.Box_Thickness or 2
    end

    local boxColor = getBoxColor(settings, player, self.Player)

    data.Origin.Position = rootPosition

    local normalBoxEnabled = settings.NormalBox == true
    local cornerBoxEnabled = settings.CornerBox == true

    if normalBoxEnabled then
        for _, line in pairs(data.Lines) do
            line.Visible = false
        end

        self:_updateNormalBox(
            data,
            left,
            top,
            right,
            bottom,
            boxColor,
            thickness
        )
    elseif cornerBoxEnabled then
        data.NormalBox.Visible = false

        self:_updateBoxLines(
            data,
            left,
            top,
            right,
            bottom,
            boxColor,
            thickness
        )
    else
        data.NormalBox.Visible = false

        for _, line in pairs(data.Lines) do
            line.Visible = false
        end
    end

    if settings.FillBoxGradient then
        data.NormalBox.Visible = false

        self:_updateGradient(
            data,
            left,
            top,
            right,
            bottom
        )
    elseif settings.FillBox then
        self:_updateSolidFill(
            data,
            left,
            top,
            right,
            bottom
        )
    else
        data.NormalBox.Visible = normalBoxEnabled

        for _, square in ipairs(data.Gradient) do
            square.Visible = false
        end
    end

    self:_updateText(
        data,
        characterBounds,
        left,
        top,
        right
    )

    self:_updateHealth(
        data,
        characterBounds,
        right,
        top,
        bottom
    )
end

function ESP:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    if self.PlayerAddedConnection then
        self.PlayerAddedConnection:Disconnect()
        self.PlayerAddedConnection = nil
    end

    if self.PlayerRemovingConnection then
        self.PlayerRemovingConnection:Disconnect()
        self.PlayerRemovingConnection = nil
    end

    if self.RenderConnection then
        self.RenderConnection:Disconnect()
        self.RenderConnection = nil
    end

    for player in pairs(self.Objects) do
        self:_removePlayer(player)
    end

    self.Objects = {}
end

return ESP