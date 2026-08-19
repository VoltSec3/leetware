local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local espRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/refs/heads/main/Modules/ESP.luau'
local chamsRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/refs/heads/main/Modules/Chams.luau'
local tracersRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/refs/heads/main/Modules/Tracers.luau'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ESPSettings = {
    Enabled = true,
    BoxStyle = "Corner",
    Box_Color = Color3.fromRGB(255, 0, 0),
    Box_Thickness = 2,
    Team_Check = false,
    Team_Color = false,
    Rainbow = false,
    Autothickness = false,
    Corner_Length = nil,
    FillBox = false,
    Fill_Box_Color = Color3.fromRGB(255, 0, 0),
    Fill_Opacity = 0.15,
    ShowName = false,
    ShowTeam = false,
    ShowHealth = false,
    CustomTextColor = false,
    Name_Color = Color3.fromRGB(255, 255, 255),
    Team_Text_Color = Color3.fromRGB(255, 255, 255),
    Name_Scale = 14,
    Font = "UI",
    HealthBorder_Color = Color3.fromRGB(0, 0, 0),
    HealthFill_Color = Color3.fromRGB(255, 255, 255),

    Chams = {
        Enabled = false,
        FillColor = Color3.fromRGB(255, 0, 0),
        FillTransparency = 0.5,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
        AlwaysOnTop = true
    },

    Tracers = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 1,
        Transparency = 1,
        Origin = "Bottom"
    }
}

local ESPModule = loadstring(game:HttpGet(espRepo))()
local ChamsModule = loadstring(game:HttpGet(chamsRepo))()
local TracersModule = loadstring(game:HttpGet(tracersRepo))()

local ESPController = ESPModule.new({
    Players = Players,
    RunService = RunService,
    Workspace = Workspace,
    Player = Player,
    Settings = ESPSettings,
    UserInputService = UserInputService
})

local ChamsController = ChamsModule.new({
    Players = Players,
    RunService = RunService,
    Workspace = Workspace,
    Player = Player,
    Settings = ESPSettings
})

local TracersController = TracersModule.new({
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

BoxGroupBox:AddDropdown('ESPBoxStyle', {
    Values = {
        'Corner',
        'Normal'
    },
    Default = 1,
    Multi = false,
    Text = 'Box Style'
})

Options.ESPBoxStyle:OnChanged(function()
    ESPSettings.BoxStyle = Options.ESPBoxStyle.Value
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

local FillToggle = FillGroupBox:AddToggle('ESPFillBox', {
    Text = 'Fill Box',
    Default = ESPSettings.FillBox
})

FillToggle:AddColorPicker('ESPFillBoxColor', {
    Default = ESPSettings.Fill_Box_Color,
    Title = 'Fill Color'
})

Toggles.ESPFillBox:OnChanged(function()
    ESPSettings.FillBox = Toggles.ESPFillBox.Value
end)

Options.ESPFillBoxColor:OnChanged(function()
    ESPSettings.Fill_Box_Color = Options.ESPFillBoxColor.Value
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

local ChamsGroupBox = Tabs.Visuals:AddRightGroupbox('Chams')

local ChamsToggle = ChamsGroupBox:AddToggle('ESPChams', {
    Text = 'Enabled',
    Default = ESPSettings.Chams.Enabled
})

ChamsToggle:AddColorPicker('ESPChamsFillColor', {
    Default = ESPSettings.Chams.FillColor,
    Title = 'Fill Color'
})

Toggles.ESPChams:OnChanged(function()
    ESPSettings.Chams.Enabled = Toggles.ESPChams.Value
end)

Options.ESPChamsFillColor:OnChanged(function()
    ESPSettings.Chams.FillColor = Options.ESPChamsFillColor.Value
end)

ChamsGroupBox:AddSlider('ESPChamsFillTransparency', {
    Text = 'Fill Transparency',
    Default = math.floor(ESPSettings.Chams.FillTransparency * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPChamsFillTransparency:OnChanged(function()
    ESPSettings.Chams.FillTransparency = Options.ESPChamsFillTransparency.Value / 100
end)

local ChamsOutlineToggle = ChamsGroupBox:AddToggle('ESPChamsOutline', {
    Text = 'Outline',
    Default = ESPSettings.Chams.OutlineTransparency < 1
})

ChamsOutlineToggle:AddColorPicker('ESPChamsOutlineColor', {
    Default = ESPSettings.Chams.OutlineColor,
    Title = 'Outline Color'
})

Toggles.ESPChamsOutline:OnChanged(function()
    if Toggles.ESPChamsOutline.Value then
        ESPSettings.Chams.OutlineTransparency = 0
    else
        ESPSettings.Chams.OutlineTransparency = 1
    end
end)

Options.ESPChamsOutlineColor:OnChanged(function()
    ESPSettings.Chams.OutlineColor = Options.ESPChamsOutlineColor.Value
end)

ChamsGroupBox:AddSlider('ESPChamsOutlineTransparency', {
    Text = 'Outline Transparency',
    Default = math.floor(ESPSettings.Chams.OutlineTransparency * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPChamsOutlineTransparency:OnChanged(function()
    ESPSettings.Chams.OutlineTransparency = Options.ESPChamsOutlineTransparency.Value / 100
end)

ChamsGroupBox:AddToggle('ESPChamsAlwaysOnTop', {
    Text = 'Always On Top',
    Default = ESPSettings.Chams.AlwaysOnTop
})

Toggles.ESPChamsAlwaysOnTop:OnChanged(function()
    ESPSettings.Chams.AlwaysOnTop = Toggles.ESPChamsAlwaysOnTop.Value
end)

local TracerGroupBox = Tabs.Visuals:AddLeftGroupbox('Tracers')

local TracerToggle = TracerGroupBox:AddToggle('ESPTracers', {
    Text = 'Enabled',
    Default = ESPSettings.Tracers.Enabled
})

TracerToggle:AddColorPicker('ESPTracerColor', {
    Default = ESPSettings.Tracers.Color,
    Title = 'Tracer Color'
})

Toggles.ESPTracers:OnChanged(function()
    ESPSettings.Tracers.Enabled = Toggles.ESPTracers.Value
end)

Options.ESPTracerColor:OnChanged(function()
    ESPSettings.Tracers.Color = Options.ESPTracerColor.Value
end)

TracerGroupBox:AddSlider('ESPTracerThickness', {
    Text = 'Thickness',
    Default = ESPSettings.Tracers.Thickness,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Compact = false
})

Options.ESPTracerThickness:OnChanged(function()
    ESPSettings.Tracers.Thickness = Options.ESPTracerThickness.Value
end)

TracerGroupBox:AddSlider('ESPTracerTransparency', {
    Text = 'Transparency',
    Default = math.floor(ESPSettings.Tracers.Transparency * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPTracerTransparency:OnChanged(function()
    ESPSettings.Tracers.Transparency = Options.ESPTracerTransparency.Value / 100
end)

TracerGroupBox:AddDropdown('ESPTracerOrigin', {
    Values = {
        'Bottom',
        'Center',
        'Top'
    },
    Default = 1,
    Multi = false,
    Text = 'Origin'
})

Options.ESPTracerOrigin:OnChanged(function()
    ESPSettings.Tracers.Origin = Options.ESPTracerOrigin.Value
end)

local InfoGroupBox = Tabs.Visuals:AddLeftGroupbox('Information')

local ShowNameToggle = InfoGroupBox:AddToggle('ESPShowName', {
    Text = 'Show Name',
    Default = ESPSettings.ShowName
})

ShowNameToggle:AddColorPicker('ESPNameColor', {
    Default = ESPSettings.Name_Color,
    Title = 'Name Color'
})

Toggles.ESPShowName:OnChanged(function()
    ESPSettings.ShowName = Toggles.ESPShowName.Value
end)

Options.ESPNameColor:OnChanged(function()
    ESPSettings.Name_Color = Options.ESPNameColor.Value
end)

local ShowTeamToggle = InfoGroupBox:AddToggle('ESPShowTeam', {
    Text = 'Show Team',
    Default = ESPSettings.ShowTeam
})

ShowTeamToggle:AddColorPicker('ESPTeamTextColor', {
    Default = ESPSettings.Team_Text_Color,
    Title = 'Team Color'
})

Toggles.ESPShowTeam:OnChanged(function()
    ESPSettings.ShowTeam = Toggles.ESPShowTeam.Value
end)

Options.ESPTeamTextColor:OnChanged(function()
    ESPSettings.Team_Text_Color = Options.ESPTeamTextColor.Value
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

local ShowHealthToggle = InfoGroupBox:AddToggle('ESPShowHealth', {
    Text = 'Show Health',
    Default = ESPSettings.ShowHealth
})

ShowHealthToggle:AddColorPicker('ESPHealthBorderColor', {
    Default = ESPSettings.HealthBorder_Color,
    Title = 'Health Border Color'
})

ShowHealthToggle:AddColorPicker('ESPHealthFillColor', {
    Default = ESPSettings.HealthFill_Color,
    Title = 'Health Fill Color'
})

Toggles.ESPShowHealth:OnChanged(function()
    ESPSettings.ShowHealth = Toggles.ESPShowHealth.Value
end)

Options.ESPHealthBorderColor:OnChanged(function()
    ESPSettings.HealthBorder_Color = Options.ESPHealthBorderColor.Value
end)

Options.ESPHealthFillColor:OnChanged(function()
    ESPSettings.HealthFill_Color = Options.ESPHealthFillColor.Value
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

local fps = 0
local frames = 0
local last = os.clock()

Library:SetWatermark("leetware | 0 FPS | 0 ms")

RunService.Heartbeat:Connect(function()
    frames += 1

    local now = os.clock()

    if now - last >= 0.25 then
        fps = math.round(frames / (now - last))
        frames = 0
        last = now

        local ping = math.round(Stats.PerformanceStats.Ping:GetValue())

        Library:SetWatermark(
            string.format(
                "leetware | %d FPS | %d ms",
                fps,
                ping
            )
        )
    end
end)

Library:OnUnload(function()
    if ESPController then
        ESPController:Destroy()
        ESPController = nil
    end

    if ChamsController then
        ChamsController:Destroy()
        ChamsController = nil
    end

    if TracersController then
        TracersController:Destroy()
        TracersController = nil
    end

    Library.Unloaded = true
end)

SaveManager:LoadAutoloadConfig()