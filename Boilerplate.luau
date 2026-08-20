local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local espRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/ESP.luau'
local chamsRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Chams.luau'
local tracersRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Tracers.luau'
local aimbotRepo = 'https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Aimbot.luau'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ESPSettings = {
    Box = {
        Enabled = true,
        Style = "Corner",
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        TeamCheck = false,
        TeamColor = false,
        Rainbow = false,
        AutoThickness = false
    },

    Fill = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Opacity = 0.15
    },

    Information = {
        ShowName = false,
        ShowTeam = false,
        CustomTextColor = false,
        NameColor = Color3.fromRGB(255, 255, 255),
        TeamTextColor = Color3.fromRGB(255, 255, 255),
        NameScale = 14,
        Font = "UI"
    },

    Health = {
        Enabled = false,
        BorderColor = Color3.fromRGB(0, 0, 0),
        FillColor = Color3.fromRGB(255, 255, 255)
    },

    TeamColor = {
        BoxBorder = false,
        BoxFill = false,
        Text = false,
        HealthBorder = false,
        HealthFill = false,
        DarkenBorders = false,
        DarkenAmount = 50
    },

    Chams = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
        Outline = true,
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
    },

    Aimbot = {
        Enabled = false,
        Bind = "MB2",
        Fov = 100,
        Smoothing = 5,
        Prediction = 0.065,
        WallCheck = true,
        LockAim = true,
        TeamCheck = false,
        HealthCheck = false,
        MinHealth = 0,
        FovColor = Color3.fromRGB(255, 0, 0),
        TargetedFovColor = Color3.fromRGB(0, 255, 0),
        RainbowFov = false,
        RainbowSpeed = 0.005
    }
}

local function LoadModule(url, name)
    local source = game:HttpGet(url)
    local chunk, compileError = loadstring(source)

    assert(
        chunk,
        string.format(
            'Failed to compile %s: %s',
            name,
            tostring(compileError)
        )
    )

    local module = chunk()

    assert(
        module and type(module.new) == 'function',
        string.format('%s did not return a valid module', name)
    )

    return module
end

local ESPModule = LoadModule(espRepo, 'ESP')
local ChamsModule = LoadModule(chamsRepo, 'Chams')
local TracersModule = LoadModule(tracersRepo, 'Tracers')
local AimbotModule = LoadModule(aimbotRepo, 'Aimbot')

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

local AimbotController = AimbotModule.new({
    Players = Players,
    RunService = RunService,
    Workspace = Workspace,
    Player = Player,
    UserInputService = UserInputService,
    Settings = ESPSettings.Aimbot
})

local Window = Library:CreateWindow({
    Title = 'leetware',
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Aimbot = Window:AddTab('Aimbot'),
    ['UI Settings'] = Window:AddTab('UI Settings')
}

local MainGroupBox = Tabs.Main:AddLeftGroupbox('Main')

MainGroupBox:AddLabel('leetware, you are in a game that doesnt have a specific script for it, thus you are using the universal one. the main tab will have nothing but placeholder content. if this is an error, report it to arcmage.js on discord.')

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
    Default = ESPSettings.Box.Enabled
})

Toggles.ESPEnabled:OnChanged(function()
    ESPSettings.Box.Enabled = Toggles.ESPEnabled.Value
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
    ESPSettings.Box.Style = Options.ESPBoxStyle.Value
end)

BoxGroupBox:AddLabel('Box Color'):AddColorPicker('ESPBoxColor', {
    Default = ESPSettings.Box.Color,
    Title = 'Box Color'
})

Options.ESPBoxColor:OnChanged(function()
    ESPSettings.Box.Color = Options.ESPBoxColor.Value
end)

BoxGroupBox:AddToggle('ESPRainbow', {
    Text = 'Rainbow',
    Default = ESPSettings.Box.Rainbow
})

Toggles.ESPRainbow:OnChanged(function()
    ESPSettings.Box.Rainbow = Toggles.ESPRainbow.Value
end)

BoxGroupBox:AddToggle('ESPTeamCheck', {
    Text = 'Team Check',
    Default = ESPSettings.Box.TeamCheck
})

Toggles.ESPTeamCheck:OnChanged(function()
    ESPSettings.Box.TeamCheck = Toggles.ESPTeamCheck.Value
end)

BoxGroupBox:AddToggle('ESPAutothickness', {
    Text = 'Auto Thickness',
    Default = ESPSettings.Box.AutoThickness
})

Toggles.ESPAutothickness:OnChanged(function()
    ESPSettings.Box.AutoThickness = Toggles.ESPAutothickness.Value
end)

BoxGroupBox:AddSlider('ESPThickness', {
    Text = 'Box Thickness',
    Default = ESPSettings.Box.Thickness,
    Min = 1,
    Max = 6,
    Rounding = 1,
    Compact = false
})

Options.ESPThickness:OnChanged(function()
    ESPSettings.Box.Thickness = Options.ESPThickness.Value
end)

local FillGroupBox = Tabs.Visuals:AddRightGroupbox('Fill')

local FillToggle = FillGroupBox:AddToggle('ESPFillBox', {
    Text = 'Fill Box',
    Default = ESPSettings.Fill.Enabled
})

FillToggle:AddColorPicker('ESPFillBoxColor', {
    Default = ESPSettings.Fill.Color,
    Title = 'Fill Color'
})

Toggles.ESPFillBox:OnChanged(function()
    ESPSettings.Fill.Enabled = Toggles.ESPFillBox.Value
end)

Options.ESPFillBoxColor:OnChanged(function()
    ESPSettings.Fill.Color = Options.ESPFillBoxColor.Value
end)

FillGroupBox:AddSlider('ESPFillOpacity', {
    Text = 'Fill Opacity',
    Default = math.floor((1 - ESPSettings.Fill.Opacity) * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPFillOpacity:OnChanged(function()
    ESPSettings.Fill.Opacity = 1 - (Options.ESPFillOpacity.Value / 100)
end)

local ChamsGroupBox = Tabs.Visuals:AddRightGroupbox('Chams')

local TeamColorGroupBox = Tabs.Visuals:AddRightGroupbox('Team Color')

TeamColorGroupBox:AddDropdown('ESPTeamColor', {
    Values = {
        'Box Border',
        'Box Fill',
        'Text',
        'Health Border',
        'Health Fill'
    },
    Default = {
        ['Box Border'] = ESPSettings.TeamColor.BoxBorder,
        ['Box Fill'] = ESPSettings.TeamColor.BoxFill,
        Text = ESPSettings.TeamColor.Text,
        ['Health Border'] = ESPSettings.TeamColor.HealthBorder,
        ['Health Fill'] = ESPSettings.TeamColor.HealthFill
    },
    Multi = true,
    Text = 'Apply Team Color'
})

Options.ESPTeamColor:OnChanged(function()
    local values = Options.ESPTeamColor.Value

    ESPSettings.TeamColor.BoxBorder = values['Box Border'] == true
    ESPSettings.TeamColor.BoxFill = values['Box Fill'] == true
    ESPSettings.TeamColor.Text = values.Text == true
    ESPSettings.TeamColor.HealthBorder = values['Health Border'] == true
    ESPSettings.TeamColor.HealthFill = values['Health Fill'] == true
end)

TeamColorGroupBox:AddToggle('ESPDarkenBorders', {
    Text = 'Darken Borders',
    Default = ESPSettings.TeamColor.DarkenBorders
})

Toggles.ESPDarkenBorders:OnChanged(function()
    ESPSettings.TeamColor.DarkenBorders =
        Toggles.ESPDarkenBorders.Value
end)

TeamColorGroupBox:AddSlider('ESPDarkenAmount', {
    Text = 'Darken Amount',
    Default = ESPSettings.TeamColor.DarkenAmount,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPDarkenAmount:OnChanged(function()
    ESPSettings.TeamColor.DarkenAmount =
        Options.ESPDarkenAmount.Value
end)

local ChamsToggle = ChamsGroupBox:AddToggle('ESPChams', {
    Text = 'Enabled',
    Default = ESPSettings.Chams.Enabled
})

ChamsToggle:AddColorPicker('ESPChamsColor', {
    Default = ESPSettings.Chams.Color,
    Title = 'Chams Color'
})

ChamsToggle:OnChanged(function()
    ESPSettings.Chams.Enabled = ChamsToggle.Value
end)

Options.ESPChamsColor:OnChanged(function()
    ESPSettings.Chams.Color = Options.ESPChamsColor.Value
end)

ChamsGroupBox:AddSlider('ESPChamsTransparency', {
    Text = 'Transparency',
    Default = math.floor(ESPSettings.Chams.Transparency * 100),
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.ESPChamsTransparency:OnChanged(function()
    ESPSettings.Chams.Transparency = Options.ESPChamsTransparency.Value / 100
end)

local ChamsOutlineToggle = ChamsGroupBox:AddToggle('ESPChamsOutline', {
    Text = 'Outline',
    Default = ESPSettings.Chams.Outline
})

ChamsOutlineToggle:AddColorPicker('ESPChamsOutlineColor', {
    Default = ESPSettings.Chams.OutlineColor,
    Title = 'Outline Color'
})

Toggles.ESPChamsOutline:OnChanged(function()
    ESPSettings.Chams.Outline = Toggles.ESPChamsOutline.Value

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

    if Options.ESPChamsOutlineTransparency.Value >= 100 then
        ESPSettings.Chams.Outline = false
    end
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

TracerToggle:OnChanged(function()
    ESPSettings.Tracers.Enabled = TracerToggle.Value
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

local AimbotGroupBox = Tabs.Aimbot:AddLeftGroupbox('Aimbot')

local AimbotToggle = AimbotGroupBox:AddToggle('AimbotEnabled', {
    Text = 'Enabled',
    Default = ESPSettings.Aimbot.Enabled
})

AimbotToggle:OnChanged(function()
    ESPSettings.Aimbot.Enabled = AimbotToggle.Value
end)

AimbotGroupBox:AddLabel('Aim Bind'):AddKeyPicker('AimbotBind', {
    Default = ESPSettings.Aimbot.Bind,
    NoUI = false,
    Text = 'Aim bind',
    Mode = 'Hold',
    ChangedCallback = function(value)
        ESPSettings.Aimbot.Bind = value
    end
})

AimbotGroupBox:AddToggle('AimbotLockAim', {
    Text = 'Lock Aim',
    Default = ESPSettings.Aimbot.LockAim
})

Toggles.AimbotLockAim:OnChanged(function()
    ESPSettings.Aimbot.LockAim = Toggles.AimbotLockAim.Value
end)

AimbotGroupBox:AddToggle('AimbotWallCheck', {
    Text = 'Wall Check',
    Default = ESPSettings.Aimbot.WallCheck
})

Toggles.AimbotWallCheck:OnChanged(function()
    ESPSettings.Aimbot.WallCheck = Toggles.AimbotWallCheck.Value
end)

AimbotGroupBox:AddToggle('AimbotTeamCheck', {
    Text = 'Team Check',
    Default = ESPSettings.Aimbot.TeamCheck
})

Toggles.AimbotTeamCheck:OnChanged(function()
    ESPSettings.Aimbot.TeamCheck = Toggles.AimbotTeamCheck.Value
end)

AimbotGroupBox:AddToggle('AimbotHealthCheck', {
    Text = 'Health Check',
    Default = ESPSettings.Aimbot.HealthCheck
})

Toggles.AimbotHealthCheck:OnChanged(function()
    ESPSettings.Aimbot.HealthCheck = Toggles.AimbotHealthCheck.Value
end)

AimbotGroupBox:AddSlider('AimbotMinHealth', {
    Text = 'Minimum Health',
    Default = ESPSettings.Aimbot.MinHealth,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.AimbotMinHealth:OnChanged(function()
    ESPSettings.Aimbot.MinHealth = Options.AimbotMinHealth.Value
end)

local AimbotSettingsGroupBox = Tabs.Aimbot:AddRightGroupbox('Settings')

AimbotSettingsGroupBox:AddSlider('AimbotFov', {
    Text = 'Aim FOV',
    Default = ESPSettings.Aimbot.Fov,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Compact = false
})

Options.AimbotFov:OnChanged(function()
    ESPSettings.Aimbot.Fov = Options.AimbotFov.Value
end)

AimbotSettingsGroupBox:AddSlider('AimbotSmoothing', {
    Text = 'Smoothing',
    Default = ESPSettings.Aimbot.Smoothing,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false
})

Options.AimbotSmoothing:OnChanged(function()
    ESPSettings.Aimbot.Smoothing = Options.AimbotSmoothing.Value
end)

AimbotSettingsGroupBox:AddSlider('AimbotPrediction', {
    Text = 'Prediction Strength',
    Default = ESPSettings.Aimbot.Prediction,
    Min = 0,
    Max = 0.2,
    Rounding = 3,
    Compact = false
})

Options.AimbotPrediction:OnChanged(function()
    ESPSettings.Aimbot.Prediction = Options.AimbotPrediction.Value
end)

AimbotSettingsGroupBox:AddLabel('FOV Color'):AddColorPicker('AimbotFovColor', {
    Default = ESPSettings.Aimbot.FovColor,
    Title = 'FOV Color'
})

Options.AimbotFovColor:OnChanged(function()
    ESPSettings.Aimbot.FovColor = Options.AimbotFovColor.Value
end)

AimbotSettingsGroupBox:AddLabel('Targeted FOV Color'):AddColorPicker('AimbotTargetedFovColor', {
    Default = ESPSettings.Aimbot.TargetedFovColor,
    Title = 'Targeted FOV Color'
})

Options.AimbotTargetedFovColor:OnChanged(function()
    ESPSettings.Aimbot.TargetedFovColor =
        Options.AimbotTargetedFovColor.Value
end)

AimbotSettingsGroupBox:AddToggle('AimbotRainbowFov', {
    Text = 'Rainbow FOV',
    Default = ESPSettings.Aimbot.RainbowFov
})

Toggles.AimbotRainbowFov:OnChanged(function()
    ESPSettings.Aimbot.RainbowFov = Toggles.AimbotRainbowFov.Value
end)

local InfoGroupBox = Tabs.Visuals:AddLeftGroupbox('Information')

local ShowNameToggle = InfoGroupBox:AddToggle('ESPShowName', {
    Text = 'Show Name',
    Default = ESPSettings.Information.ShowName
})

ShowNameToggle:AddColorPicker('ESPNameColor', {
    Default = ESPSettings.Information.NameColor,
    Title = 'Name Color'
})

Toggles.ESPShowName:OnChanged(function()
    ESPSettings.Information.ShowName = Toggles.ESPShowName.Value
end)

Options.ESPNameColor:OnChanged(function()
    ESPSettings.Information.NameColor = Options.ESPNameColor.Value
end)

local ShowTeamToggle = InfoGroupBox:AddToggle('ESPShowTeam', {
    Text = 'Show Team',
    Default = ESPSettings.Information.ShowTeam
})

ShowTeamToggle:AddColorPicker('ESPTeamTextColor', {
    Default = ESPSettings.Information.TeamTextColor,
    Title = 'Team Color'
})

Toggles.ESPShowTeam:OnChanged(function()
    ESPSettings.Information.ShowTeam = Toggles.ESPShowTeam.Value
end)

Options.ESPTeamTextColor:OnChanged(function()
    ESPSettings.Information.TeamTextColor = Options.ESPTeamTextColor.Value
end)

InfoGroupBox:AddToggle('ESPCustomTextColor', {
    Text = 'Custom Text Colors',
    Default = ESPSettings.Information.CustomTextColor
})

Toggles.ESPCustomTextColor:OnChanged(function()
    ESPSettings.Information.CustomTextColor = Toggles.ESPCustomTextColor.Value
end)

InfoGroupBox:AddSlider('ESPNameScale', {
    Text = 'Name Scale',
    Default = ESPSettings.Information.NameScale,
    Min = 10,
    Max = 24,
    Rounding = 0,
    Compact = false
})

Options.ESPNameScale:OnChanged(function()
    ESPSettings.Information.NameScale = Options.ESPNameScale.Value
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
    ESPSettings.Information.Font = Options.ESPFont.Value
end)

local ShowHealthToggle = InfoGroupBox:AddToggle('ESPShowHealth', {
    Text = 'Show Health',
    Default = ESPSettings.Health.Enabled
})

ShowHealthToggle:AddColorPicker('ESPHealthBorderColor', {
    Default = ESPSettings.Health.BorderColor,
    Title = 'Health Border Color'
})

ShowHealthToggle:AddColorPicker('ESPHealthFillColor', {
    Default = ESPSettings.Health.FillColor,
    Title = 'Health Fill Color'
})

Toggles.ESPShowHealth:OnChanged(function()
    ESPSettings.Health.Enabled = Toggles.ESPShowHealth.Value
end)

Options.ESPHealthBorderColor:OnChanged(function()
    ESPSettings.Health.BorderColor = Options.ESPHealthBorderColor.Value
end)

Options.ESPHealthFillColor:OnChanged(function()
    ESPSettings.Health.FillColor = Options.ESPHealthFillColor.Value
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

    if AimbotController then
        AimbotController:Destroy()
        AimbotController = nil
    end

    Library.Unloaded = true
end)

SaveManager:LoadAutoloadConfig()