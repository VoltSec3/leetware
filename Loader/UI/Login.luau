local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = {}

function UI.create(onSubmit)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("LeetwareLoader")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeetwareLoader"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(360, 220)
	frame.Position = UDim2.new(0.5, -180, 0.5, -110)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 45, 120)
	stroke.Thickness = 1
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 0, 40)
	title.Position = UDim2.fromOffset(12, 12)
	title.Font = Enum.Font.GothamBold
	title.Text = "leetware"
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.new(1, -24, 0, 20)
	subtitle.Position = UDim2.fromOffset(12, 44)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Enter your license to continue"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
	subtitle.TextSize = 14
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = frame

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -24, 0, 42)
	input.Position = UDim2.fromOffset(12, 84)
	input.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	input.TextColor3 = Color3.fromRGB(240, 240, 245)
	input.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
	input.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
	input.Font = Enum.Font.Code
	input.TextSize = 16
	input.ClearTextOnFocus = false
	input.Text = ""
	input.Parent = frame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = input

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, -24, 0, 18)
	status.Position = UDim2.fromOffset(12, 134)
	status.Font = Enum.Font.Gotham
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(180, 180, 190)
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -24, 0, 42)
	button.Position = UDim2.fromOffset(12, 158)
	button.BackgroundColor3 = Color3.fromRGB(109, 74, 201)
	button.Text = "Authenticate"
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function setStatus(text, color)
		status.Text = text
		status.TextColor3 = color or Color3.fromRGB(180, 180, 190)
	end

	local function setLoading(loading)
		button.AutoButtonColor = not loading
		button.Text = loading and "Authenticating..." or "Authenticate"
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
				local tween = TweenService:Create(
					frame,
					TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 1 }
				)
				tween:Play()
				tween.Completed:Wait()
				screenGui:Destroy()
			end)

			if not ok then
				setLoading(false)
				setStatus(tostring(err or "Authentication failed"), Color3.fromRGB(255, 120, 120))
			end
		end)
	end)

	return screenGui
end

return UI
