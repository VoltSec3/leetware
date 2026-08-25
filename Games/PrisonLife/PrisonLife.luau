-- leetware runtime guard: do not remove. this file only executes inside the official loader.
do
  local function __leet_expected()
    return "e96e0f9ca57a2b88"
  end
  local function __leet_key()
    return "prison-life"
  end
  local rt = _G.__leet_rt
  if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
    error("leetware: this script must be executed through the leetware loader.", 0)
  end
  local ok, provided = pcall(rt.verify, __leet_key())
  if not ok or provided ~= __leet_expected() then
    error("leetware: runtime verification failed.", 0)
  end
end
-- leetware runtime guard end

local repo='https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/'
local Library=loadstring(game:HttpGet(repo..'Library.lua'))()
local ThemeManager=loadstring(game:HttpGet(repo..'addons/ThemeManager.lua'))()
local SaveManager=loadstring(game:HttpGet(repo..'addons/SaveManager.lua'))()

-- Modules are delivered by the loader through the authenticated API and exposed
-- on _G.__leet_modules. They are never fetched directly from a raw URL here,
-- which keeps them behind the loader runtime guard.
local function GetModule(key)
	local module = _G.__leet_modules and _G.__leet_modules[key]

	if not module or type(module.new) ~= "function" then
		error("leetware: required module '" .. tostring(key) .. "' was not loaded by the loader.", 0)
	end

	return module
end

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local Stats=game:GetService("Stats")
local UserInputService=game:GetService("UserInputService")

local Player=Players.LocalPlayer
local GameId=tostring(game.GameId)
local ESPSettings={
    FriendCheck=false,

    Box={
        Enabled=true,
        Style="Corner",
        Color=Color3.fromRGB(255,0,0),
        Thickness=2,
        TeamCheck=false,
        TeamColor=false,
        AutoThickness=false
    },

    Fill={
        Enabled=false,
        Color=Color3.fromRGB(255,0,0),
        Opacity=0.15
    },

    Information={
        ShowName=false,
        ShowDisplayName=false,
        ShowWeapon=false,
        ShowTeam=false,
        CustomTextColor=false,
        NameColor=Color3.fromRGB(255,255,255),
        WeaponColor=Color3.fromRGB(255,255,255),
        TeamTextColor=Color3.fromRGB(255,255,255),
        NameScale=14,
        Font="UI"
    },

    Health={
        Enabled=false,
        BorderColor=Color3.fromRGB(0,0,0),
        FillColor=Color3.fromRGB(255,255,255)
    },

    TeamColor={
        BoxBorder=false,
        BoxFill=false,
        Text=false,
        HealthBorder=false,
        HealthFill=false,
        DarkenBorders=false,
        DarkenAmount=50
    },

    Chams={
        Enabled=false,
        Color=Color3.fromRGB(255,0,0),
        Transparency=0.5,
        Outline=true,
        OutlineColor=Color3.fromRGB(255,255,255),
        OutlineTransparency=0,
        AlwaysOnTop=true
    },

    Tracers={
        Enabled=false,
        ShowNotInView=false,
        Color=Color3.fromRGB(255,0,0),
        Thickness=1,
        Transparency=1,
        Origin="Bottom"
    },

    Aimbot={
        Enabled=false,
        Bind="MB2",
        Targeting="Normal",
        Range=500,
        Fov=100,
        Smoothing=5,
        Prediction=0.065,
        WallCheck=true,
        LockAim=true,
        TeamCheck=false,
        FriendCheck=false,
        HealthCheck=false,
        MinHealth=0,
        FovColor=Color3.fromRGB(255,0,0),
        TargetedFovColor=Color3.fromRGB(0,255,0),
        Triggerbot=false,
        TriggerbotDelay=0,
        ExcludeTeams={},
        PrioritizeTeams={}
    }
}

local function LoadModule(url,name)
    local source=game:HttpGet(url)
    local chunk,compileError=loadstring(source)

    assert(
        chunk,
        string.format('Failed to compile %s: %s',name,tostring(compileError))
    )

    local module=chunk()

    assert(
        module and type(module.new)=='function',
        string.format('%s did not return a valid module',name)
    )

    return module
end

local ESPModule=GetModule('esp')
local ChamsModule=GetModule('chams')
local TracersModule=GetModule('tracers')
local AimbotModule=GetModule('aimbot')
local Utils=GetModule('utils')

local ESPController=ESPModule.new({
    Players=Players,
    RunService=RunService,
    Workspace=Workspace,
    Player=Player,
    Settings=ESPSettings,
    UserInputService=UserInputService,
    Utils=Utils
})

local ChamsController=ChamsModule.new({
    Players=Players,
    RunService=RunService,
    Workspace=Workspace,
    Player=Player,
    Settings=ESPSettings,
    Utils=Utils
})

local TracersController=TracersModule.new({
    Players=Players,
    RunService=RunService,
    Workspace=Workspace,
    Player=Player,
    Settings=ESPSettings,
    Utils=Utils
})

local AimbotController=AimbotModule.new({
    Players=Players,
    RunService=RunService,
    Workspace=Workspace,
    Player=Player,
    UserInputService=UserInputService,
    Settings=ESPSettings.Aimbot,
    Utils=Utils
})

local GunTransparency=0
local GunTransparencyObjects={}

local CustomGunSounds=false
local CustomGunSoundValues={}
local CustomGunSoundIds=nil

local CustomGunSoundFiles={
    Shoot={
        URL='https://files.catbox.moe/lip2i4.mp3',
        File='leetware_shoot.mp3'
    },
    Reload={
        URL='https://files.catbox.moe/c4qtkm.mp3',
        File='leetware_reload.mp3'
    }
}

local function LoadCustomGunSounds()
    if CustomGunSoundIds then
        return true
    end

    local ids={}

    for name,data in pairs(CustomGunSoundFiles) do
        local success,result=pcall(function()
            if not isfile(data.File) then
                writefile(data.File,game:HttpGet(data.URL))
            end

            return getcustomasset(data.File)
        end)

        if not success then
            Library:Notify('Failed to load custom '..string.lower(name)..' sound',3)
            return false
        end

        ids[name]=result
    end

    CustomGunSoundIds=ids
    return true
end

local function SaveCustomGunSoundValue(tool,sound,name)
    CustomGunSoundValues[tool]=CustomGunSoundValues[tool] or {
        Sounds={},
        Attributes={},
        Captured={}
    }

    if not CustomGunSoundValues[tool].Captured[name] then
        CustomGunSoundValues[tool].Sounds[name]=sound.SoundId
        CustomGunSoundValues[tool].Attributes[name]=tool:GetAttribute(name)
        CustomGunSoundValues[tool].Captured[name]=true
    end
end

local function UpdateCustomGunSound(tool)
    if not CustomGunSoundIds or not tool:IsA('Tool') then
        return
    end

    local handle=tool:FindFirstChild('Handle')

    if not handle then
        return
    end

    local sounds={
        Shoot={Object=handle:FindFirstChild('ShootSound'),Id=CustomGunSoundIds.Shoot},
        Reload={Object=handle:FindFirstChild('ReloadSound'),Id=CustomGunSoundIds.Reload}
    }

    for name,data in pairs(sounds) do
        if data.Object and data.Object:IsA('Sound') then
            SaveCustomGunSoundValue(tool,data.Object,name)
            data.Object.SoundId=data.Id
            tool:SetAttribute(name..'SoundId',data.Id)
        end
    end
end

local function RestoreCustomGunSounds()
    for tool,data in pairs(CustomGunSoundValues) do
        if tool and tool.Parent then
            for name,soundId in pairs(data.Sounds) do
                local handle=tool:FindFirstChild('Handle')
                local sound=handle and handle:FindFirstChild(name..'Sound')

                if sound and sound:IsA('Sound') then
                    sound.SoundId=soundId
                end
            end

            for name,value in pairs(data.Attributes) do
                tool:SetAttribute(name,value)
            end
        end
    end

    table.clear(CustomGunSoundValues)
end

local DoorCollision=false
local DoorParts={}
local DoorScanInterval=0.5
local DoorScanTimer=0

local BlatantToolValues={}
local PlayerToolsCache=nil

local AntiAimEnabled=false
local AntiAimRotationTime=0.18
local AntiAimRandomization=360
local AntiAimPreviewTransparency=0.5
local AntiAimRotation=0
local AntiAimNextRotation=0
local AntiAimNextChange=0
local AntiAimCharacter=nil
local AntiAimOriginalAutoRotate=nil
local AntiAimPreview=nil
local AntiAimShowPreview=false
local AntiAimRandom=Random.new()
local AntiAimOverlapParams=OverlapParams.new()
local AntiAimCollisionTimer=0
local AntiAimCollisionBlocked=false
AntiAimOverlapParams.FilterType=Enum.RaycastFilterType.Include
AntiAimOverlapParams.FilterDescendantsInstances={Workspace}

local function GetAntiAimRotation()
    return math.rad(AntiAimRandom:NextInteger(0,math.floor(AntiAimRandomization)))
end

local function DestroyAntiAimPreview()
    if AntiAimPreview then
        AntiAimPreview:Destroy()
        AntiAimPreview=nil
    end
end

local function SetupAntiAimCharacter(character)
    AntiAimCharacter=character
    AntiAimCollisionTimer=0
    AntiAimCollisionBlocked=false
    AntiAimRotation=GetAntiAimRotation()
    AntiAimNextRotation=GetAntiAimRotation()
    AntiAimNextChange=os.clock()+AntiAimRotationTime

    local humanoid=character:FindFirstChildOfClass('Humanoid')

    if humanoid then
        AntiAimOriginalAutoRotate=humanoid.AutoRotate
        humanoid.AutoRotate=false
    end
end

local function CreateAntiAimPreview(character)
    DestroyAntiAimPreview()

    local archivable=character.Archivable
    character.Archivable=true

    local success,preview=pcall(function()
        return character:Clone()
    end)

    character.Archivable=archivable

    if not success or not preview then
        return
    end

    for _,object in ipairs(preview:GetDescendants()) do
        if object:IsA('Script') or object:IsA('LocalScript')
            or object:IsA('ModuleScript') or object:IsA('Humanoid') then
            object:Destroy()
        elseif object:IsA('BasePart') then
            object.Anchored=true
            object.CanCollide=false
            object.CanTouch=false
            object.CanQuery=false
            object.Transparency=0.5
            object.Color=Color3.fromRGB(150,150,150)
        elseif object:IsA('Decal') or object:IsA('Texture') then
            object.Transparency=0.5
        end
    end

    preview.Name='LeetwareAntiAimPreview'
    preview.Parent=Workspace
    AntiAimPreview=preview
end

local function UpdateAntiAimPreview(character,rotation)
    if not AntiAimPreview or not AntiAimPreview.Parent then
        CreateAntiAimPreview(character)
    end

    if not AntiAimPreview then
        return
    end

    local root=character:FindFirstChild('HumanoidRootPart')
    local previewRoot=AntiAimPreview:FindFirstChild('HumanoidRootPart')

    if root and previewRoot then
        local target=CFrame.new(root.Position)*CFrame.Angles(0,rotation,0)
        local delta=target*previewRoot.CFrame:Inverse()

        AntiAimPreview:PivotTo(delta*AntiAimPreview:GetPivot())
    end

    local color=Color3.fromRGB(150,150,150)

    for _,object in ipairs(AntiAimPreview:GetDescendants()) do
        if object:IsA('BasePart') then
            object.Color=color
            object.Transparency=AntiAimPreviewTransparency
        elseif object:IsA('Decal') or object:IsA('Texture') then
            object.Transparency=AntiAimPreviewTransparency
        end
    end
end

local function IsAntiAimBlocked(character,root,humanoid)
    if humanoid.Sit or humanoid:GetState()==Enum.HumanoidStateType.Seated then
        return true
    end

    if AntiAimCollisionTimer>0 then
        return AntiAimCollisionBlocked
    end

    AntiAimCollisionTimer=0.15
    AntiAimCollisionBlocked=false

    for _,part in ipairs(Workspace:GetPartBoundsInRadius(
        root.Position,
        1,
        AntiAimOverlapParams
    )) do
        if part:IsA('TrussPart') then
            AntiAimCollisionBlocked=true
            return true
        end
    end

    return false
end

local function RestoreAntiAimCharacter()
    if AntiAimCharacter and AntiAimCharacter.Parent then
        local humanoid=AntiAimCharacter:FindFirstChildOfClass('Humanoid')

        if humanoid then
            humanoid.AutoRotate=AntiAimOriginalAutoRotate
        end
    end

    AntiAimCharacter=nil
    AntiAimOriginalAutoRotate=nil
    AntiAimCollisionTimer=0
    AntiAimCollisionBlocked=false
end

local function SetAntiAimEnabled(enabled)
    AntiAimEnabled=enabled

    if not enabled then
        RestoreAntiAimCharacter()
        DestroyAntiAimPreview()
    elseif Player.Character then
        SetupAntiAimCharacter(Player.Character)
    end
end

local function ApplyAntiAim(deltaTime)
    if not AntiAimEnabled then
        return
    end

    local character=Player.Character

    if not character then
        return
    end

    if AntiAimCharacter~=character then
        SetupAntiAimCharacter(character)
    end

    local humanoid=character:FindFirstChildOfClass('Humanoid')
    local root=character:FindFirstChild('HumanoidRootPart')

    if not humanoid or not root then
        return
    end

    AntiAimCollisionTimer-=deltaTime

    if IsAntiAimBlocked(character,root,humanoid) then
        humanoid.AutoRotate=AntiAimOriginalAutoRotate

        if AntiAimShowPreview and AntiAimPreview then
            UpdateAntiAimPreview(character,AntiAimNextRotation)
        end

        return
    end

    humanoid.AutoRotate=false

    if os.clock()>=AntiAimNextChange then
        AntiAimRotation=AntiAimNextRotation
        AntiAimNextRotation=GetAntiAimRotation()
        AntiAimNextChange=os.clock()+AntiAimRotationTime
    end

    local position=root.Position
    root.CFrame=CFrame.new(position)*CFrame.Angles(0,AntiAimRotation,0)

    if AntiAimShowPreview then
        UpdateAntiAimPreview(character,AntiAimNextRotation)
    else
        DestroyAntiAimPreview()
    end
end

local function GetPlayerTools()
    if PlayerToolsCache then
        return PlayerToolsCache
    end

    local tools={}
    local backpack=Player:FindFirstChildOfClass('Backpack')
    local character=Player.Character

    if backpack then
        for _,object in ipairs(backpack:GetChildren()) do
            if object:IsA('Tool') then
                table.insert(tools,object)
            end
        end
    end

    if character then
        for _,object in ipairs(character:GetChildren()) do
            if object:IsA('Tool') then
                table.insert(tools,object)
            end
        end
    end

    PlayerToolsCache=tools
    return PlayerToolsCache
end

local function RefreshPlayerTools()
    PlayerToolsCache=nil
    return GetPlayerTools()
end

local function GetToolValue(tool,name)
    local value=tool:GetAttribute(name)
    local child=tool:FindFirstChild(name)

    if value==nil and child and child:IsA('ValueBase') then
        value=child.Value
    end

    return value
end

local function SetToolValue(tool,name,value)
    tool:SetAttribute(name,value)

    local child=tool:FindFirstChild(name)

    if child and child:IsA('ValueBase') then
        child.Value=value
    end
end

local function RememberToolValue(tool,name)
    BlatantToolValues[tool]=BlatantToolValues[tool] or {}

    if BlatantToolValues[tool][name]==nil then
        BlatantToolValues[tool][name]={
            Attribute=tool:GetAttribute(name),
            Value=GetToolValue(tool,name),
            Child=tool:FindFirstChild(name)
        }
    end
end

local function RestoreToolValue(tool,name)
    local original=BlatantToolValues[tool] and BlatantToolValues[tool][name]

    if not original or not tool.Parent then
        return
    end

    if original.Attribute==nil then
        tool:SetAttribute(name,nil)
    else
        tool:SetAttribute(name,original.Attribute)
    end

    local child=tool:FindFirstChild(name)

    if child and child:IsA('ValueBase') and original.Value~=nil then
        child.Value=original.Value
    end
end

local function ApplyBlatantToolMod(enabled,names,value)
    for _,tool in ipairs(GetPlayerTools()) do
        for _,name in ipairs(names) do
            if enabled then
                RememberToolValue(tool,name)
                SetToolValue(tool,name,value)
            else
                RestoreToolValue(tool,name)
            end
        end
    end
end

local function RestoreBlatantToolMods()
    for tool,values in pairs(BlatantToolValues) do
        if tool and tool.Parent then
            for name in pairs(values) do
                RestoreToolValue(tool,name)
            end
        end
    end

    table.clear(BlatantToolValues)
end

local function RefreshBlatantToolMods()
    for _,tool in ipairs(GetPlayerTools()) do
        if Toggles.NoSpread and Toggles.NoSpread.Value then
            RememberToolValue(tool,'SpreadRadius')
            SetToolValue(tool,'SpreadRadius',0)
        end

        if Toggles.InfiniteRange and Toggles.InfiniteRange.Value then
            RememberToolValue(tool,'Range')
            SetToolValue(tool,'Range',100000)
        end

        if Toggles.InfiniteAmmo and Toggles.InfiniteAmmo.Value then
            local maxAmmo=tonumber(GetToolValue(tool,'MaxAmmo'))

            if maxAmmo then
                RememberToolValue(tool,'CurrentAmmo')
                RememberToolValue(tool,'Local_CurrentAmmo')
                SetToolValue(tool,'CurrentAmmo',maxAmmo)
                SetToolValue(tool,'Local_CurrentAmmo',maxAmmo)
            end
        end
    end
end

local function SaveGunTransparency(object)
    if GunTransparencyObjects[object]~=nil then
        return
    end

    GunTransparencyObjects[object]=object.LocalTransparencyModifier
end

local function ProcessGunTransparencyTool(tool)
    if not tool:IsA('Tool') then
        return
    end

    for _,object in ipairs(tool:GetDescendants()) do
        if object:IsA('BasePart') then
            SaveGunTransparency(object)

            if object.LocalTransparencyModifier~=GunTransparency then
                object.LocalTransparencyModifier=GunTransparency
            end
        end
    end
end

local function ProcessGunTransparencyContainer(container)
    for _,object in ipairs(container:GetChildren()) do
        if object:IsA('Tool') then
            ProcessGunTransparencyTool(object)
        end
    end
end

local function ProcessGunTransparencyTools(tools)
    for _,tool in ipairs(tools) do
        ProcessGunTransparencyTool(tool)
    end
end

local function RestoreGunTransparency()
    for object,transparency in pairs(GunTransparencyObjects) do
        if object and object.Parent then
            object.LocalTransparencyModifier=transparency
        end
    end

    table.clear(GunTransparencyObjects)
end

local function GetDoorContainers()
    return {
        Workspace:FindFirstChild("Doors"),
        Workspace:FindFirstChild("Prison_Fences"),
        Workspace:FindFirstChild("CellDoors")
    }
end

local function SaveDoorPart(part)
    if DoorParts[part] then
        return
    end

    DoorParts[part]={
        Color=part.Color,
        Transparency=part.Transparency,
        CanCollide=part.CanCollide
    }
end

local function ProcessDoorPart(part)
    if not part:IsA("BasePart") then
        return
    end

    SaveDoorPart(part)

    if part.CanCollide then
        part.CanCollide=false
    end

    if part.Transparency~=0.5 then
        part.Transparency=0.5
    end
end

local function ScanDoors()
    if not DoorCollision then
        return
    end

    local found={}

    for _,container in ipairs(GetDoorContainers()) do
        if container then
            for _,object in ipairs(container:GetDescendants()) do
                if object:IsA("BasePart") then
                    found[object]=true

                    if not DoorParts[object] then
                        SaveDoorPart(object)
                    end

                    ProcessDoorPart(object)
                end
            end
        end
    end

    for part in pairs(DoorParts) do
        if not found[part] or not part.Parent then
            DoorParts[part]=nil
        end
    end
end

local function RestoreDoorParts()
    for part,data in pairs(DoorParts) do
        if part and part.Parent then
            part.Color=data.Color
            part.Transparency=data.Transparency
            part.CanCollide=data.CanCollide
        end
    end

    table.clear(DoorParts)
end

-- ui init

local Window=Library:CreateWindow({
    Title='leetware',
    Center=true,
    AutoShow=true
})

local Tabs={
    Main=Window:AddTab('Main'),
    Visuals=Window:AddTab('Visuals'),
    Aimbot=Window:AddTab('Aimbot'),
    ['UI Settings']=Window:AddTab('UI Settings')
}

local MainVisualsGroupBox=Tabs.Main:AddLeftGroupbox('Visuals')
local BlatantGroupBox=Tabs.Main:AddRightGroupbox('Blatant')
MainVisualsGroupBox:AddSlider('GunTransparency',{
    Text='Gun Transparency',
    Default=0,
    Min=0,
    Max=1,
    Rounding=2,
    Compact=false
})

Options.GunTransparency:OnChanged(function()
    GunTransparency=Options.GunTransparency.Value

    if GunTransparency<=0 then
        RestoreGunTransparency()
    else
        local backpack=Player:FindFirstChildOfClass('Backpack')

        if backpack then
            ProcessGunTransparencyContainer(backpack)
        end

        local character=Player.Character

        if character then
            ProcessGunTransparencyContainer(character)
        end
    end
end)

MainVisualsGroupBox:AddToggle('CustomGunSounds',{
    Text='Custom Gun Sounds',
    Default=false
})

Toggles.CustomGunSounds:OnChanged(function()
    CustomGunSounds=Toggles.CustomGunSounds.Value

    if CustomGunSounds then
        if not LoadCustomGunSounds() then
            CustomGunSounds=false
            Toggles.CustomGunSounds:SetValue(false)
            return
        end

        for _,tool in ipairs(GetPlayerTools()) do
            UpdateCustomGunSound(tool)
        end
    else
        RestoreCustomGunSounds()
    end
end)

local AntiAimGroupBox=Tabs.Main:AddLeftGroupbox('Anti Aim')

AntiAimGroupBox:AddToggle('AntiAimEnabled',{
    Text='Enabled',
    Default=false
})

Toggles.AntiAimEnabled:OnChanged(function()
    SetAntiAimEnabled(Toggles.AntiAimEnabled.Value)
end)

AntiAimGroupBox:AddSlider('AntiAimRotationTime',{
    Text='Rotation Time',
    Default=0.18,
    Min=0.1,
    Max=1,
    Rounding=2,
    Compact=false
})

Options.AntiAimRotationTime:OnChanged(function()
    AntiAimRotationTime=Options.AntiAimRotationTime.Value
end)

AntiAimGroupBox:AddSlider('AntiAimRandomization',{
    Text='Randomization',
    Default=360,
    Min=0,
    Max=360,
    Rounding=0,
    Compact=false
})

Options.AntiAimRandomization:OnChanged(function()
    AntiAimRandomization=Options.AntiAimRandomization.Value
end)

AntiAimGroupBox:AddSlider('AntiAimPreviewTransparency',{
    Text='Preview Transparency',
    Default=0.5,
    Min=0,
    Max=1,
    Rounding=2,
    Compact=false
})

Options.AntiAimPreviewTransparency:OnChanged(function()
    AntiAimPreviewTransparency=Options.AntiAimPreviewTransparency.Value
end)

AntiAimGroupBox:AddToggle('AntiAimShowPreview',{
    Text='Show Next Rotation',
    Default=false
})

Toggles.AntiAimShowPreview:OnChanged(function()
    AntiAimShowPreview=Toggles.AntiAimShowPreview.Value

    if AntiAimShowPreview and AntiAimEnabled and Player.Character then
        UpdateAntiAimPreview(Player.Character,AntiAimNextRotation)
    elseif not AntiAimShowPreview then
        DestroyAntiAimPreview()
    end
end)

BlatantGroupBox:AddToggle('DoorCollision',{
    Text='Door Collision',
    Default=false
})

Toggles.DoorCollision:OnChanged(function()
    DoorCollision=Toggles.DoorCollision.Value
    DoorScanTimer=0

    if DoorCollision then
        ScanDoors()
    else
        RestoreDoorParts()
    end
end)

BlatantGroupBox:AddToggle('NoSpread',{
    Text='No Spread',
    Default=false
})

Toggles.NoSpread:OnChanged(function()
    ApplyBlatantToolMod(Toggles.NoSpread.Value,{'SpreadRadius'},0)
end)

BlatantGroupBox:AddToggle('InfiniteRange',{
    Text='Infinite Range',
    Default=false
})

Toggles.InfiniteRange:OnChanged(function()
    ApplyBlatantToolMod(Toggles.InfiniteRange.Value,{'Range'},100000)
end)

BlatantGroupBox:AddToggle('InfiniteAmmo',{
    Text='Infinite Ammo',
    Default=false
})

Toggles.InfiniteAmmo:OnChanged(function()
    if Toggles.InfiniteAmmo.Value then
        RefreshBlatantToolMods()
    else
        ApplyBlatantToolMod(false,{'CurrentAmmo','Local_CurrentAmmo'})
    end
end)

local BoxGroupBox=Tabs.Visuals:AddLeftGroupbox('Box')

BoxGroupBox:AddToggle('ESPEnabled',{
    Text='Enabled',
    Default=ESPSettings.Box.Enabled
})

Toggles.ESPEnabled:OnChanged(function()
    ESPSettings.Box.Enabled=Toggles.ESPEnabled.Value
end)

BoxGroupBox:AddDropdown('ESPBoxStyle',{
    Values={
        'Corner',
        'Normal'
    },
    Default=1,
    Multi=false,
    Text='Box Style'
})

Options.ESPBoxStyle:OnChanged(function()
    ESPSettings.Box.Style=Options.ESPBoxStyle.Value
end)

BoxGroupBox:AddLabel('Box Color'):AddColorPicker('ESPBoxColor',{
    Default=ESPSettings.Box.Color,
    Title='Box Color'
})

Options.ESPBoxColor:OnChanged(function()
    ESPSettings.Box.Color=Options.ESPBoxColor.Value
end)

BoxGroupBox:AddToggle('ESPTeamCheck',{
    Text='Team Check',
    Default=ESPSettings.Box.TeamCheck
})

Toggles.ESPTeamCheck:OnChanged(function()
    ESPSettings.Box.TeamCheck=Toggles.ESPTeamCheck.Value
end)

BoxGroupBox:AddToggle('ESPFriendCheck',{
    Text='Friend Check',
    Default=ESPSettings.FriendCheck
})

Toggles.ESPFriendCheck:OnChanged(function()
    ESPSettings.FriendCheck=Toggles.ESPFriendCheck.Value
end)

BoxGroupBox:AddToggle('ESPAutothickness',{
    Text='Auto Thickness',
    Default=ESPSettings.Box.AutoThickness
})

Toggles.ESPAutothickness:OnChanged(function()
    ESPSettings.Box.AutoThickness=Toggles.ESPAutothickness.Value
end)

BoxGroupBox:AddSlider('ESPThickness',{
    Text='Box Thickness',
    Default=ESPSettings.Box.Thickness,
    Min=1,
    Max=6,
    Rounding=1,
    Compact=false
})

Options.ESPThickness:OnChanged(function()
    ESPSettings.Box.Thickness=Options.ESPThickness.Value
end)

local FillGroupBox=Tabs.Visuals:AddRightGroupbox('Fill')

local FillToggle=FillGroupBox:AddToggle('ESPFillBox',{
    Text='Fill Box',
    Default=ESPSettings.Fill.Enabled
})

FillToggle:AddColorPicker('ESPFillBoxColor',{
    Default=ESPSettings.Fill.Color,
    Title='Fill Color'
})

Toggles.ESPFillBox:OnChanged(function()
    ESPSettings.Fill.Enabled=Toggles.ESPFillBox.Value
end)

Options.ESPFillBoxColor:OnChanged(function()
    ESPSettings.Fill.Color=Options.ESPFillBoxColor.Value
end)

FillGroupBox:AddSlider('ESPFillOpacity',{
    Text='Fill Opacity',
    Default=math.floor((1-ESPSettings.Fill.Opacity)*100),
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.ESPFillOpacity:OnChanged(function()
    ESPSettings.Fill.Opacity=1-(Options.ESPFillOpacity.Value/100)
end)

local ChamsGroupBox=Tabs.Visuals:AddRightGroupbox('Chams')
local TeamColorGroupBox=Tabs.Visuals:AddRightGroupbox('Team Color')

TeamColorGroupBox:AddDropdown('ESPTeamColor',{
    Values={
        'Box Border',
        'Box Fill',
        'Text',
        'Health Border',
        'Health Fill'
    },
    Default={
        ['Box Border']=ESPSettings.TeamColor.BoxBorder,
        ['Box Fill']=ESPSettings.TeamColor.BoxFill,
        Text=ESPSettings.TeamColor.Text,
        ['Health Border']=ESPSettings.TeamColor.HealthBorder,
        ['Health Fill']=ESPSettings.TeamColor.HealthFill
    },
    Multi=true,
    Text='Apply Team Color'
})

Options.ESPTeamColor:OnChanged(function()
    local values=Options.ESPTeamColor.Value

    ESPSettings.TeamColor.BoxBorder=values['Box Border']==true
    ESPSettings.TeamColor.BoxFill=values['Box Fill']==true
    ESPSettings.TeamColor.Text=values.Text==true
    ESPSettings.TeamColor.HealthBorder=values['Health Border']==true
    ESPSettings.TeamColor.HealthFill=values['Health Fill']==true
end)

TeamColorGroupBox:AddToggle('ESPDarkenBorders',{
    Text='Darken Borders',
    Default=ESPSettings.TeamColor.DarkenBorders
})

Toggles.ESPDarkenBorders:OnChanged(function()
    ESPSettings.TeamColor.DarkenBorders=Toggles.ESPDarkenBorders.Value
end)

TeamColorGroupBox:AddSlider('ESPDarkenAmount',{
    Text='Darken Amount',
    Default=ESPSettings.TeamColor.DarkenAmount,
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.ESPDarkenAmount:OnChanged(function()
    ESPSettings.TeamColor.DarkenAmount=Options.ESPDarkenAmount.Value
end)

local ChamsToggle=ChamsGroupBox:AddToggle('ESPChams',{
    Text='Enabled',
    Default=ESPSettings.Chams.Enabled
})

ChamsToggle:AddColorPicker('ESPChamsColor',{
    Default=ESPSettings.Chams.Color,
    Title='Chams Color',
    Callback=function(value)
        ESPSettings.Chams.Color=value
    end
})

ChamsToggle:OnChanged(function()
    ESPSettings.Chams.Enabled=ChamsToggle.Value
end)

ChamsGroupBox:AddSlider('ESPChamsTransparency',{
    Text='Transparency',
    Default=math.floor(ESPSettings.Chams.Transparency*100),
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.ESPChamsTransparency:OnChanged(function()
    ESPSettings.Chams.Transparency=Options.ESPChamsTransparency.Value/100
end)

local ChamsOutlineToggle=ChamsGroupBox:AddToggle('ESPChamsOutline',{
    Text='Outline',
    Default=ESPSettings.Chams.Outline
})

ChamsOutlineToggle:AddColorPicker('ESPChamsOutlineColor',{
    Default=ESPSettings.Chams.OutlineColor,
    Title='Outline Color',
    Callback=function(value)
        ESPSettings.Chams.OutlineColor=value
    end
})

Toggles.ESPChamsOutline:OnChanged(function()
    ESPSettings.Chams.Outline=Toggles.ESPChamsOutline.Value

    if Toggles.ESPChamsOutline.Value then
        ESPSettings.Chams.OutlineTransparency=0
    else
        ESPSettings.Chams.OutlineTransparency=1
    end
end)

ChamsGroupBox:AddSlider('ESPChamsOutlineTransparency',{
    Text='Outline Transparency',
    Default=math.floor(ESPSettings.Chams.OutlineTransparency*100),
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.ESPChamsOutlineTransparency:OnChanged(function()
    ESPSettings.Chams.OutlineTransparency=Options.ESPChamsOutlineTransparency.Value/100

    if Options.ESPChamsOutlineTransparency.Value>=100 then
        ESPSettings.Chams.Outline=false
    end
end)

ChamsGroupBox:AddToggle('ESPChamsAlwaysOnTop',{
    Text='Always On Top',
    Default=ESPSettings.Chams.AlwaysOnTop
})

Toggles.ESPChamsAlwaysOnTop:OnChanged(function()
    ESPSettings.Chams.AlwaysOnTop=Toggles.ESPChamsAlwaysOnTop.Value
end)

local TracerGroupBox=Tabs.Visuals:AddLeftGroupbox('Tracers')

local TracerToggle=TracerGroupBox:AddToggle('ESPTracers',{
    Text='Enabled',
    Default=ESPSettings.Tracers.Enabled
})

TracerToggle:AddColorPicker('ESPTracerColor',{
    Default=ESPSettings.Tracers.Color,
    Title='Tracer Color',
    Callback=function(value)
        ESPSettings.Tracers.Color=value
    end
})

TracerToggle:OnChanged(function()
    ESPSettings.Tracers.Enabled=TracerToggle.Value
end)

TracerGroupBox:AddToggle('ESPTracersShowNotInView',{
    Text='Show Not In View',
    Default=ESPSettings.Tracers.ShowNotInView
})

Toggles.ESPTracersShowNotInView:OnChanged(function()
    ESPSettings.Tracers.ShowNotInView=
        Toggles.ESPTracersShowNotInView.Value
end)

TracerGroupBox:AddSlider('ESPTracerThickness',{
    Text='Thickness',
    Default=ESPSettings.Tracers.Thickness,
    Min=1,
    Max=5,
    Rounding=0,
    Compact=false
})

Options.ESPTracerThickness:OnChanged(function()
    ESPSettings.Tracers.Thickness=Options.ESPTracerThickness.Value
end)

TracerGroupBox:AddSlider('ESPTracerTransparency',{
    Text='Transparency',
    Default=math.floor(ESPSettings.Tracers.Transparency*100),
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.ESPTracerTransparency:OnChanged(function()
    ESPSettings.Tracers.Transparency=Options.ESPTracerTransparency.Value/100
end)

TracerGroupBox:AddDropdown('ESPTracerOrigin',{
    Values={
        'Bottom',
        'Center',
        'Top'
    },
    Default=1,
    Multi=false,
    Text='Origin'
})

Options.ESPTracerOrigin:OnChanged(function()
    ESPSettings.Tracers.Origin=Options.ESPTracerOrigin.Value
end)

local AimbotGroupBox=Tabs.Aimbot:AddLeftGroupbox('Aimbot')

local AimbotToggle=AimbotGroupBox:AddToggle('AimbotEnabled',{
    Text='Enabled',
    Default=ESPSettings.Aimbot.Enabled
})

AimbotToggle:OnChanged(function()
    ESPSettings.Aimbot.Enabled=AimbotToggle.Value
end)

local GetTeamDropdownValues=function()
    return Utils.GetTeamNames(Players)
end

AimbotGroupBox:AddDropdown('AimbotExcludeTeams',{
    Values=GetTeamDropdownValues(),
    Default={},
    Multi=true,
    Text='Exclude Teams'
})

Options.AimbotExcludeTeams:OnChanged(function()
    ESPSettings.Aimbot.ExcludeTeams=Options.AimbotExcludeTeams.Value
end)

AimbotGroupBox:AddDropdown('AimbotPrioritizeTeams',{
    Values=GetTeamDropdownValues(),
    Default={},
    Multi=true,
    Text='Prioritize Teams'
})

Options.AimbotPrioritizeTeams:OnChanged(function()
    ESPSettings.Aimbot.PrioritizeTeams=Options.AimbotPrioritizeTeams.Value
end)

AimbotGroupBox:AddLabel('Aim Bind'):AddKeyPicker('AimbotBind',{
    Default=ESPSettings.Aimbot.Bind,
    NoUI=false,
    Text='Aim bind',
    Mode='Hold',
    ChangedCallback=function(value)
        ESPSettings.Aimbot.Bind=value
    end
})

AimbotGroupBox:AddDropdown('AimbotTargeting',{
    Values={
        'Normal',
        'Closest',
        'Furthest',
        'Random'
    },
    Default=1,
    Multi=false,
    Text='Targeting'
})

Options.AimbotTargeting:OnChanged(function()
    ESPSettings.Aimbot.Targeting=Options.AimbotTargeting.Value
end)

AimbotGroupBox:AddToggle('AimbotLockAim',{
    Text='Lock Aim',
    Default=ESPSettings.Aimbot.LockAim
})

Toggles.AimbotLockAim:OnChanged(function()
    ESPSettings.Aimbot.LockAim=Toggles.AimbotLockAim.Value
end)

AimbotGroupBox:AddToggle('AimbotWallCheck',{
    Text='Wall Check',
    Default=ESPSettings.Aimbot.WallCheck
})

Toggles.AimbotWallCheck:OnChanged(function()
    ESPSettings.Aimbot.WallCheck=Toggles.AimbotWallCheck.Value
end)

AimbotGroupBox:AddToggle('AimbotTeamCheck',{
    Text='Team Check',
    Default=ESPSettings.Aimbot.TeamCheck
})

Toggles.AimbotTeamCheck:OnChanged(function()
    ESPSettings.Aimbot.TeamCheck=Toggles.AimbotTeamCheck.Value
end)

AimbotGroupBox:AddToggle('AimbotFriendCheck',{
    Text='Friend Check',
    Default=ESPSettings.Aimbot.FriendCheck
})

Toggles.AimbotFriendCheck:OnChanged(function()
    ESPSettings.Aimbot.FriendCheck=Toggles.AimbotFriendCheck.Value
end)

AimbotGroupBox:AddToggle('AimbotHealthCheck',{
    Text='Health Check',
    Default=ESPSettings.Aimbot.HealthCheck
})

Toggles.AimbotHealthCheck:OnChanged(function()
    ESPSettings.Aimbot.HealthCheck=Toggles.AimbotHealthCheck.Value
end)

AimbotGroupBox:AddSlider('AimbotMinHealth',{
    Text='Minimum Health',
    Default=ESPSettings.Aimbot.MinHealth,
    Min=0,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.AimbotMinHealth:OnChanged(function()
    ESPSettings.Aimbot.MinHealth=Options.AimbotMinHealth.Value
end)

local TriggerbotGroupBox=Tabs.Aimbot:AddLeftGroupbox('Triggerbot')

TriggerbotGroupBox:AddToggle('AimbotTriggerbot',{
    Text='Triggerbot',
    Default=ESPSettings.Aimbot.Triggerbot
})

Toggles.AimbotTriggerbot:OnChanged(function()
    ESPSettings.Aimbot.Triggerbot=Toggles.AimbotTriggerbot.Value
end)

TriggerbotGroupBox:AddSlider('AimbotTriggerbotDelay',{
    Text='Triggerbot Delay',
    Default=ESPSettings.Aimbot.TriggerbotDelay,
    Min=0,
    Max=0.3,
    Rounding=3,
    Compact=false
})

Options.AimbotTriggerbotDelay:OnChanged(function()
    ESPSettings.Aimbot.TriggerbotDelay=Options.AimbotTriggerbotDelay.Value
end)

local AimbotSettingsGroupBox=Tabs.Aimbot:AddRightGroupbox('Settings')

AimbotSettingsGroupBox:AddSlider('AimbotFov',{
    Text='Aim FOV',
    Default=ESPSettings.Aimbot.Fov,
    Min=0,
    Max=1000,
    Rounding=0,
    Compact=false
})

Options.AimbotFov:OnChanged(function()
    ESPSettings.Aimbot.Fov=Options.AimbotFov.Value
end)

AimbotSettingsGroupBox:AddSlider('AimbotRange',{
    Text='Range (Studs)',
    Default=ESPSettings.Aimbot.Range,
    Min=1,
    Max=1500,
    Rounding=0,
    Compact=false
})

Options.AimbotRange:OnChanged(function()
    ESPSettings.Aimbot.Range=Options.AimbotRange.Value
end)

AimbotSettingsGroupBox:AddSlider('AimbotSmoothing',{
    Text='Smoothing',
    Default=ESPSettings.Aimbot.Smoothing,
    Min=1,
    Max=100,
    Rounding=0,
    Compact=false
})

Options.AimbotSmoothing:OnChanged(function()
    ESPSettings.Aimbot.Smoothing=Options.AimbotSmoothing.Value
end)

AimbotSettingsGroupBox:AddSlider('AimbotPrediction',{
    Text='Prediction Strength',
    Default=ESPSettings.Aimbot.Prediction,
    Min=0,
    Max=0.2,
    Rounding=3,
    Compact=false
})

Options.AimbotPrediction:OnChanged(function()
    ESPSettings.Aimbot.Prediction=Options.AimbotPrediction.Value
end)

AimbotSettingsGroupBox:AddLabel('FOV Color'):AddColorPicker('AimbotFovColor',{
    Default=ESPSettings.Aimbot.FovColor,
    Title='FOV Color'
})

Options.AimbotFovColor:OnChanged(function()
    ESPSettings.Aimbot.FovColor=Options.AimbotFovColor.Value
end)

AimbotSettingsGroupBox:AddLabel('Targeted FOV Color'):AddColorPicker('AimbotTargetedFovColor',{
    Default=ESPSettings.Aimbot.TargetedFovColor,
    Title='Targeted FOV Color'
})

Options.AimbotTargetedFovColor:OnChanged(function()
    ESPSettings.Aimbot.TargetedFovColor=Options.AimbotTargetedFovColor.Value
end)

local InfoGroupBox=Tabs.Visuals:AddLeftGroupbox('Information')

local ShowNameToggle=InfoGroupBox:AddToggle('ESPShowName',{
    Text='Show Name',
    Default=ESPSettings.Information.ShowName
})

ShowNameToggle:AddColorPicker('ESPNameColor',{
    Default=ESPSettings.Information.NameColor,
    Title='Name Color'
})

Toggles.ESPShowName:OnChanged(function()
    ESPSettings.Information.ShowName=Toggles.ESPShowName.Value
end)

InfoGroupBox:AddToggle('ESPShowDisplayName',{
    Text='Show Display Name',
    Default=ESPSettings.Information.ShowDisplayName
})

Toggles.ESPShowDisplayName:OnChanged(function()
    ESPSettings.Information.ShowDisplayName=Toggles.ESPShowDisplayName.Value
end)

local WeaponToggle=InfoGroupBox:AddToggle('ESPShowWeapon',{
    Text='Show Weapon',
    Default=ESPSettings.Information.ShowWeapon
})

WeaponToggle:AddColorPicker('ESPWeaponColor',{
    Default=ESPSettings.Information.WeaponColor,
    Title='Weapon Color'
})

Toggles.ESPShowWeapon:OnChanged(function()
    ESPSettings.Information.ShowWeapon=Toggles.ESPShowWeapon.Value
end)

Options.ESPWeaponColor:OnChanged(function()
    ESPSettings.Information.WeaponColor=Options.ESPWeaponColor.Value
end)

Options.ESPNameColor:OnChanged(function()
    ESPSettings.Information.NameColor=Options.ESPNameColor.Value
end)

local ShowTeamToggle=InfoGroupBox:AddToggle('ESPShowTeam',{
    Text='Show Team',
    Default=ESPSettings.Information.ShowTeam
})

ShowTeamToggle:AddColorPicker('ESPTeamTextColor',{
    Default=ESPSettings.Information.TeamTextColor,
    Title='Team Color'
})

Toggles.ESPShowTeam:OnChanged(function()
    ESPSettings.Information.ShowTeam=Toggles.ESPShowTeam.Value
end)

Options.ESPTeamTextColor:OnChanged(function()
    ESPSettings.Information.TeamTextColor=Options.ESPTeamTextColor.Value
end)

InfoGroupBox:AddToggle('ESPCustomTextColor',{
    Text='Custom Text Colors',
    Default=ESPSettings.Information.CustomTextColor
})

Toggles.ESPCustomTextColor:OnChanged(function()
    ESPSettings.Information.CustomTextColor=Toggles.ESPCustomTextColor.Value
end)

InfoGroupBox:AddSlider('ESPNameScale',{
    Text='Name Scale',
    Default=ESPSettings.Information.NameScale,
    Min=10,
    Max=24,
    Rounding=0,
    Compact=false
})

Options.ESPNameScale:OnChanged(function()
    ESPSettings.Information.NameScale=Options.ESPNameScale.Value
end)

InfoGroupBox:AddDropdown('ESPFont',{
    Values={
        'UI',
        'System',
        'Plex',
        'Monospace'
    },
    Default=1,
    Multi=false,
    Text='Font'
})

Options.ESPFont:OnChanged(function()
    ESPSettings.Information.Font=Options.ESPFont.Value
end)

local ShowHealthToggle=InfoGroupBox:AddToggle('ESPShowHealth',{
    Text='Show Health',
    Default=ESPSettings.Health.Enabled
})

ShowHealthToggle:AddColorPicker('ESPHealthBorderColor',{
    Default=ESPSettings.Health.BorderColor,
    Title='Health Border Color'
})

ShowHealthToggle:AddColorPicker('ESPHealthFillColor',{
    Default=ESPSettings.Health.FillColor,
    Title='Health Fill Color'
})

Toggles.ESPShowHealth:OnChanged(function()
    ESPSettings.Health.Enabled=Toggles.ESPShowHealth.Value
end)

Options.ESPHealthBorderColor:OnChanged(function()
    ESPSettings.Health.BorderColor=Options.ESPHealthBorderColor.Value
end)

Options.ESPHealthFillColor:OnChanged(function()
    ESPSettings.Health.FillColor=Options.ESPHealthFillColor.Value
end)

local MenuGroup=Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload',function()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind',{
    Default='End',
    NoUI=true,
    Text='Menu keybind'
})

Library.ToggleKeybind=Options.MenuKeybind

MenuGroup:AddToggle('Watermark',{
    Text='Watermark',
    Default=true
})

Toggles.Watermark:OnChanged(function()
    Library:SetWatermarkVisibility(Toggles.Watermark.Value)
end)

MenuGroup:AddLabel('Config Bind'):AddKeyPicker('ConfigBind',{
    Default='F5',
    NoUI=false,
    Text='Config bind',
    Mode='Toggle'
})

local ConfigGroup=Tabs['UI Settings']:AddRightGroupbox('Configs')

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({
    'MenuKeybind'
})

ThemeManager:SetFolder('leetware')
SaveManager:SetFolder('leetware/configs/'..GameId)

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library:SetWatermarkVisibility(true)

local fps=0
local frames=0
local last=os.clock()
local ToolRefreshTimer=0
local PlayerToolsTimer=0
local GunTransparencyTimer=0
local CustomSoundTimer=0

Library:SetWatermark("leetware | loading")

local FrameContext={
    Camera=nil,
    Players=Players:GetPlayers(),
    Tools=nil
}

local PlayerAddedConnection=Players.PlayerAdded:Connect(function()
    FrameContext.Players=Players:GetPlayers()
end)

local PlayerRemovingConnection=Players.PlayerRemoving:Connect(function()
    FrameContext.Players=Players:GetPlayers()
end)

local function UpdateController(controller,deltaTime)
    if controller and type(controller.Update)=='function' then
        controller:Update(deltaTime,FrameContext)
    end
end

RunService.RenderStepped:Connect(function(deltaTime)
    FrameContext.Camera=Workspace.CurrentCamera

    PlayerToolsTimer+=deltaTime

    if not FrameContext.Tools or PlayerToolsTimer>=0.25 then
        PlayerToolsTimer=0
        FrameContext.Tools=RefreshPlayerTools()
    end

    frames+=1

    local now=os.clock()

    if now-last>=0.25 then
        fps=math.round(frames/(now-last))
        frames=0
        last=now

        local ping=math.round(Stats.PerformanceStats.Ping:GetValue())

        Library:SetWatermark(
            string.format(
                "leetware | %d FPS | %d ms",
                fps,
                ping
            )
        )
    end

    UpdateController(AimbotController,deltaTime)
    UpdateController(ESPController,deltaTime)
    UpdateController(ChamsController,deltaTime)
    UpdateController(TracersController,deltaTime)

    ApplyAntiAim(deltaTime)

    local blatantToolsEnabled=(Toggles.NoSpread and Toggles.NoSpread.Value)
        or (Toggles.InfiniteRange and Toggles.InfiniteRange.Value)
        or (Toggles.InfiniteAmmo and Toggles.InfiniteAmmo.Value)

    if blatantToolsEnabled then
        ToolRefreshTimer+=deltaTime

        if ToolRefreshTimer>=0.25 then
            ToolRefreshTimer=0
            RefreshBlatantToolMods()
        end
    else
        ToolRefreshTimer=0
    end

    if GunTransparency>0 then
        GunTransparencyTimer+=deltaTime

        if GunTransparencyTimer>=0.25 then
            GunTransparencyTimer=0

            ProcessGunTransparencyTools(FrameContext.Tools)
        end
    else
        GunTransparencyTimer=0
    end

    if CustomGunSounds then
        CustomSoundTimer+=deltaTime

        if CustomSoundTimer>=0.25 then
            CustomSoundTimer=0

            for _,tool in ipairs(FrameContext.Tools) do
                UpdateCustomGunSound(tool)
            end
        end
    else
        CustomSoundTimer=0
    end

    if DoorCollision then
        DoorScanTimer+=deltaTime

        if DoorScanTimer>=DoorScanInterval then
            DoorScanTimer=0
            ScanDoors()
        end

        local doorColor=Color3.fromRGB(150,150,150)

        for part in pairs(DoorParts) do
            if part and part.Parent then
                if part.Color~=doorColor then
                    part.Color=doorColor
                end

                if part.Transparency~=0.5 then
                    part.Transparency=0.5
                end

                if part.CanCollide then
                    part.CanCollide=false
                end
            end
        end
    else
        DoorScanTimer=0
    end
end)

Library:OnUnload(function()
    DoorCollision=false
    AntiAimEnabled=false

    RestoreGunTransparency()
    RestoreDoorParts()
    RestoreCustomGunSounds()
    RestoreBlatantToolMods()
    RestoreAntiAimCharacter()
    DestroyAntiAimPreview()

    if ESPController then
        ESPController:Destroy()
        ESPController=nil
    end

    if ChamsController then
        ChamsController:Destroy()
        ChamsController=nil
    end

    if TracersController then
        TracersController:Destroy()
        TracersController=nil
    end

    if AimbotController then
        AimbotController:Destroy()
        AimbotController=nil
    end

    if PlayerAddedConnection then
        PlayerAddedConnection:Disconnect()
        PlayerAddedConnection=nil
    end

    if PlayerRemovingConnection then
        PlayerRemovingConnection:Disconnect()
        PlayerRemovingConnection=nil
    end

    Library.Unloaded=true
end)

SaveManager:LoadAutoloadConfig()