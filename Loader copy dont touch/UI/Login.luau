local Players = game:GetService("Players")

local UI = {}

function UI.create(onSubmit)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("auth")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "auth"
    screenGui.ResetOnSpawn = true
    screenGui.IgnoreGuiInset = false
    screenGui.DisplayOrder = 0
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.ZIndex = -1
    frame.Position = UDim2.new(0.432031631, 0, 0.412836075, 0)
    frame.Size = UDim2.new(0, 274, 0, 201)
    frame.BackgroundColor3 = Color3.fromRGB(44, 13, 52)
    frame.BackgroundTransparency = 0
    frame.Visible = true
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.ClipsDescendants = false
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local main = Instance.new("Frame")
    main.Name = "main"
    main.ZIndex = 1
    main.Position = UDim2.new(0.0189391635, 0, 0.0250049792, 0)
    main.Size = UDim2.new(0, 262, 0, 189)
    main.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
    main.BackgroundTransparency = 0
    main.Visible = true
    main.AnchorPoint = Vector2.new(0, 0)
    main.ClipsDescendants = false
    main.BorderSizePixel = 0
    main.Parent = frame

    local input = Instance.new("TextBox")
    input.Name = "TextBox"
    input.ZIndex = 1
    input.Position = UDim2.new(0, 0, 0.370370358, 0)
    input.Size = UDim2.new(0, 262, 0, 50)
    input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.TextScaled = true
    input.TextSize = 14
    input.Font = Enum.Font.SourceSans
    input.TextColor3 = Color3.fromRGB(0, 0, 0)
    input.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    input.TextStrokeTransparency = 1
    input.TextWrapped = true
    input.TextXAlignment = Enum.TextXAlignment.Center
    input.TextYAlignment = Enum.TextYAlignment.Center
    input.TextTransparency = 0
    input.ClearTextOnFocus = true
    input.MultiLine = false
    input.Visible = true
    input.AnchorPoint = Vector2.new(0, 0)
    input.ClipsDescendants = false
    input.Parent = main

    local button = Instance.new("TextButton")
    button.Name = "TextButton"
    button.ZIndex = 1
    button.Position = UDim2.new(0, 0, 0.661375642, 0)
    button.Size = UDim2.new(0, 262, 0, 64)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundTransparency = 1
    button.Text = "click me to auth!!!1!1!!"
    button.TextScaled = true
    button.TextSize = 14
    button.Font = Enum.Font.SourceSans
    button.TextColor3 = Color3.fromRGB(104, 104, 104)
    button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    button.TextStrokeTransparency = 1
    button.TextWrapped = true
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.TextYAlignment = Enum.TextYAlignment.Center
    button.TextTransparency = 0
    button.Visible = true
    button.AnchorPoint = Vector2.new(0, 0)
    button.ClipsDescendants = false
    button.AutoButtonColor = true
    button.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "TextLabel"
    status.ZIndex = 1
    status.Position = UDim2.new(0, 0, 0, 0)
    status.Size = UDim2.new(0, 262, 0, 71)
    status.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    status.BackgroundTransparency = 1
    status.Text = "shitty temp auth ui"
    status.TextScaled = true
    status.TextSize = 14
    status.Font = Enum.Font.SourceSans
    status.TextColor3 = Color3.fromRGB(132, 132, 132)
    status.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    status.TextStrokeTransparency = 1
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.TextTransparency = 0
    status.Visible = true
    status.AnchorPoint = Vector2.new(0, 0)
    status.ClipsDescendants = false
    status.Parent = main

    local function setStatus(text, color)
        status.Text = text
        status.TextColor3 = color or Color3.fromRGB(132, 132, 132)
    end

    local function setLoading(loading)
        button.AutoButtonColor = not loading
        button.Text = loading and "authenticating..." or "click me to auth!!!1!1!!"
        input.TextEditable = not loading
    end

    button.MouseButton1Click:Connect(function()
        local license = string.gsub(input.Text, "%s+", "")
        if license == "" then
            setStatus("License is required.", Color3.fromRGB(255, 120, 120))
            return
        end

        setLoading(true)
        setStatus("Contacting license server...", Color3.fromRGB(180, 180, 190))

        task.spawn(function()
            local ok, err = onSubmit(license, function(message)
                setStatus(message)
            end, function()
                screenGui:Destroy()
            end)

            if not ok then
                setLoading(false)
                setStatus(
                    tostring(err or "Authentication failed"),
                    Color3.fromRGB(255, 120, 120)
                )
            end
        end)
    end)

    return screenGui
end

return UI
