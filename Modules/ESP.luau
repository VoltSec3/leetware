local ESP = {}

function ESP.new(config)
    local Players = config.Players
    local RunService = config.RunService
    local Workspace = config.Workspace
    local Player = config.Player
    local Settings = config.Settings

    local Camera = Workspace.CurrentCamera
    local Objects = {}

    local Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3
    }

    local DefaultBoxColor = Color3.fromRGB(255, 0, 0)
    local DefaultTextColor = Color3.fromRGB(255, 255, 255)
    local DefaultHealthBorder = Color3.fromRGB(0, 0, 0)
    local DefaultHealthFill = Color3.fromRGB(255, 255, 255)

    local GradientUpdateRate = 1 / 30

    local GradientVertex = [[
struct VSOut
{
    float4 pos : SV_POSITION;
    float2 uv  : TEXCOORD0;
};

VSOut main(uint id : SV_VertexID)
{
    VSOut o;

    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2(-1.0,  3.0),
        float2( 3.0, -1.0)
    };

    float2 uv[3] = {
        float2(0.0, 1.0),
        float2(0.0, -1.0),
        float2(2.0, 1.0)
    };

    o.pos = float4(pos[id], 0.0, 1.0);
    o.uv = uv[id];

    return o;
}
]]

    local function ValidColor(value, fallback)
        if typeof(value) == "Color3" then
            return value
        end

        return fallback
    end

    local function ColorToHLSL(value, fallback)
        local color = ValidColor(value, fallback)

        return string.format(
            "float3(%.8f, %.8f, %.8f)",
            color.R,
            color.G,
            color.B
        )
    end

    local function NewLine(color, thickness)
        local line = Drawing.new("Line")
        line.Visible = false
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        line.Color = ValidColor(color, DefaultBoxColor)
        line.Thickness = thickness or 2
        line.Transparency = 1
        return line
    end

    local function NewSquare(color)
        local square = Drawing.new("Square")
        square.Visible = false
        square.Position = Vector2.new(0, 0)
        square.Size = Vector2.new(0, 0)
        square.Thickness = 1
        square.Filled = false
        square.Transparency = 1
        square.Color = ValidColor(color, DefaultBoxColor)
        return square
    end

    local function NewText()
        local text = Drawing.new("Text")
        text.Visible = false
        text.Text = ""
        text.Size = 14
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.fromRGB(0, 0, 0)
        text.Position = Vector2.new(0, 0)
        text.Font = Fonts.UI
        text.Transparency = 1
        text.Color = DefaultTextColor
        return text
    end

    local function NewGradientShader()
        local shader = Drawing.new("Shader")

        shader.Visible = false
        shader.Position = Vector2.new(0, 0)
        shader.Size = Vector2.new(1, 1)
        shader.Transparency = 1
        shader.ZIndex = 0
        shader.Vertex = GradientVertex

        shader.Pixel = [[
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    return float4(0.0, 0.0, 0.0, 0.0);
}
]]

        shader:Create()

        return shader
    end

    local function HideLibrary(library)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    nested.Visible = false
                end
            else
                object.Visible = false
            end
        end
    end

    local function SetThickness(library, thickness)
        for _, object in pairs(library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    if nested.Thickness ~= nil then
                        nested.Thickness = thickness
                    end
                end
            elseif object.Thickness ~= nil then
                object.Thickness = thickness
            end
        end
    end

    local function GetESPColor(plr)
        if Settings.Rainbow then
            return Color3.fromHSV(
                (tick() % 5) / 5,
                0.6,
                1
            )
        end

        if Settings.Team_Color and plr.TeamColor then
            return ValidColor(
                plr.TeamColor.Color,
                DefaultBoxColor
            )
        end

        if Settings.Team_Check then
            if plr.TeamColor
                and Player.TeamColor
                and plr.TeamColor == Player.TeamColor then

                return Color3.fromRGB(
                    0,
                    255,
                    0
                )
            end

            return Color3.fromRGB(
                255,
                0,
                0
            )
        end

        return ValidColor(
            Settings.Box_Color,
            DefaultBoxColor
        )
    end

    local function GetTextColor(plr, textType)
        if not Settings.CustomTextColor then
            return GetESPColor(plr)
        end

        if textType == "Name" then
            return ValidColor(
                Settings.Name_Color,
                DefaultTextColor
            )
        end

        return ValidColor(
            Settings.Team_Text_Color,
            DefaultTextColor
        )
    end

    local function DestroyObject(plr)
        local data = Objects[plr]

        if not data then
            return
        end

        if data.Connection then
            data.Connection:Disconnect()
        end

        if data.OriginPart then
            data.OriginPart:Destroy()
        end

        for _, object in pairs(data.Library) do
            if typeof(object) == "table" then
                for _, nested in pairs(object) do
                    pcall(function()
                        nested:Remove()
                    end)
                end
            else
                pcall(function()
                    object:Remove()
                end)
            end
        end

        Objects[plr] = nil
    end

    local function UpdateGradientShader(
        shader,
        left,
        top,
        right,
        bottom,
        rotation,
        color1,
        color2,
        opacity
    )
        local viewport = Camera.ViewportSize

        local viewportX = math.max(
            viewport.X,
            1
        )

        local viewportY = math.max(
            viewport.Y,
            1
        )

        local normalizedLeft =
            left / viewportX

        local normalizedTop =
            top / viewportY

        local normalizedRight =
            right / viewportX

        local normalizedBottom =
            bottom / viewportY

        local normalizedWidth =
            math.max(
                normalizedRight -
                normalizedLeft,
                0.00001
            )

        local normalizedHeight =
            math.max(
                normalizedBottom -
                normalizedTop,
                0.00001
            )

        local radians =
            math.rad(rotation)

        local color1HLSL =
            ColorToHLSL(
                color1,
                DefaultBoxColor
            )

        local color2HLSL =
            ColorToHLSL(
                color2,
                DefaultBoxColor
            )

        local pixelShader =
            string.format(
[[
cbuffer Params : register(b0)
{
    float time;
    float2 resolution;
    float2 mouse;
};

float Random(float2 value)
{
    return frac(
        sin(
            dot(
                value,
                float2(
                    12.9898,
                    78.233
                )
            )
        ) *
        43758.5453
    );
}

float4 main(
    float4 pos : SV_Position,
    float2 uv : TEXCOORD0
) : SV_Target
{
    float2 screen = pos.xy;

    float2 boxMin =
        float2(
            %.8f,
            %.8f
        );

    float2 boxMax =
        float2(
            %.8f,
            %.8f
        );

    if (
        screen.x < boxMin.x ||
        screen.y < boxMin.y ||
        screen.x > boxMax.x ||
        screen.y > boxMax.y
    )
    {
        return float4(
            0.0,
            0.0,
            0.0,
            0.0
        );
    }

    float2 boxSize =
        max(
            boxMax - boxMin,
            float2(
                0.00001,
                0.00001
            )
        );

    float2 local =
        (screen - boxMin) /
        boxSize;

    local =
        saturate(local);

    float2 centered =
        local - 0.5;

    float angle =
        %.8f;

    float c =
        cos(angle);

    float s =
        sin(angle);

    float2 rotated =
        float2(
            centered.x * c -
            centered.y * s,

            centered.x * s +
            centered.y * c
        );

    float extent =
        0.5 *
        (
            abs(c) +
            abs(s)
        );

    float t =
        saturate(
            (
                rotated.y +
                extent
            ) /
            max(
                extent * 2.0,
                0.00001
            )
        );

    float3 color1 =
        %s;

    float3 color2 =
        %s;

    float3 result =
        lerp(
            color1,
            color2,
            t
        );

    float noise =
        Random(
            screen
        ) -
        0.5;

    noise *=
        0.5 /
        255.0;

    result =
        saturate(
            result + noise
        );

    return float4(
        result,
        %.8f
    );
}
]],
                left,
                top,
                right,
                bottom,
                radians,
                color1HLSL,
                color2HLSL,
                opacity
            )

        shader.Pixel =
            pixelShader

        shader:Create()
    end

    local function CreateObject(plr)
        if plr == Player
            or Objects[plr] then
            return
        end

        local library = {
            TL1 = NewLine(),
            TL2 = NewLine(),
            TR1 = NewLine(),
            TR2 = NewLine(),
            BL1 = NewLine(),
            BL2 = NewLine(),
            BR1 = NewLine(),
            BR2 = NewLine(),

            BoxTop = NewLine(),
            BoxBottom = NewLine(),
            BoxLeft = NewLine(),
            BoxRight = NewLine(),

            Fill = NewSquare(),
            Gradient = NewGradientShader(),

            Name = NewText(),
            Team = NewText(),

            HealthOutline =
                NewSquare(
                    DefaultHealthBorder
                ),

            HealthBar =
                NewSquare(
                    DefaultHealthFill
                )
        }

        library.Fill.Filled =
            true

        library.HealthOutline.Filled =
            false

        library.HealthOutline.Color =
            DefaultHealthBorder

        library.HealthBar.Filled =
            true

        library.HealthBar.Color =
            DefaultHealthFill

        local originPart =
            Instance.new("Part")

        originPart.Parent =
            Workspace

        originPart.Transparency =
            1

        originPart.CanCollide =
            false

        originPart.CanQuery =
            false

        originPart.CanTouch =
            false

        originPart.Anchored =
            true

        originPart.Size =
            Vector3.new(
                1,
                1,
                1
            )

        local data = {
            Library = library,
            OriginPart = originPart,
            Connection = nil,

            GradientClock = 0,
            GradientKey = nil
        }

        Objects[plr] = data

        HideLibrary(
            library
        )

        data.Connection =
            RunService.RenderStepped:Connect(
                function()
                    local success =
                        pcall(
                            function()
                                Camera =
                                    Workspace.CurrentCamera

                                if not Camera then
                                    HideLibrary(
                                        library
                                    )
                                    return
                                end

                                if not Settings.Enabled then
                                    HideLibrary(
                                        library
                                    )
                                    return
                                end

                                local character =
                                    plr.Character

                                local humanoid =
                                    character
                                    and character:FindFirstChildOfClass(
                                        "Humanoid"
                                    )

                                local root =
                                    character
                                    and character:FindFirstChild(
                                        "HumanoidRootPart"
                                    )

                                local head =
                                    character
                                    and character:FindFirstChild(
                                        "Head"
                                    )

                                if not character
                                    or not humanoid
                                    or not root
                                    or not head
                                    or humanoid.Health <= 0 then

                                    HideLibrary(
                                        library
                                    )
                                    return
                                end

                                local rootPosition,
                                    visible =
                                    Camera:WorldToViewportPoint(
                                        root.Position
                                    )

                                if not visible
                                    or rootPosition.Z <= 0 then

                                    HideLibrary(
                                        library
                                    )
                                    return
                                end

                                originPart.Size =
                                    Vector3.new(
                                        root.Size.X,
                                        root.Size.Y * 1.5,
                                        root.Size.Z
                                    )

                                originPart.CFrame =
                                    CFrame.new(
                                        root.Position,
                                        Camera.CFrame.Position
                                    )

                                local sizeX =
                                    originPart.Size.X

                                local sizeY =
                                    originPart.Size.Y

                                local topLeft =
                                    Camera:WorldToViewportPoint(
                                        (
                                            originPart.CFrame *
                                            CFrame.new(
                                                sizeX,
                                                sizeY,
                                                0
                                            )
                                        ).Position
                                    )

                                local topRight =
                                    Camera:WorldToViewportPoint(
                                        (
                                            originPart.CFrame *
                                            CFrame.new(
                                                -sizeX,
                                                sizeY,
                                                0
                                            )
                                        ).Position
                                    )

                                local bottomLeft =
                                    Camera:WorldToViewportPoint(
                                        (
                                            originPart.CFrame *
                                            CFrame.new(
                                                sizeX,
                                                -sizeY,
                                                0
                                            )
                                        ).Position
                                    )

                                local bottomRight =
                                    Camera:WorldToViewportPoint(
                                        (
                                            originPart.CFrame *
                                            CFrame.new(
                                                -sizeX,
                                                -sizeY,
                                                0
                                            )
                                        ).Position
                                    )

                                local left =
                                    math.min(
                                        topLeft.X,
                                        topRight.X,
                                        bottomLeft.X,
                                        bottomRight.X
                                    )

                                local right =
                                    math.max(
                                        topLeft.X,
                                        topRight.X,
                                        bottomLeft.X,
                                        bottomRight.X
                                    )

                                local top =
                                    math.min(
                                        topLeft.Y,
                                        topRight.Y,
                                        bottomLeft.Y,
                                        bottomRight.Y
                                    )

                                local bottom =
                                    math.max(
                                        topLeft.Y,
                                        topRight.Y,
                                        bottomLeft.Y,
                                        bottomRight.Y
                                    )

                                local width =
                                    math.max(
                                        right - left,
                                        1
                                    )

                                local height =
                                    math.max(
                                        bottom - top,
                                        1
                                    )

                                local distance =
                                    (
                                        Camera.CFrame.Position -
                                        root.Position
                                    ).Magnitude

                                local offset =
                                    math.clamp(
                                        1 /
                                        math.max(
                                            distance,
                                            0.01
                                        ) *
                                        750,
                                        2,
                                        300
                                    )

                                local boxColor =
                                    GetESPColor(
                                        plr
                                    )

                                library.TL1.Color =
                                    boxColor

                                library.TL2.Color =
                                    boxColor

                                library.TR1.Color =
                                    boxColor

                                library.TR2.Color =
                                    boxColor

                                library.BL1.Color =
                                    boxColor

                                library.BL2.Color =
                                    boxColor

                                library.BR1.Color =
                                    boxColor

                                library.BR2.Color =
                                    boxColor

                                library.BoxTop.Color =
                                    boxColor

                                library.BoxBottom.Color =
                                    boxColor

                                library.BoxLeft.Color =
                                    boxColor

                                library.BoxRight.Color =
                                    boxColor

                                library.TL1.From =
                                    Vector2.new(
                                        topLeft.X,
                                        topLeft.Y
                                    )

                                library.TL1.To =
                                    Vector2.new(
                                        topLeft.X +
                                        offset,
                                        topLeft.Y
                                    )

                                library.TL2.From =
                                    Vector2.new(
                                        topLeft.X,
                                        topLeft.Y
                                    )

                                library.TL2.To =
                                    Vector2.new(
                                        topLeft.X,
                                        topLeft.Y +
                                        offset
                                    )

                                library.TR1.From =
                                    Vector2.new(
                                        topRight.X,
                                        topRight.Y
                                    )

                                library.TR1.To =
                                    Vector2.new(
                                        topRight.X -
                                        offset,
                                        topRight.Y
                                    )

                                library.TR2.From =
                                    Vector2.new(
                                        topRight.X,
                                        topRight.Y
                                    )

                                library.TR2.To =
                                    Vector2.new(
                                        topRight.X,
                                        topRight.Y +
                                        offset
                                    )

                                library.BL1.From =
                                    Vector2.new(
                                        bottomLeft.X,
                                        bottomLeft.Y
                                    )

                                library.BL1.To =
                                    Vector2.new(
                                        bottomLeft.X +
                                        offset,
                                        bottomLeft.Y
                                    )

                                library.BL2.From =
                                    Vector2.new(
                                        bottomLeft.X,
                                        bottomLeft.Y
                                    )

                                library.BL2.To =
                                    Vector2.new(
                                        bottomLeft.X,
                                        bottomLeft.Y -
                                        offset
                                    )

                                library.BR1.From =
                                    Vector2.new(
                                        bottomRight.X,
                                        bottomRight.Y
                                    )

                                library.BR1.To =
                                    Vector2.new(
                                        bottomRight.X -
                                        offset,
                                        bottomRight.Y
                                    )

                                library.BR2.From =
                                    Vector2.new(
                                        bottomRight.X,
                                        bottomRight.Y
                                    )

                                library.BR2.To =
                                    Vector2.new(
                                        bottomRight.X,
                                        bottomRight.Y -
                                        offset
                                    )

                                library.BoxTop.From =
                                    Vector2.new(
                                        left,
                                        top
                                    )

                                library.BoxTop.To =
                                    Vector2.new(
                                        right,
                                        top
                                    )

                                library.BoxBottom.From =
                                    Vector2.new(
                                        left,
                                        bottom
                                    )

                                library.BoxBottom.To =
                                    Vector2.new(
                                        right,
                                        bottom
                                    )

                                library.BoxLeft.From =
                                    Vector2.new(
                                        left,
                                        top
                                    )

                                library.BoxLeft.To =
                                    Vector2.new(
                                        left,
                                        bottom
                                    )

                                library.BoxRight.From =
                                    Vector2.new(
                                        right,
                                        top
                                    )

                                library.BoxRight.To =
                                    Vector2.new(
                                        right,
                                        bottom
                                    )

                                local boxStyle =
                                    Settings.BoxStyle
                                    or "Corner"

                                local corner =
                                    boxStyle ==
                                    "Corner"

                                local normal =
                                    boxStyle ==
                                    "Normal"

                                library.TL1.Visible =
                                    corner

                                library.TL2.Visible =
                                    corner

                                library.TR1.Visible =
                                    corner

                                library.TR2.Visible =
                                    corner

                                library.BL1.Visible =
                                    corner

                                library.BL2.Visible =
                                    corner

                                library.BR1.Visible =
                                    corner

                                library.BR2.Visible =
                                    corner

                                library.BoxTop.Visible =
                                    normal

                                library.BoxBottom.Visible =
                                    normal

                                library.BoxLeft.Visible =
                                    normal

                                library.BoxRight.Visible =
                                    normal

                                local opacity =
                                    tonumber(
                                        Settings.Fill_Opacity
                                    ) or 0.15

                                opacity =
                                    math.clamp(
                                        opacity,
                                        0,
                                        1
                                    )

                                if Settings.FillBoxGradient then
                                    library.Fill.Visible =
                                        false

                                    library.Gradient.Visible =
                                        true

                                    local gradientColor1 =
                                        ValidColor(
                                            Settings.Gradient_Color_1,
                                            DefaultBoxColor
                                        )

                                    local gradientColor2 =
                                        ValidColor(
                                            Settings.Gradient_Color_2,
                                            DefaultBoxColor
                                        )

                                    local gradientRotation =
                                        tonumber(
                                            Settings.Gradient_Rotation
                                        ) or 0

                                    local viewport =
                                        Camera.ViewportSize

                                    local screenLeft =
                                        math.clamp(
                                            left,
                                            0,
                                            viewport.X
                                        )

                                    local screenTop =
                                        math.clamp(
                                            top,
                                            0,
                                            viewport.Y
                                        )

                                    local screenRight =
                                        math.clamp(
                                            right,
                                            0,
                                            viewport.X
                                        )

                                    local screenBottom =
                                        math.clamp(
                                            bottom,
                                            0,
                                            viewport.Y
                                        )

                                    data.GradientClock +=
                                        1 /
                                        math.max(
                                            1 /
                                            RunService.RenderStepped:Wait(),
                                            1
                                        )

                                    local now =
                                        os.clock()

                                    local key =
                                        string.format(
                                            "%d:%d:%d:%d:%d:%d:%d:%.4f:%.4f:%.4f",
                                            math.floor(
                                                screenLeft
                                            ),
                                            math.floor(
                                                screenTop
                                            ),
                                            math.ceil(
                                                screenRight
                                            ),
                                            math.ceil(
                                                screenBottom
                                            ),
                                            viewport.X,
                                            viewport.Y,
                                            gradientRotation,
                                            gradientColor1.R,
                                            gradientColor2.R,
                                            opacity
                                        )

                                    if data.GradientKey ~= key
                                        or now >=
                                            (
                                                data.GradientClock +
                                                GradientUpdateRate
                                            ) then

                                        data.GradientKey =
                                            key

                                        data.GradientClock =
                                            now

                                        UpdateGradientShader(
                                            library.Gradient,
                                            screenLeft,
                                            screenTop,
                                            screenRight,
                                            screenBottom,
                                            gradientRotation,
                                            gradientColor1,
                                            gradientColor2,
                                            opacity
                                        )
                                    end
                                else
                                    library.Gradient.Visible =
                                        false

                                    if Settings.FillBox then
                                        library.Fill.Visible =
                                            true

                                        library.Fill.Color =
                                            ValidColor(
                                                Settings.Fill_Box_Color,
                                                DefaultBoxColor
                                            )

                                        library.Fill.Transparency =
                                            opacity

                                        library.Fill.Position =
                                            Vector2.new(
                                                left,
                                                top
                                            )

                                        library.Fill.Size =
                                            Vector2.new(
                                                width,
                                                height
                                            )
                                    else
                                        library.Fill.Visible =
                                            false
                                    end
                                end

                                local nameScale =
                                    tonumber(
                                        Settings.Name_Scale
                                    ) or 14

                                nameScale =
                                    math.clamp(
                                        nameScale,
                                        1,
                                        100
                                    )

                                library.Name.Visible =
                                    Settings.ShowName

                                library.Name.Text =
                                    tostring(
                                        plr.Name
                                    )

                                library.Name.Color =
                                    GetTextColor(
                                        plr,
                                        "Name"
                                    )

                                library.Name.Size =
                                    nameScale

                                library.Name.Font =
                                    Fonts[
                                        Settings.Font
                                    ] or Fonts.UI

                                library.Name.Position =
                                    Vector2.new(
                                        (left + right) / 2,
                                        top -
                                        nameScale -
                                        5
                                    )

                                library.Team.Visible =
                                    Settings.ShowTeam

                                library.Team.Text =
                                    plr.Team
                                    and tostring(
                                        plr.Team.Name
                                    )
                                    or "Neutral"

                                library.Team.Color =
                                    GetTextColor(
                                        plr,
                                        "Team"
                                    )

                                library.Team.Size =
                                    math.max(
                                        nameScale - 1,
                                        10
                                    )

                                library.Team.Font =
                                    Fonts[
                                        Settings.Font
                                    ] or Fonts.UI

                                library.Team.Position =
                                    Vector2.new(
                                        (left + right) / 2,
                                        top -
                                        (
                                            Settings.ShowName
                                            and nameScale + 19
                                            or 18
                                        )
                                    )

                                local healthRatio =
                                    0

                                if humanoid.MaxHealth
                                    and humanoid.MaxHealth > 0 then

                                    healthRatio =
                                        math.clamp(
                                            humanoid.Health /
                                            humanoid.MaxHealth,
                                            0,
                                            1
                                        )
                                end

                                local healthWidth =
                                    5

                                local healthGap =
                                    5

                                library.HealthOutline.Visible =
                                    Settings.ShowHealth

                                library.HealthOutline.Color =
                                    ValidColor(
                                        Settings.HealthBorder_Color,
                                        DefaultHealthBorder
                                    )

                                library.HealthOutline.Position =
                                    Vector2.new(
                                        right +
                                        healthGap,
                                        top
                                    )

                                library.HealthOutline.Size =
                                    Vector2.new(
                                        healthWidth,
                                        height
                                    )

                                library.HealthBar.Visible =
                                    Settings.ShowHealth

                                library.HealthBar.Color =
                                    ValidColor(
                                        Settings.HealthFill_Color,
                                        DefaultHealthFill
                                    )

                                library.HealthBar.Position =
                                    Vector2.new(
                                        right +
                                        healthGap +
                                        1,
                                        bottom -
                                        (
                                            (height - 2) *
                                            healthRatio
                                        ) -
                                        1
                                    )

                                library.HealthBar.Size =
                                    Vector2.new(
                                        healthWidth - 2,
                                        math.max(
                                            (height - 2) *
                                            healthRatio,
                                            0
                                        )
                                    )

                                local thickness

                                if Settings.Autothickness then
                                    thickness =
                                        math.clamp(
                                            1 /
                                            math.max(
                                                distance,
                                                0.01
                                            ) *
                                            100,
                                            1,
                                            4
                                        )
                                else
                                    thickness =
                                        tonumber(
                                            Settings.Box_Thickness
                                        ) or 2
                                end

                                SetThickness({
                                    TL1 =
                                        library.TL1,

                                    TL2 =
                                        library.TL2,

                                    TR1 =
                                        library.TR1,

                                    TR2 =
                                        library.TR2,

                                    BL1 =
                                        library.BL1,

                                    BL2 =
                                        library.BL2,

                                    BR1 =
                                        library.BR1,

                                    BR2 =
                                        library.BR2,

                                    BoxTop =
                                        library.BoxTop,

                                    BoxBottom =
                                        library.BoxBottom,

                                    BoxLeft =
                                        library.BoxLeft,

                                    BoxRight =
                                        library.BoxRight,

                                    HealthOutline =
                                        library.HealthOutline
                                }, thickness)
                            end
                        )

                    if not success then
                        HideLibrary(
                            library
                        )
                    end
                end)
    end

    local controller = {}

    for _, plr in ipairs(
        Players:GetPlayers()
    ) do
        CreateObject(plr)
    end

    controller.PlayerAdded =
        Players.PlayerAdded:Connect(
            function(plr)
                CreateObject(plr)
            end
        )

    controller.PlayerRemoving =
        Players.PlayerRemoving:Connect(
            function(plr)
                DestroyObject(plr)
            end
        )

    function controller:Destroy()
        if controller.PlayerAdded then
            controller.PlayerAdded:Disconnect()
            controller.PlayerAdded = nil
        end

        if controller.PlayerRemoving then
            controller.PlayerRemoving:Disconnect()
            controller.PlayerRemoving = nil
        end

        for plr in pairs(Objects) do
            DestroyObject(plr)
        end
    end

    return controller
end

return ESP