local Aimbot = {}

function Aimbot.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local UserInputService = config.UserInputService
    local Utils = config.Utils
    local Settings = config.Settings
    local Mouse = Player:GetMouse()
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
    local TriggerbotTarget = nil
    local TriggerbotNextFire = nil
    local MotorSim = nil

    local function GetGlobalFunction(name)
        local environment = type(getgenv) == "function"
            and getgenv()
            or _G

        return environment and environment[name]
            or _G[name]
    end

    local FovCircle = Drawing.new("Circle")
    FovCircle.Thickness = 2
    FovCircle.Filled = false
    FovCircle.Visible = false

    local function IsTeamBlocked(target)
        local excludedTeams = Settings.ExcludeTeams or {}
        local teamName = Utils.GetTeamName(target)

        if excludedTeams[teamName] then
            return true
        end

        return Settings.TeamCheck
            and target.Team
            and Player.Team
            and target.Team == Player.Team
    end

    local function GetTeamPriority(target)
        local prioritizedTeams = Settings.PrioritizeTeams or {}

        return prioritizedTeams[Utils.GetTeamName(target)] and 1 or 0
    end

    local function HasValidHealth(target, ignoreMinimum)
        local humanoid = Utils.GetHumanoid(target)

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

        return Utils.IsFriend(Player, target)
    end

    local IsBlocked

    IsBlocked = function(character, ignorePlayers)
        local head = Utils.GetCharacterPart(character, "Head")

        if not head then
            return true
        end

        local origin = Camera.CFrame.Position
        local direction = head.Position - origin
        local raycastParams = RaycastParams.new()
        local filter = { Player.Character }

        if ignorePlayers then
            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= Player and target.Character then
                    table.insert(filter, target.Character)
                end
            end
        end

        raycastParams.FilterDescendantsInstances = filter
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local result = Workspace:Raycast(
            origin,
            direction,
            raycastParams
        )

        return result ~= nil
            and not result.Instance:IsDescendantOf(character)
    end

    local function IsTargetValid(
        target,
        requireFov,
        maintainLock,
        ignorePlayers
    )
        if not target or target == Player then
            return false
        end

        local character = target.Character
        local head = Utils.GetHead(target)

        if not character or not head then
            return false
        end

        local range = math.clamp(
            tonumber(Settings.Range) or 500,
            1,
            1500
        )

        if (head.Position - Camera.CFrame.Position).Magnitude > range then
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
            and IsBlocked(character, ignorePlayers) then
            return false
        end

        return true
    end

    local function GetTarget()
        local candidates = {}
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

                table.insert(candidates, {
                    target = target,
                    priority = GetTeamPriority(target),
                    cursorDistance = cursorDistance,
                    playerDistance = playerDistance
                })
            end
        end

        if #candidates == 0 then
            return nil
        end

        local targeting = Settings.Targeting or "Normal"

        if targeting == "Random" then
            return candidates[math.random(1, #candidates)].target
        end

        local selected = candidates[1]

        for index = 2, #candidates do
            local candidate = candidates[index]
            local isBetter = false

            if targeting == "Closest" then
                isBetter = candidate.playerDistance < selected.playerDistance
            elseif targeting == "Furthest" then
                isBetter = candidate.playerDistance > selected.playerDistance
            else
                isBetter = candidate.priority > selected.priority
                    or (
                        candidate.priority == selected.priority
                        and (
                            candidate.cursorDistance < selected.cursorDistance
                            or (
                                candidate.cursorDistance
                                    == selected.cursorDistance
                                and candidate.playerDistance
                                    < selected.playerDistance
                            )
                        )
                    )
            end

            if isBetter then
                selected = candidate
            end
        end

        return selected.target
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
        local head = Utils.GetHead(target)
        local root = Utils.GetRootPart(target)

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
        TriggerbotTarget = nil
        TriggerbotNextFire = nil
        MouseLockDisabled = false

        if MotorSim then
            MotorSim:Reset()
        end

        UnlockMouse()
        AimStartMouseBehavior = nil
    end

    local function GetTriggerbotDelay()
        return math.clamp(
            tonumber(Settings.TriggerbotDelay) or 0,
            0,
            0.3
        )
    end

    local function ResetTriggerbot()
        TriggerbotTarget = nil
        TriggerbotNextFire = nil
    end

    local function ClickMouse1()
        local press = GetGlobalFunction("mouse1press")
        local release = GetGlobalFunction("mouse1release")

        if type(press) ~= "function" or type(release) ~= "function" then
            return false
        end

        local pressed = pcall(press)
        local released = pcall(release)

        return pressed and released
    end

    local function GetHeadCursorRadius(head)
        local headPosition, visible = Camera:WorldToViewportPoint(
            head.Position
        )

        if not visible or headPosition.Z <= 0 then
            return nil
        end

        local edgePosition = Camera:WorldToViewportPoint(
            head.Position + Vector3.new(head.Size.X / 2, 0, 0)
        )
        local radius = (
            Vector2.new(edgePosition.X, edgePosition.Y)
            - Vector2.new(headPosition.X, headPosition.Y)
        ).Magnitude

        return math.max(radius * 1.25, 6)
    end

    local function GetTriggerbotTarget()
        local cursorPosition = UserInputService:GetMouseLocation()
        local nearestTarget = nil
        local nearestDistance = math.huge

        for _, target in ipairs(Players:GetPlayers()) do
            local head = Utils.GetHead(target)

            if head and IsTargetValid(target, false, false, true) then
                local screenPosition, visible = Camera:WorldToViewportPoint(
                    head.Position
                )
                local cursorDistance = (
                    Vector2.new(screenPosition.X, screenPosition.Y)
                    - cursorPosition
                ).Magnitude
                local cursorRadius = GetHeadCursorRadius(
                    head
                )

                if visible
                    and cursorRadius
                    and cursorDistance <= cursorRadius
                    and cursorDistance < nearestDistance then
                    nearestTarget = target
                    nearestDistance = cursorDistance
                end
            end
        end

        return nearestTarget
    end

    local function UpdateTriggerbot()
        if not Settings.Triggerbot
            or not Aiming then
            ResetTriggerbot()
            return
        end

        local targetPlayer = GetTriggerbotTarget()
        local isValidHead = targetPlayer
            and targetPlayer ~= Player
            and IsTargetValid(targetPlayer, false, false, true)

        if not isValidHead then
            ResetTriggerbot()
            return
        end

        local now = os.clock()

        if TriggerbotTarget ~= targetPlayer then
            TriggerbotTarget = targetPlayer
            TriggerbotNextFire = now + GetTriggerbotDelay()
        end

        if TriggerbotNextFire and now >= TriggerbotNextFire then
            if not ClickMouse1() then
                ResetTriggerbot()
                return
            end

            TriggerbotNextFire = now
        end
    end

    MotorSim = (function()
        local seed = tonumber(Settings.RngSeed) or 0
        local rng = seed > 0 and Random.new(math.floor(seed)) or Random.new()

        local TelemetryBuffer = {}
        local TelemetryIndex = 0
        local TelemetryCount = 0
        local TelemetryCapacity = 6000

        local function Gauss(mean, sd)
            local u1 = rng:NextNumber()
            local u2 = rng:NextNumber()
            local magnitude = math.sqrt(
                -2 * math.log(math.max(u1, 1e-9))
            )

            return mean + sd * magnitude * math.cos(2 * math.pi * u2)
        end

        local function Number(name, default)
            local value = tonumber(Settings[name])

            return value or default
        end

        local state = {
            readyAt = nil,
            active = false,
            startRotationInverse = nil,
            x = 0,
            y = 0,
            vx = 0,
            vy = 0,
            prevX = 0,
            prevY = 0,
            omega = 6,
            zeta = 0.92,
            tracking = false,
            biasX = 0,
            biasY = 0,
            localOffX = 0,
            localOffY = 0,
            noiseX = 0,
            noiseY = 0,
            curveSign = 1,
            curveAmp = 0,
            unitYaw = 0,
            unitPitch = 0,
            distance0 = 0,
            nextLocalRefresh = 0,
            nextKick = nil
        }

        local function SampleTrial(distance0)
            local durationScale = math.max(Number("DurationScale", 1), 0.1)
            local variability = math.clamp(
                Number("DurationVariability", 0.15),
                0,
                0.5
            )
            local movementTime = (
                0.08 + 0.13 * math.log(distance0 / 3 + 1)
            ) * durationScale * math.exp(Gauss(0, variability))

            state.omega = math.clamp(5.8 / math.max(movementTime, 0.06), 1.5, 14)

            local overshootChance = math.clamp(
                Number("OvershootProbability", 0.35),
                0,
                1
            )
            local baseZeta = math.clamp(Number("Damping", 0.92), 0.5, 1.1)

            if rng:NextNumber() < overshootChance then
                local ratio = math.clamp(
                    Number("OvershootMagnitude", 5),
                    0.5,
                    40
                ) / 100
                local logarithm = math.log(ratio)

                state.zeta = math.clamp(
                    -logarithm / math.sqrt(math.pi ^ 2 + logarithm ^ 2),
                    0.45,
                    0.85
                )
            else
                state.zeta = math.min(baseZeta + 0.06, 1.1)
            end

            local biasScale = math.max(Number("FinalBiasDegrees", 0.35), 0)

            state.biasX = Gauss(0, biasScale)
            state.biasY = Gauss(0, biasScale)
            state.localOffX = state.biasX
            state.localOffY = state.biasY
            state.curveAmp = math.max(Number("CurvatureDegrees", 1.5), 0)
                * math.clamp(distance0 / 45, 0, 1)
            state.curveSign = rng:NextInteger(0, 1) == 0 and 1 or -1
            state.nextKick = os.clock()
                + math.exp(1) / math.max(Number("MicroCorrectionRate", 2.5), 0.01)
            state.nextLocalRefresh = 0
        end

        local function RecordTelemetry(clock, setErrorX, setErrorY, speed, accel, phase)
            if not Settings.Telemetry then
                return
            end

            local sample = {
                clock,
                setErrorX,
                setErrorY,
                speed,
                accel,
                phase
            }

            TelemetryIndex = TelemetryIndex % TelemetryCapacity + 1
            TelemetryBuffer[TelemetryIndex] = sample
            TelemetryCount = math.min(TelemetryCount + 1, TelemetryCapacity)
        end

        local methods = {}

        function methods:OnEngage()
            local mean = math.max(Number("ReactionMean", 0.18), 0)
            local sd = math.clamp(Number("ReactionSd", 0.05), 0, 0.3)

            state.readyAt = os.clock() + math.max(Gauss(mean, sd), 0)
            state.active = false
            state.tracking = false
            state.x = 0
            state.y = 0
            state.vx = 0
            state.vy = 0
            state.noiseX = 0
            state.noiseY = 0
        end

        function methods:Reset()
            state.readyAt = nil
            state.active = false
            state.tracking = false
            state.startRotationInverse = nil
            state.x = 0
            state.y = 0
            state.vx = 0
            state.vy = 0
            state.prevX = 0
            state.prevY = 0
            state.noiseX = 0
            state.noiseY = 0
        end

        function methods:GetTelemetry()
            local samples = table.create(TelemetryCount)

            for index = 1, TelemetryCount do
                local readIndex = (TelemetryIndex - TelemetryCount + index - 1)
                    % TelemetryCapacity + 1

                samples[index] = TelemetryBuffer[readIndex]
            end

            return samples
        end

        function methods:Step(deltaTime, target, aimPosition)
            if not Settings.HumanizedAim then
                return false
            end

            local now = os.clock()

            if not state.active then
                if not state.readyAt or now < state.readyAt then
                    return true
                end

                local startRotation = Camera.CFrame.Rotation

                state.startRotationInverse = startRotation:Inverse()

                local relative = (
                    CFrame.new(Camera.CFrame.Position, aimPosition)
                    * state.startRotationInverse
                ).Rotation
                local pitch, yaw = relative:ToEulerAnglesYXZ()

                state.distance0 = math.max(math.sqrt(
                    math.deg(yaw) ^ 2 + math.deg(pitch) ^ 2
                ), 0.5)
                state.unitYaw = math.deg(yaw) / state.distance0
                state.unitPitch = math.deg(pitch) / state.distance0

                SampleTrial(state.distance0)

                state.x = 0
                state.y = 0
                state.vx = 0
                state.vy = 0
                state.prevX = 0
                state.prevY = 0
                state.tracking = false
                state.active = true
            end

            local step = math.clamp(deltaTime, 0.0005, 0.05)
            local relative = (
                CFrame.new(Camera.CFrame.Position, aimPosition)
                * state.startRotationInverse
            ).Rotation
            local pitch, yaw = relative:ToEulerAnglesYXZ()
            local setErrorX = math.deg(yaw)
            local setErrorY = math.deg(pitch)

            if not state.tracking then
                local traveled = math.clamp(
                    math.sqrt(state.x ^ 2 + state.y ^ 2)
                        / state.distance0,
                    0,
                    1
                )
                local bow = state.curveSign * state.curveAmp
                    * math.sin(math.pi * traveled)

                setErrorX = setErrorX
                    + (-state.unitPitch) * bow
                    + state.biasX
                setErrorY = setErrorY
                    + state.unitYaw * bow
                    + state.biasY
            else
                if now >= state.nextLocalRefresh then
                    local spread = math.max(
                        Number("FinalBiasDegrees", 0.35),
                        0
                    ) * 0.7

                    state.localOffX = Gauss(state.biasX, spread)
                    state.localOffY = Gauss(state.biasY, spread)
                    state.nextLocalRefresh = now
                        + math.exp(1)
                            / math.max(Number("MicroCorrectionRate", 2.5), 0.01)
                end

                setErrorX = setErrorX + state.localOffX
                setErrorY = setErrorY + state.localOffY

                if state.nextKick and now >= state.nextKick then
                    local kick = 6 * math.max(Number("NoiseScale", 1), 0)

                    state.vx = state.vx + Gauss(0, kick) * 0.12
                    state.vy = state.vy + Gauss(0, kick) * 0.12
                    state.nextKick = now
                        + math.exp(1)
                            / math.max(Number("MicroCorrectionRate", 2.5), 0.01)
                        * rng:NextNumber(0.6, 1.6)
                end
            end

            local noiseScale = math.max(Number("NoiseScale", 1), 0)
            local noiseDrive = 14 * noiseScale
            local omegaSquared = state.omega ^ 2
            local accelX = omegaSquared * (setErrorX - state.x)
                - 2 * state.zeta * state.omega * state.vx
                + noiseDrive * state.noiseX
            local accelY = omegaSquared * (setErrorY - state.y)
                - 2 * state.zeta * state.omega * state.vy
                + noiseDrive * state.noiseY

            state.noiseX = math.clamp(
                state.noiseX
                    + (-3 * state.noiseX * step + math.sqrt(step) * Gauss(0, 1)),
                -1,
                1
            )
            state.noiseY = math.clamp(
                state.noiseY
                    + (-3 * state.noiseY * step + math.sqrt(step) * Gauss(0, 1)),
                -1,
                1
            )

            state.vx = state.vx + accelX * step
            state.vy = state.vy + accelY * step

            local maxSpeed = math.max(Number("MaxSpeedDegPerSec", 340), 30)
            local speed = math.sqrt(state.vx ^ 2 + state.vy ^ 2)

            if speed > maxSpeed then
                state.vx = state.vx * maxSpeed / speed
                state.vy = state.vy * maxSpeed / speed
                speed = maxSpeed
            end

            state.x = state.x + state.vx * step
            state.y = state.y + state.vy * step

            if not state.tracking then
                local residual = math.sqrt(
                    (setErrorX - state.x) ^ 2 + (setErrorY - state.y) ^ 2
                )

                if residual < 0.8 and speed < 25 then
                    state.tracking = true
                    state.nextLocalRefresh = 0
                end
            end

            RecordTelemetry(
                now,
                setErrorX - state.x,
                setErrorY - state.y,
                speed,
                math.sqrt(accelX ^ 2 + accelY ^ 2),
                state.tracking and 2 or 1
            )

            local deltaX = state.x - state.prevX
            local deltaY = state.y - state.prevY

            state.prevX = state.x
            state.prevY = state.y

            Camera.CFrame = Camera.CFrame
                * CFrame.fromEulerAnglesYXZ(
                    math.rad(deltaY),
                    math.rad(deltaX),
                    0
                )

            return true
        end

        return methods
    end)()

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

        if MotorSim then
            MotorSim:OnEngage()
        end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if not IsInputBound(input) then
            return
        end

        StopAiming()
    end)

    local renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
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

                if not MotorSim:Step(deltaTime, target, aimPosition) then
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
                end
            else
                CurrentTarget = nil
                UnlockMouse()
            end

            UpdateTriggerbot()
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

    function controller:GetTelemetry()
        if MotorSim then
            return MotorSim:GetTelemetry()
        end

        return {}
    end

    return controller
end

return Aimbot