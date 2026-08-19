local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local espRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/refs/heads/main/Modules/ESP.luau'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

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
    Fill_Opacity = 0.15,

    ShowName = false,
    ShowTeam = false,
    ShowHealth = false,
    CustomTextColor = false,
    Name_Color = Color3.fromRGB(255, 255, 255),
    Team_Text_Color = Color3.fromRGB(255, 255, 255),
    Name_Scale = 14,
    Font = "UI",

    HealthBorder_Color = Color3.fromRGB(255, 255, 255),
    HealthFill_Color = Color3.fromRGB(255, 255, 255)
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
    Title = 'leetware',
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

local MainGroupBox = Tabs.Main:AddLeftGroupbox('Main')

MainGroupBox:AddLabel('leetware')

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

local BoxGroupBox = Tabs.Visuals:AddLeftGroupbox('Box')

BoxGroupBox:AddToggle('ESPEnabled', {
    Text = 'Enabled',
    Default = ESPSettings.Enabled
})

Toggles.ESPEnabled:OnChanged(function()
    ESPSettings.Enabled = Toggles.ESPEnabled.Value
end)

BoxGroupBox:AddToggle('ESPCornerBox', {
    Text = 'Corner Box',
    Default = ESPSettings.CornerBox
})

Toggles.ESPCornerBox:OnChanged(function()
    ESPSettings.CornerBox = Toggles.ESPCornerBox.Value
end)

BoxGroupBox:AddToggle('ESPNormalBox', {
    Text = 'Normal Box',
    Default = ESPSettings.NormalBox
})

Toggles.ESPNormalBox:OnChanged(function()
    ESPSettings.NormalBox = Toggles.ESPNormalBox.Value
end)

BoxGroupBox:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', {
    Default = ESPSettings.Box_Color,
    Title = 'Box Color'
})

Options.ESPBoxColor:OnChanged(function()
    ESPSettings.Box_Color = Options.ESPBoxColor.Value
end)

BoxGroupBox:AddToggle('ESPRainbow', {
    Text = 'Rainbow',
    Default = ESPSettings.Rainbow
})

Toggles.ESPRainbow:OnChanged(function()
    ESPSettings.Rainbow = Toggles.ESPRainbow.Value
end)

BoxGroupBox:AddToggle('ESPTeamCheck', {
    Text = 'Team Check',
    Default = ESPSettings.Team_Check
})

Toggles.ESPTeamCheck:OnChanged(function()
    ESPSettings.Team_Check = Toggles.ESPTeamCheck.Value
end)

BoxGroupBox:AddToggle('ESPTeamColor', {
    Text = 'Team Color',
    Default = ESPSettings.Team_Color
})

Toggles.ESPTeamColor:OnChanged(function()
    ESPSettings.Team_Color = Toggles.ESPTeamColor.Value
end)

BoxGroupBox:AddToggle('ESPAutothickness', {
    Text = 'Auto Thickness',
    Default = ESPSettings.Autothickness
})

Toggles.ESPAutothickness:OnChanged(function()
    ESPSettings.Autothickness = Toggles.ESPAutothickness.Value
end)

BoxGroupBox:AddSlider('ESPThickness', {
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

local FillGroupBox = Tabs.Visuals:AddRightGroupbox('Fill')

FillGroupBox:AddToggle('ESPFillBox', {
    Text = 'Fill Box',
    Default = ESPSettings.FillBox
})

Toggles.ESPFillBox:OnChanged(function()
    ESPSettings.FillBox = Toggles.ESPFillBox.Value
end)

FillGroupBox:AddLabel('Fill Color'):AddColorPicker('ESPFillBoxColor', {
    Default = ESPSettings.Fill_Box_Color,
    Title = 'Fill Color'
})

Options.ESPFillBoxColor:OnChanged(function()
    ESPSettings.Fill_Box_Color = Options.ESPFillBoxColor.Value
end)

FillGroupBox:AddToggle('ESPFillBoxGradient', {
    Text = 'Gradient',
    Default = ESPSettings.FillBoxGradient
})

Toggles.ESPFillBoxGradient:OnChanged(function()
    ESPSettings.FillBoxGradient = Toggles.ESPFillBoxGradient.Value
end)

FillGroupBox:AddLabel('Gradient Start'):AddColorPicker('ESPGradientColor1', {
    Default = ESPSettings.Gradient_Color_1,
    Title = 'Gradient Start'
})

Options.ESPGradientColor1:OnChanged(function()
    ESPSettings.Gradient_Color_1 = Options.ESPGradientColor1.Value
end)

FillGroupBox:AddLabel('Gradient End'):AddColorPicker('ESPGradientColor2', {
    Default = ESPSettings.Gradient_Color_2,
    Title = 'Gradient End'
})

Options.ESPGradientColor2:OnChanged(function()
    ESPSettings.Gradient_Color_2 = Options.ESPGradientColor2.Value
end)

FillGroupBox:AddSlider('ESPFillOpacity', {
    Text = 'Fill Opacity',
    Default = math.floor((1 - ESPSettings.Fill_Opacity) * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPFillOpacity:OnChanged(function()
    ESPSettings.Fill_Opacity = 1 - (Options.ESPFillOpacity.Value / 100)
end)

local InfoGroupBox = Tabs.Visuals:AddLeftGroupbox('Information')

InfoGroupBox:AddToggle('ESPShowName', {
    Text = 'Show Name',
    Default = ESPSettings.ShowName
})

Toggles.ESPShowName:OnChanged(function()
    ESPSettings.ShowName = Toggles.ESPShowName.Value
end)

InfoGroupBox:AddLabel('Name Color'):AddColorPicker('ESPNameColor', {
    Default = ESPSettings.Name_Color,
    Title = 'Name Color'
})

Options.ESPNameColor:OnChanged(function()
    ESPSettings.Name_Color = Options.ESPNameColor.Value
end)

InfoGroupBox:AddToggle('ESPShowTeam', {
    Text = 'Show Team',
    Default = ESPSettings.ShowTeam
})

Toggles.ESPShowTeam:OnChanged(function()
    ESPSettings.ShowTeam = Toggles.ESPShowTeam.Value
end)

InfoGroupBox:AddLabel('Team Color'):AddColorPicker('ESPTeamTextColor', {
    Default = ESPSettings.Team_Text_Color,
    Title = 'Team Color'
})

Options.ESPTeamTextColor:OnChanged(function()
    ESPSettings.Team_Text_Color = Options.ESPTeamTextColor.Value
end)

InfoGroupBox:AddToggle('ESPShowHealth', {
    Text = 'Show Health',
    Default = ESPSettings.ShowHealth
})

Toggles.ESPShowHealth:OnChanged(function()
    ESPSettings.ShowHealth = Toggles.ESPShowHealth.Value
end)

InfoGroupBox:AddLabel('Health Border'):AddColorPicker('ESPHealthBorderColor', {
    Default = ESPSettings.HealthBorder_Color,
    Title = 'Health Border Color'
})

Options.ESPHealthBorderColor:OnChanged(function()
    ESPSettings.HealthBorder_Color = Options.ESPHealthBorderColor.Value
end)

InfoGroupBox:AddLabel('Health Fill'):AddColorPicker('ESPHealthFillColor', {
    Default = ESPSettings.HealthFill_Color,
    Title = 'Health Fill Color'
})

Options.ESPHealthFillColor:OnChanged(function()
    ESPSettings.HealthFill_Color = Options.ESPHealthFillColor.Value
end)

InfoGroupBox:AddToggle('ESPCustomTextColor', {
    Text = 'Custom Text Colors',
    Default = ESPSettings.CustomTextColor
})

Toggles.ESPCustomTextColor:OnChanged(function()
    ESPSettings.CustomTextColor = Toggles.ESPCustomTextColor.Value
end)

InfoGroupBox:AddSlider('ESPNameScale', {
    Text = 'Name Scale',
    Default = ESPSettings.Name_Scale,
    Min = 10,
    Max = 24,
    Rounding = 0,
    Compact = false
})

Options.ESPNameScale:OnChanged(function()
    ESPSettings.Name_Scale = Options.ESPNameScale.Value
end)

InfoGroupBox:AddDropdown('ESPFont', {
    Values = {
        'UI',
        'System',
        'Plex',
        'Monospace'
    },
    Default = 1,
    Multi = false,
    Text = 'Font'
})

Options.ESPFont:OnChanged(function()
    ESPSettings.Font = Options.ESPFont.Value
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

ThemeManager:SetFolder('leetware')
SaveManager:SetFolder('leetware/configs')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:SetWatermarkVisibility(true)

local RunService, Stats = game:GetService("RunService"), game:GetService("Stats")
local fps, frames, last = 0, 0, os.clock()

Library:SetWatermark("leetware | 0 FPS | 0 ms")

RunService.Heartbeat:Connect(function()
    frames += 1

    local now = os.clock()

    if now - last >= 0.25 then
        fps, frames, last = math.round(frames / (now - last)), 0, now

        local ping = math.round(Stats.PerformanceStats.Ping:GetValue())

        Library:SetWatermark(string.format(
            "leetware | %d FPS | %d ms",
            fps,
            ping
        ))
    end
end)

Library:OnUnload(function()
    if ESPController then
        ESPController:Destroy()
        ESPController = nil
    end

    Library.Unloaded = true
end)

SaveManager:LoadAutoloadConfig()