local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local espRepo = 'Modules/ESP.lua'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESPSettings = {
    Enabled = true,
    Box_Color = Color3.fromRGB(255, 0, 0),
    Box_Thickness = 2,
    Team_Check = false,
    Team_Color = false,
    Autothickness = false,
    Rainbow = false,
    CornerBox = true,
    NormalBox = false,
    FillBox = false,
    FillBoxGradient = false,
    Fill_Box_Color = Color3.fromRGB(255, 0, 0),
    Gradient_Color_1 = Color3.fromRGB(255, 0, 0),
    Gradient_Color_2 = Color3.fromRGB(0, 0, 255),
    ShowName = false,
    ShowHealth = false,
    ShowTeam = false
}

local ESPModule = loadstring(game:HttpGet(espRepo))()

local ESPController = ESPModule.new({
    Players = Players,
    RunService = RunService,
    Workspace = Workspace,
    Player = Player,
    Settings = ESPSettings
})

local Window = Library:CreateWindow({
    Title = 'Leetware',
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

local MainGroupBox = Tabs.Main:AddLeftGroupbox('Main')

MainGroupBox:AddLabel('Leetware')

MainGroupBox:AddButton('Placeholder Button', function()
end)

MainGroupBox:AddButton({
    Text = 'Another Button',
    Func = function()
    end,
    DoubleClick = false,
    Tooltip = 'Placeholder button'
})

MainGroupBox:AddToggle('PlaceholderToggle', {
    Text = 'Placeholder Toggle',
    Default = false
})

MainGroupBox:AddToggle('AnotherPlaceholderToggle', {
    Text = 'Another Toggle',
    Default = true
})

MainGroupBox:AddSlider('PlaceholderSlider', {
    Text = 'Placeholder Slider',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

MainGroupBox:AddSlider('AnotherPlaceholderSlider', {
    Text = 'Another Slider',
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false
})

MainGroupBox:AddDropdown('PlaceholderDropdown', {
    Values = {
        'Option 1',
        'Option 2',
        'Option 3'
    },
    Default = 1,
    Multi = false,
    Text = 'Placeholder Dropdown'
})

MainGroupBox:AddDropdown('PlaceholderMultiDropdown', {
    Values = {
        'Option A',
        'Option B',
        'Option C',
        'Option D'
    },
    Default = {
        OptionA = false,
        OptionB = false,
        OptionC = false,
        OptionD = false
    },
    Multi = true,
    Text = 'Placeholder Multi Dropdown'
})

MainGroupBox:AddLabel('Placeholder Color'):AddColorPicker('PlaceholderColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Placeholder Color'
})

MainGroupBox:AddLabel('Another Color'):AddColorPicker('AnotherPlaceholderColor', {
    Default = Color3.fromRGB(255, 0, 255),
    Title = 'Another Placeholder Color'
})

MainGroupBox:AddLabel('Placeholder Keybind'):AddKeyPicker('PlaceholderKeybind', {
    Default = 'None',
    NoUI = false,
    Text = 'Placeholder Keybind',
    Mode = 'Toggle'
})

local RightMainGroupBox = Tabs.Main:AddRightGroupbox('Settings')

RightMainGroupBox:AddButton('Test Button', function()
end)

RightMainGroupBox:AddToggle('TestToggle', {
    Text = 'Test Toggle',
    Default = false
})

RightMainGroupBox:AddSlider('TestSlider', {
    Text = 'Test Slider',
    Default = 25,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

RightMainGroupBox:AddDropdown('TestDropdown', {
    Values = {
        'First',
        'Second',
        'Third'
    },
    Default = 1,
    Multi = false,
    Text = 'Test Dropdown'
})

RightMainGroupBox:AddLabel('Test Color'):AddColorPicker('TestColor', {
    Default = Color3.fromRGB(0, 170, 255),
    Title = 'Test Color'
})

RightMainGroupBox:AddLabel('Test Keybind'):AddKeyPicker('TestKeybind', {
    Default = 'None',
    NoUI = false,
    Text = 'Test Keybind',
    Mode = 'Toggle'
})

local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPGroupBox:AddToggle('ESPEnabled', {
    Text = 'Enabled',
    Default = ESPSettings.Enabled
})

Toggles.ESPEnabled:OnChanged(function()
    ESPSettings.Enabled = Toggles.ESPEnabled.Value
end)

ESPGroupBox:AddToggle('ESPCornerBox', {
    Text = 'Corner Box',
    Default = ESPSettings.CornerBox
})

Toggles.ESPCornerBox:OnChanged(function()
    ESPSettings.CornerBox = Toggles.ESPCornerBox.Value
end)

ESPGroupBox:AddToggle('ESPNormalBox', {
    Text = 'Normal Box',
    Default = ESPSettings.NormalBox
})

Toggles.ESPNormalBox:OnChanged(function()
    ESPSettings.NormalBox = Toggles.ESPNormalBox.Value
end)

ESPGroupBox:AddToggle('ESPFillBox', {
    Text = 'Fill Box',
    Default = ESPSettings.FillBox
})

Toggles.ESPFillBox:OnChanged(function()
    ESPSettings.FillBox = Toggles.ESPFillBox.Value
end)

ESPGroupBox:AddLabel('Fill Color'):AddColorPicker('ESPFillBoxColor', {
    Default = ESPSettings.Fill_Box_Color,
    Title = 'Fill Box Color'
})

Options.ESPFillBoxColor:OnChanged(function()
    ESPSettings.Fill_Box_Color = Options.ESPFillBoxColor.Value
end)

ESPGroupBox:AddToggle('ESPFillBoxGradient', {
    Text = 'Fill Box Gradient',
    Default = ESPSettings.FillBoxGradient
})

Toggles.ESPFillBoxGradient:OnChanged(function()
    ESPSettings.FillBoxGradient = Toggles.ESPFillBoxGradient.Value
end)

ESPGroupBox:AddLabel('Gradient Color 1'):AddColorPicker('ESPGradientColor1', {
    Default = ESPSettings.Gradient_Color_1,
    Title = 'Gradient Color 1'
})

Options.ESPGradientColor1:OnChanged(function()
    ESPSettings.Gradient_Color_1 = Options.ESPGradientColor1.Value
end)

ESPGroupBox:AddLabel('Gradient Color 2'):AddColorPicker('ESPGradientColor2', {
    Default = ESPSettings.Gradient_Color_2,
    Title = 'Gradient Color 2'
})

Options.ESPGradientColor2:OnChanged(function()
    ESPSettings.Gradient_Color_2 = Options.ESPGradientColor2.Value
end)

ESPGroupBox:AddToggle('ESPShowName', {
    Text = 'Show Name',
    Default = ESPSettings.ShowName
})

Toggles.ESPShowName:OnChanged(function()
    ESPSettings.ShowName = Toggles.ESPShowName.Value
end)

ESPGroupBox:AddToggle('ESPShowHealth', {
    Text = 'Show Health',
    Default = ESPSettings.ShowHealth
})

Toggles.ESPShowHealth:OnChanged(function()
    ESPSettings.ShowHealth = Toggles.ESPShowHealth.Value
end)

ESPGroupBox:AddToggle('ESPShowTeam', {
    Text = 'Show Team',
    Default = ESPSettings.ShowTeam
})

Toggles.ESPShowTeam:OnChanged(function()
    ESPSettings.ShowTeam = Toggles.ESPShowTeam.Value
end)

ESPGroupBox:AddToggle('ESPRainbow', {
    Text = 'Rainbow',
    Default = ESPSettings.Rainbow
})

Toggles.ESPRainbow:OnChanged(function()
    ESPSettings.Rainbow = Toggles.ESPRainbow.Value
end)

ESPGroupBox:AddToggle('ESPTeamCheck', {
    Text = 'Team Check',
    Default = ESPSettings.Team_Check
})

Toggles.ESPTeamCheck:OnChanged(function()
    ESPSettings.Team_Check = Toggles.ESPTeamCheck.Value
end)

ESPGroupBox:AddToggle('ESPTeamColor', {
    Text = 'Team Color',
    Default = ESPSettings.Team_Color
})

Toggles.ESPTeamColor:OnChanged(function()
    ESPSettings.Team_Color = Toggles.ESPTeamColor.Value
end)

ESPGroupBox:AddToggle('ESPAutothickness', {
    Text = 'Auto Thickness',
    Default = ESPSettings.Autothickness
})

Toggles.ESPAutothickness:OnChanged(function()
    ESPSettings.Autothickness = Toggles.ESPAutothickness.Value
end)

ESPGroupBox:AddSlider('ESPThickness', {
    Text = 'Box Thickness',
    Default = ESPSettings.Box_Thickness,
    Min = 1,
    Max = 6,
    Rounding = 1,
    Compact = false
})

Options.ESPThickness:OnChanged(function()
    ESPSettings.Box_Thickness = Options.ESPThickness.Value
end)

ESPGroupBox:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', {
    Default = ESPSettings.Box_Color,
    Title = 'ESP Box Color'
})

Options.ESPBoxColor:OnChanged(function()
    ESPSettings.Box_Color = Options.ESPBoxColor.Value
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Menu keybind'
})

Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle('Watermark', {
    Text = 'Watermark',
    Default = true
})

Toggles.Watermark:OnChanged(function()
    Library:SetWatermarkVisibility(Toggles.Watermark.Value)
end)

MenuGroup:AddLabel('Config Bind'):AddKeyPicker('ConfigBind', {
    Default = 'F5',
    NoUI = false,
    Text = 'Config bind',
    Mode = 'Toggle'
})

local ConfigGroup = Tabs['UI Settings']:AddRightGroupbox('Configs')

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
    'MenuKeybind'
})

ThemeManager:SetFolder('Leetware')
SaveManager:SetFolder('Leetware/configs')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:SetWatermarkVisibility(true)
Library:SetWatermark('Leetware')

Library:OnUnload(function()
    if ESPController then
        ESPController:Destroy()
        ESPController = nil
    end

    Library.Unloaded = true
end)

SaveManager:LoadAutoloadConfig()