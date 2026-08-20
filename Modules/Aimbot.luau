local Aimbot = {}

function Aimbot.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local UserInputService = config.UserInputService
    local Settings = config.Settings
    local Camera = Workspace.CurrentCamera
    local CurrentTarget = nil
    local Aiming = false
    local Hue = 0
    local AimStartMouseBehavior = nil
    local OriginalMouseBehavior = nil
    local MouseLockedByAimbot = false
    local LockStartedInFirstPerson = false
    local PendingFirstPersonUnlock = false
    local MouseLockDisabled = false

    local FovCircle = Drawing.new("Circle")
    FovCircle.Thickness = 2
    FovCircle.Filled = false
    FovCircle.Visible = false

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

    local IsBlocked

    IsBlocked = function(character)
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

        bind = string.upper(bind)
        bind = string.gsub(bind, "^ENUM%.KEYCODE%.", "")
        bind = string.gsub(bind, "^ENUM%.USERINPUTTYPE%.", "")

        if bind == "MB1" or bind == "MOUSEBUTTON1" then
            return input.UserInputType == Enum.UserInputType.MouseButton1
        end

        if bind == "MB2" or bind == "MOUSEBUTTON2" then
            return input.UserInputType == Enum.UserInputType.MouseButton2
        end

        return input.KeyCode.Name == bind
            or input.UserInputType.Name == bind
    end

    local function IsBindHeld()
        local bind = Settings.Bind

        if typeof(bind) == "EnumItem" then
            if bind.EnumType == Enum.KeyCode then
                return UserInputService:IsKeyDown(bind)
            end

            return UserInputService:IsMouseButtonPressed(bind)
        end

        if type(bind) ~= "string" then
            return false
        end

        bind = string.upper(bind)
        bind = string.gsub(bind, "^ENUM%.KEYCODE%.", "")
        bind = string.gsub(bind, "^ENUM%.USERINPUTTYPE%.", "")

        if bind == "MB1" or bind == "MOUSEBUTTON1" then
            return UserInputService:IsMouseButtonPressed(
                Enum.UserInputType.MouseButton1
            )
        end

        if bind == "MB2" or bind == "MOUSEBUTTON2" then
            return UserInputService:IsMouseButtonPressed(
                Enum.UserInputType.MouseButton2
            )
        end

        local keyCode = Enum.KeyCode[bind]

        if keyCode then
            return UserInputService:IsKeyDown(keyCode)
        end

        return false
    end

    local function IsFirstPerson()
        local character = Player.Character
        local head = character and character:FindFirstChild("Head")

        if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
            return true
        end

        return head
            and (Camera.CFrame.Position - head.Position).Magnitude <= 1.5
            or false
    end

    local function UnlockMouse()
        if MouseLockedByAimbot then
            if LockStartedInFirstPerson then
                PendingFirstPersonUnlock = IsFirstPerson()
                UserInputService.MouseBehavior = PendingFirstPersonUnlock
                    and OriginalMouseBehavior
                    or Enum.MouseBehavior.Default
            else
                UserInputService.MouseBehavior = OriginalMouseBehavior
            end

            OriginalMouseBehavior = nil
            MouseLockedByAimbot = false
            LockStartedInFirstPerson = false
        end
    end

    local function StopAiming()
        Aiming = false
        CurrentTarget = nil
        MouseLockDisabled = false
        UnlockMouse()
        AimStartMouseBehavior = nil
    end

    local function LockMouse()
        if MouseLockedByAimbot or MouseLockDisabled then
            return
        end

        OriginalMouseBehavior = AimStartMouseBehavior
            or UserInputService.MouseBehavior

        if IsFirstPerson()
            and OriginalMouseBehavior
                ~= Enum.MouseBehavior.LockCenter then
            OriginalMouseBehavior = Enum.MouseBehavior.LockCenter
        end

        LockStartedInFirstPerson = IsFirstPerson()
        MouseLockedByAimbot = true
        PendingFirstPersonUnlock = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
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


    end

    local inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if not Settings.Enabled or not IsInputBound(input) then
            return
        end

        if not IsFirstPerson()
            and UserInputService.MouseBehavior
                ~= Enum.MouseBehavior.LockCenter then
            return
        end

        Aiming = true
        AimStartMouseBehavior = UserInputService.MouseBehavior

        if IsFirstPerson()
            and AimStartMouseBehavior ~= Enum.MouseBehavior.LockCenter then
            AimStartMouseBehavior = Enum.MouseBehavior.LockCenter
        end

        MouseLockDisabled = false
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if not IsInputBound(input) then
            return
        end

        StopAiming()
    end)

    local renderConnection = RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera

        if not Camera then
            return
        end

        UpdateCircle()

        if not Settings.Enabled or not Aiming then
            StopAiming()

            if PendingFirstPersonUnlock and not IsFirstPerson() then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                PendingFirstPersonUnlock = false
            end
        else
            if not IsBindHeld() then
                StopAiming()
                return
            end

            if LockStartedInFirstPerson
                and not IsFirstPerson()
                and MouseLockedByAimbot then
                UnlockMouse()
                MouseLockDisabled = true
                PendingFirstPersonUnlock = false
                return
            end

            local target = GetLockedTarget()
            local aimPosition = GetAimPosition(target)

            if aimPosition then
                LockMouse()

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
                UnlockMouse()
            end
        end

    end)

    local controller = {}

    function controller:Destroy()
        inputBegan:Disconnect()
        inputEnded:Disconnect()
        renderConnection:Disconnect()
        FovCircle.Visible = false
        FovCircle:Remove()
        StopAiming()
    end

    return controller
end

return Aimbot