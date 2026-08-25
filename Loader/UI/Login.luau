local Players = game:GetService("Players")

local UI = {}

function UI.create(onSubmit)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("auth")
	if existing then
		existing:Destroy()
	end

	-- Instances
	local Loader = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local Frame_2 = Instance.new("Frame")
	local logo = Instance.new("TextLabel")
	local loaderorerror = Instance.new("TextLabel")
	local license = Instance.new("TextBox")
	local submit = Instance.new("TextButton")

	-- Properties
	Loader.Name = "auth"
	Loader.ResetOnSpawn = true
	Loader.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Loader.Parent = playerGui

	Frame.Parent = Loader
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = Color3.fromRGB(86, 86, 86)
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	Frame.Size = UDim2.new(0, 410, 0, 210)
	Frame.ZIndex = -20

	Frame_2.Parent = Frame
	Frame_2.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame_2.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	Frame_2.Size = UDim2.new(0, 400, 0, 200)

	logo.Name = "logo"
	logo.Parent = Frame_2
	logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	logo.BackgroundTransparency = 1.000
	logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	logo.BorderSizePixel = 0
	logo.Position = UDim2.new(0.412499994, 0, 0.0350000001, 0)
	logo.Size = UDim2.new(0, 70, 0, 50)
	logo.Font = Enum.Font.Unknown
	logo.Text = "<l>"
	logo.TextColor3 = Color3.fromRGB(0, 0, 0)
	logo.TextScaled = true
	logo.TextSize = 14.000
	logo.TextWrapped = true

	loaderorerror.Name = "loaderorerror"
	loaderorerror.Parent = Frame_2
	loaderorerror.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	loaderorerror.BackgroundTransparency = 1.000
	loaderorerror.BorderColor3 = Color3.fromRGB(0, 0, 0)
	loaderorerror.BorderSizePixel = 0
	loaderorerror.Position = UDim2.new(0.237499997, 0, 0.216071784, 0)
	loaderorerror.Size = UDim2.new(0, 209, 0, 38)
	loaderorerror.Font = Enum.Font.Unknown
	loaderorerror.Text = "leetware loader"
	loaderorerror.TextColor3 = Color3.fromRGB(0, 0, 0)
	loaderorerror.TextScaled = true
	loaderorerror.TextSize = 14.000
	loaderorerror.TextWrapped = true

	license.Name = "license"
	license.Parent = Frame_2
	license.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	license.BackgroundTransparency = 1.000
	license.BorderColor3 = Color3.fromRGB(0, 0, 0)
	license.BorderSizePixel = 0
	license.Position = UDim2.new(0, 0, 0.436071783, 0)
	license.Size = UDim2.new(0, 400, 0, 43)
	license.Font = Enum.Font.SourceSans
	license.PlaceholderColor3 = Color3.fromRGB(62, 62, 62)
	license.PlaceholderText = "license field"
	license.Text = ""
	license.TextColor3 = Color3.fromRGB(0, 0, 0)
	license.TextScaled = true
	license.TextSize = 14.000
	license.TextWrapped = true
	license.ClearTextOnFocus = true
	license.TextEditable = true

	submit.Name = "submit"
	submit.Parent = Frame_2
	submit.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	submit.BackgroundTransparency = 1.000
	submit.BorderColor3 = Color3.fromRGB(255, 255, 255)
	submit.BorderSizePixel = 0
	submit.Position = UDim2.new(0, 0, 0.685000002, 0)
	submit.Size = UDim2.new(0, 400, 0, 49)
	submit.Font = Enum.Font.SourceSans
	submit.Text = "submit"
	submit.TextColor3 = Color3.fromRGB(0, 0, 0)
	submit.TextScaled = true
	submit.TextSize = 14.000
	submit.TextWrapped = true
	submit.AutoButtonColor = true

	local function setStatus(text, color)
		loaderorerror.Text = text
		loaderorerror.TextColor3 = color or Color3.fromRGB(0, 0, 0)
	end

	local function setLoading(loading)
		submit.AutoButtonColor = not loading
		submit.Text = loading and "authenticating..." or "submit"
		license.TextEditable = not loading
	end

	local function attempt()
		local value = string.gsub(license.Text, "%s+", "")

		if value == "" then
			setStatus("License is required.", Color3.fromRGB(255, 120, 120))
			return
		end

		setLoading(true)
		setStatus("Contacting license server...", Color3.fromRGB(180, 180, 190))

		task.spawn(function()
			local ok, err = onSubmit(
				value,
				function(message, color)
					setStatus(message, color)
				end,
				function()
					Loader:Destroy()
				end
			)

			if not ok then
				setLoading(false)
				setStatus(
					tostring(err or "Authentication failed"),
					Color3.fromRGB(255, 120, 120)
				)
			end
		end)
	end

	submit.MouseButton1Click:Connect(attempt)

	license.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			attempt()
		end
	end)

	return Loader
end

return UI
