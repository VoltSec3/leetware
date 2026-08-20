local doors = {}
local rainbowcon

MainGroupBox:AddToggle('PlaceholderToggle', {
    Text = 'No Doors',
    Default = false,
    Callback = function(Value)
        if Value then
            doors = {}

            for _, Model in ipairs(Workspace.Doors:GetChildren()) do
                if Model:IsA('Model') then
                    for _, Part in ipairs(Model:GetDescendants()) do
                        if Part:IsA('BasePart') then
                            doors[Part] = {
                                Color = Part.Color,
                                Transparency = Part.Transparency,
                                CanCollide = Part.CanCollide
                            }

                            Part.CanCollide = false
                            Part.Transparency = 0.5
                        end
                    end
                end
            end

            if rainbowcon then
                rainbowcon:Disconnect()
            end

            rainbowcon = RunService.RenderStepped:Connect(function()
                local color = (tick() % 5) / 5

                for Part in pairs(doors) do
                    if Part and Part.Parent then
                        Part.Color = Color3.fromHSV(color, 1, 1)
                    end
                end
            end)
        else
            if rainbowcon then
                rainbowcon:Disconnect()
                rainbowcon = nil
            end

            for Part, Original in pairs(doors) do
                if Part and Part.Parent then
                    Part.Color = Original.Color
                    Part.Transparency = Original.Transparency
                    Part.CanCollide = Original.CanCollide
                end
            end

            doors = {}
        end
    end
})