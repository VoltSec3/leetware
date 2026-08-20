local Aimbot = {}

function Aimbot.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local UserInputService = config.UserInputService
    local Settings = config.Settings
    local TriggerSettings = config.Triggerbot
    local AimbotSettings = config.AimbotSettings

    local Camera = Workspace.CurrentCamera
    local Mouse = Player:GetMouse()
    local CurrentTarget = nil
    local Aiming = false
    local Hue = 0
    local TriggerHue = 0
    local TriggerActive = false
    local TriggerHeld = false
    local TriggerTarget = nil
    local LastClick = 0

    local FovCircle = Drawing.new("Circle")
    FovCircle.Thickness = 2
    FovCircle.Filled = false
    FovCircle.Visible = false

    local TriggerCircle = Drawing.new("Circle")
    TriggerCircle.Thickness = 2
    TriggerCircle.Filled = false
    TriggerCircle.Visible = false

    local function GetTargetPart(character, partName)
        if partName == "Torso" then
            return character:FindFirstChild("UpperTorso")
                or character:FindFirstChild("Torso")
                or character:FindFirstChild("HumanoidRootPart")
        end

        local aliases = {
            ["Left Arm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm"},
            ["Right Arm"] = {"Right Arm", "RightUpperArm", "RightLowerArm"},
            ["Left Leg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg"},
            ["Right Leg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg"}
        }

        if aliases[partName] then
            for _, alias in ipairs(aliases[partName]) do
                local part = character:FindFirstChild(alias)

                if part then
                    return part
                end
            end

            return nil
        end

        return character:FindFirstChild(partName)
    end

    local function IsTeamBlocked(target)
        return Settings.TeamCheck
            and target.Team
            and Player.Team
            and target.Team == Player.Team
    end

    local function HasValidHealth(target, ignoreMinimum)
        local character = target.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        if not humanoid or humanoid.Health <= 0 then
            return false
        end

        return ignoreMinimum
            or not Settings.HealthCheck
            or humanoid.Health >= Settings.MinHealth
    end

    local function IsFriendBlocked(target)
        if not Settings.FriendCheck then
            return false
        end

        local success, isFriend = pcall(function()
            return Player:IsFriendsWith(target.UserId)
        end)

        return success and isFriend
    end

    local function IsTriggerTargetValid(target, partName)
        if not target or target == Player then
            return false
        end

        if IsTeamBlocked(target) or IsFriendBlocked(target) then
            return false
        end

        if not HasValidHealth(target, false) then
            return false
        end

        local character = target.Character
        local part = character and GetTargetPart(character, partName)

        if not part then
            return false
        end

        local screenPosition, visible = Camera:WorldToViewportPoint(
            part.Position
        )

        if screenPosition.Z <= 0 or not visible then
            return false
        end

        local mousePosition = UserInputService:GetMouseLocation()
        local partPosition = Vector2.new(
            screenPosition.X,
            screenPosition.Y
        )
        local fov = TriggerSettings.Fov

        if TriggerSettings.InheritAimbot and AimbotSettings then
            fov = AimbotSettings.Fov
        end

        if (partPosition - mousePosition).Magnitude > fov then
            return false
        end

        if TriggerSettings.WallCheck and IsBlocked(character) then
            return false
        end

        return true, part
    end

    local function GetTriggerTarget()
        local closest = nil
        local closestDistance = math.huge
        local partName = TriggerSettings.TargetPart

        for _, target in ipairs(Players:GetPlayers()) do
            local valid, part = IsTriggerTargetValid(target, partName)

            if valid then
                local screenPosition = Camera:WorldToViewportPoint(
                    part.Position
                )
                local mousePosition = UserInputService:GetMouseLocation()
                local distance = (
                    Vector2.new(screenPosition.X, screenPosition.Y)
                    - mousePosition
                ).Magnitude

                if distance < closestDistance then
                    closest = target
                    closestDistance = distance
                end
            end
        end

        return closest
    end

    local function SetTriggerHeld(held)
        if held == TriggerHeld then
            return
        end

        TriggerHeld = held

        if held then
            pcall(function()
                mouse1press()
            end)
        else
            pcall(function()
                mouse1release()
            end)
        end
    end

    local function IsTriggerEnabled()
        if not TriggerSettings.Enabled or not TriggerActive then
            return false
        end

        return not TriggerSettings.InheritAimbot
            or not AimbotSettings
            or AimbotSettings.Enabled
    end

    local function IsBlocked(character)
        local head = character:FindFirstChild("Head")

        if not head then
            return true
        end

        local origin = Camera.CFrame.Position
        local direction = head.Position - origin
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {
            Player.Character
        }
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local result = Workspace:Raycast(
            origin,
            direction,
            raycastParams
        )

        return result ~= nil
            and not result.Instance:IsDescendantOf(character)
    end

    local function IsTargetValid(target, requireFov, maintainLock)
        if not target or target == Player then
            return false
        end

        local character = target.Character
        local head = character
            and character:FindFirstChild("Head")

        if not character or not head then
            return false
        end

        if IsTeamBlocked(target) then
            return false
        end

        if IsFriendBlocked(target) then
            return false
        end

        if not HasValidHealth(target, maintainLock) then
            return false
        end

        local screenPosition, visible = Camera:WorldToViewportPoint(
            head.Position
        )

        if not maintainLock
            and (screenPosition.Z <= 0 or not visible) then
            return false
        end

        if not maintainLock and requireFov then
            local cursorPosition = UserInputService:GetMouseLocation()
            local targetPosition = Vector2.new(
                screenPosition.X,
                screenPosition.Y
            )

            if (targetPosition - cursorPosition).Magnitude
                > Settings.Fov then
                return false
            end
        end

        if not maintainLock
            and Settings.WallCheck
            and IsBlocked(character) then
            return false
        end

        return true
    end

    local function GetTarget()
        local nearestTarget = nil
        local nearestCursorDistance = Settings.Fov
        local nearestPlayerDistance = math.huge
        local cursorPosition = UserInputService:GetMouseLocation()
        local cameraPosition = Camera.CFrame.Position

        for _, target in ipairs(Players:GetPlayers()) do
            if IsTargetValid(target, true) then
                local head = target.Character.Head
                local screenPosition = Camera:WorldToViewportPoint(
                    head.Position
                )
                local targetPosition = Vector2.new(
                    screenPosition.X,
                    screenPosition.Y
                )
                local cursorDistance = (
                    targetPosition - cursorPosition
                ).Magnitude
                local playerDistance = (
                    head.Position - cameraPosition
                ).Magnitude

                if cursorDistance < nearestCursorDistance
                    or (cursorDistance == nearestCursorDistance
                        and playerDistance < nearestPlayerDistance) then
                    nearestCursorDistance = cursorDistance
                    nearestPlayerDistance = playerDistance
                    nearestTarget = target
                end
            end
        end

        return nearestTarget
    end

    local function GetLockedTarget()
        if not Settings.LockAim then
            CurrentTarget = GetTarget()
            return CurrentTarget
        end

        if CurrentTarget
            and IsTargetValid(CurrentTarget, false, true) then
            return CurrentTarget
        end

        CurrentTarget = GetTarget()
        return CurrentTarget
    end

    local function GetAimPosition(target)
        local character = target and target.Character
        local head = character and character:FindFirstChild("Head")
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not head then
            return nil
        end

        if not root or Settings.Prediction <= 0 then
            return head.Position
        end

        return head.Position + (
            root.AssemblyLinearVelocity * Settings.Prediction
        )
    end

    local function IsInputBound(input)
        local bind = Settings.Bind

        if typeof(bind) == "EnumItem" then
            return input.KeyCode == bind
                or input.UserInputType == bind
        end

        if type(bind) ~= "string" then
            return false
        end

        if bind == "MB1" then
            return input.UserInputType == Enum.UserInputType.MouseButton1
        end

        if bind == "MB2" then
            return input.UserInputType == Enum.UserInputType.MouseButton2
        end

        return input.KeyCode.Name == bind
            or input.UserInputType.Name == bind
    end

    local function IsTriggerInputBound(input)
        local bind = TriggerSettings.Bind

        if typeof(bind) == "EnumItem" then
            return input.KeyCode == bind
                or input.UserInputType == bind
        end

        if type(bind) ~= "string" then
            return false
        end

        return input.KeyCode.Name == bind
            or input.UserInputType.Name == bind
    end

    local function UpdateCircle()
        local settings = Settings
        local mousePosition = UserInputService:GetMouseLocation()

        FovCircle.Position = mousePosition
        FovCircle.Radius = settings.Fov
        FovCircle.Visible = settings.Enabled

        if settings.RainbowFov then
            Hue = (Hue + settings.RainbowSpeed) % 1
            FovCircle.Color = Color3.fromHSV(Hue, 1, 1)
        elseif CurrentTarget and Aiming then
            FovCircle.Color = settings.TargetedFovColor
        else
            FovCircle.Color = settings.FovColor
        end

        local triggerFov = TriggerSettings.Fov

        if TriggerSettings.InheritAimbot and AimbotSettings then
            triggerFov = AimbotSettings.Fov
        end

        TriggerCircle.Position = mousePosition
        TriggerCircle.Radius = triggerFov
        TriggerCircle.Visible = IsTriggerEnabled()

        if TriggerSettings.RainbowFov then
            TriggerHue = (TriggerHue + TriggerSettings.RainbowSpeed) % 1
            TriggerCircle.Color = Color3.fromHSV(TriggerHue, 1, 1)
        elseif TriggerTarget then
            TriggerCircle.Color = TriggerSettings.TargetedFovColor
        else
            TriggerCircle.Color = TriggerSettings.FovColor
        end
    end

    local inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Settings.Enabled or not IsInputBound(input) then
            return
        end

        Aiming = true
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if not IsInputBound(input) then
            return
        end

        Aiming = false
        CurrentTarget = nil
    end)

    local triggerInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not IsTriggerInputBound(input) then
            return
        end

        TriggerActive = not TriggerActive
    end)

    local renderConnection = RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera

        if not Camera then
            return
        end

        UpdateCircle()

        if not Settings.Enabled or not Aiming then
            CurrentTarget = nil
        else
            local target = GetLockedTarget()
            local aimPosition = GetAimPosition(target)

            if aimPosition then
                local smoothing = math.clamp(
                    tonumber(Settings.Smoothing) or 5,
                    1,
                    100
                ) / 100
                local targetCFrame = CFrame.new(
                    Camera.CFrame.Position,
                    aimPosition
                )

                Camera.CFrame = Camera.CFrame:Lerp(
                    targetCFrame,
                    smoothing
                )
            else
                CurrentTarget = nil
            end
        end

        if IsTriggerEnabled() then
            local target = GetTriggerTarget()
            TriggerTarget = target

            if target then
                if TriggerSettings.Holding then
                    SetTriggerHeld(true)
                else
                    SetTriggerHeld(false)

                    local now = os.clock()
                    local interval = 1 / math.clamp(
                        tonumber(TriggerSettings.CPS) or 10,
                        5,
                        25
                    )

                    if now - LastClick >= interval then
                        LastClick = now
                        pcall(function()
                            mouse1click()
                        end)
                    end
                end
            else
                SetTriggerHeld(false)
            end
        else
            TriggerTarget = nil
            SetTriggerHeld(false)
        end

        UpdateCircle()
    end)

    local controller = {}

    function controller:Destroy()
        inputBegan:Disconnect()
        inputEnded:Disconnect()
        triggerInputBegan:Disconnect()
        renderConnection:Disconnect()
        FovCircle.Visible = false
        FovCircle:Remove()
        TriggerCircle.Visible = false
        TriggerCircle:Remove()
        CurrentTarget = nil
        TriggerTarget = nil
        Aiming = false
    end

    return controller
end

return Aimbot