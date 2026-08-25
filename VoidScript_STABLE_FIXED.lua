--[[
    VOID SCRIPT
    Roblox Studio - safe LocalScript / testing version

    Place in:
    StarterPlayer > StarterPlayerScripts

    IMPORTANT:
    Upload your supplied black-hole image to Roblox first, then replace
    BACKGROUND_IMAGE_ID below with that Roblox image asset ID.

    Features:
      • Aim Assist (hold RMB)
      • Target Lock (Q)
      • FOV / Smoothness / Max Distance
      • Team Check / Wall Check
      • Target Part
      • ESP Boxes / ESP Lines
      • Adjustable WalkSpeed / JumpPower
      • Studio weapon-test toggles
      • Music + volume 1-500
      • Image background INSIDE the UI
      • Rainbow accents
      • Draggable / minimizable UI
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- ASSETS
--==================================================

-- Roblox does not allow a LocalScript to use a phone/local image file directly.
-- Upload the supplied black-hole picture to Creator Dashboard/Studio and paste
-- the resulting image/decal ID here.
local BACKGROUND_IMAGE_ID = "rbxassetid://905016157"
local MUSIC_ID = "rbxassetid://111351357978027"

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    Aimbot = false,
    TargetLock = false,
    TeamCheck = true,
    WallCheck = true,

    ESP = false,
    ESPLine = false,

    FOV = 150,
    Smoothness = 35,
    MaxDistance = 1000,
    AimPart = "Head",

    WalkSpeed = 16,
    JumpPower = 50,

    MusicEnabled = true,
    MusicVolume = 150,

    InfiniteAmmo = false,
    NoRecoil = false,

    HoldingAim = false,
    LockedTarget = nil,
}

local Hue = 0
local CurrentTab = "COMBAT"

--==================================================
-- CLEANUP
--==================================================

for _, guiName in ipairs({"VoidScript", "VoidScriptFOV"}) do
    local old = PlayerGui:FindFirstChild(guiName)
    if old then old:Destroy() end
end

local oldMusic = PlayerGui:FindFirstChild("VoidScriptMusic")
if oldMusic then oldMusic:Destroy() end

--==================================================
-- CHARACTER / TARGET HELPERS
--==================================================

local function getCharacter(player)
    if not player or not player.Character then
        return nil
    end

    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil
    end

    return character, humanoid, root
end

local function getLocalRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function isEnemy(player)
    if not player or player == LocalPlayer then
        return false
    end

    if Settings.TeamCheck and LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end

    return true
end

local function getDistance(position)
    local root = getLocalRoot()
    if not root then return math.huge end
    return (position - root.Position).Magnitude
end

local function visibleFromCamera(character, part)
    if not Settings.WallCheck then
        return true
    end

    local localCharacter = LocalPlayer.Character
    if not localCharacter or not part then
        return false
    end

    local originPart =
        localCharacter:FindFirstChild("Head")
        or localCharacter:FindFirstChild("HumanoidRootPart")

    if not originPart then
        return false
    end

    local direction = part.Position - originPart.Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {localCharacter}
    params.IgnoreWater = true

    local result = workspace:Raycast(
        originPart.Position,
        direction,
        params
    )

    return not result or result.Instance:IsDescendantOf(character)
end

local function getScreenDistance(worldPosition)
    local camera = workspace.CurrentCamera
    if not camera then return math.huge end

    local screen, visible =
        camera:WorldToViewportPoint(worldPosition)

    if not visible then
        return math.huge
    end

    local center = Vector2.new(
        camera.ViewportSize.X / 2,
        camera.ViewportSize.Y / 2
    )

    return (
        Vector2.new(screen.X, screen.Y) - center
    ).Magnitude
end

local function getBestTarget()
    local best = nil
    local bestScreenDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character, humanoid, root =
                getCharacter(player)

            if character and humanoid and root then
                if getDistance(root.Position) <= Settings.MaxDistance then
                    local part =
                        character:FindFirstChild(Settings.AimPart)
                        or root

                    if part and visibleFromCamera(character, part) then
                        local screenDistance =
                            getScreenDistance(part.Position)

                        if screenDistance <= Settings.FOV
                            and screenDistance < bestScreenDistance then

                            bestScreenDistance = screenDistance
                            best = player
                        end
                    end
                end
            end
        end
    end

    return best
end

local function aimAt(player)
    local character = player and player.Character
    if not character then return end

    local part =
        character:FindFirstChild(Settings.AimPart)
        or character:FindFirstChild("HumanoidRootPart")

    if not part then return end
    if not visibleFromCamera(character, part) then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local desired =
        CFrame.lookAt(camera.CFrame.Position, part.Position)

    local smooth = math.clamp(Settings.Smoothness, 1, 100)
    local alpha = math.clamp(1 / (smooth / 8), 0.02, 1)

    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VoidScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 20
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(700, 460)
Main.Position = UDim2.new(0.5, -350, 0.5, -230)
Main.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Parent = Main

-- Image background is contained inside Main.
local Background = Instance.new("ImageLabel")
Background.Name = "BlackHoleBackground"
Background.Size = UDim2.fromScale(1, 1)
Background.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Background.BackgroundTransparency = 0
Background.BorderSizePixel = 0
Background.Image = BACKGROUND_IMAGE_ID
if BACKGROUND_IMAGE_ID == "" then
    Background.ImageTransparency = 1
end
Background.ScaleType = Enum.ScaleType.Crop
Background.ImageTransparency = 0
Background.ZIndex = 0
Background.Parent = Main

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 12)
bgCorner.Parent = Background

local BackgroundHint = Instance.new("TextLabel")
BackgroundHint.Name = "BackgroundHint"
BackgroundHint.Size = UDim2.new(0, 360, 0, 54)
BackgroundHint.AnchorPoint = Vector2.new(0.5, 0.5)
BackgroundHint.Position = UDim2.fromScale(0.5, 0.5)
BackgroundHint.BackgroundTransparency = 1
BackgroundHint.Text = "BLACK-HOLE BACKGROUND\nSet BACKGROUND_IMAGE_ID to your uploaded Roblox image ID"
BackgroundHint.TextColor3 = Color3.fromRGB(255, 185, 100)
BackgroundHint.TextTransparency = 0.12
BackgroundHint.Font = Enum.Font.GothamBold
BackgroundHint.TextSize = 12
BackgroundHint.TextWrapped = true
BackgroundHint.ZIndex = 2
BackgroundHint.Visible = (BACKGROUND_IMAGE_ID == "")
BackgroundHint.Parent = Main

if BACKGROUND_IMAGE_ID ~= "" then
    Background.Image = BACKGROUND_IMAGE_ID
    BackgroundHint.Visible = false
end

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.38
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 1
Overlay.Parent = Main

local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0, 12)
overlayCorner.Parent = Overlay

-- Compact scale for smaller/mobile screens.
local UIScale = Instance.new("UIScale")
UIScale.Scale = 0.82
UIScale.Parent = Main

--==================================================
-- TOP BAR
--==================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 68)
Top.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
Top.BackgroundTransparency = 0.18
Top.BorderSizePixel = 0
Top.ZIndex = 5
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 420, 0, 34)
Title.Position = UDim2.fromOffset(22, 8)
Title.BackgroundTransparency = 1
Title.Text = "VOID SCRIPT"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 19
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Top

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 420, 0, 20)
Subtitle.Position = UDim2.fromOffset(23, 39)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "STUDIO TESTING • LOCAL"
Subtitle.TextColor3 = Color3.fromRGB(255, 150, 20)
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 8
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 6
Subtitle.Parent = Top

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(42, 38)
Minimize.Position = UDim2.new(1, -100, 0, 15)
Minimize.BackgroundColor3 = Color3.fromRGB(25, 26, 30)
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 24
Minimize.BorderSizePixel = 0
Minimize.ZIndex = 7
Minimize.Parent = Top

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 7)
minCorner.Parent = Minimize

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(42, 38)
Close.Position = UDim2.new(1, -52, 0, 15)
Close.BackgroundColor3 = Color3.fromRGB(25, 26, 30)
Close.Text = "×"
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 25
Close.BorderSizePixel = 0
Close.ZIndex = 7
Close.Parent = Top

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = Close

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 145, 1, -84)
Sidebar.Position = UDim2.fromOffset(10, 74)
Sidebar.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
Sidebar.BackgroundTransparency = 0.18
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 4
Sidebar.Parent = Main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 9)
sidebarCorner.Parent = Sidebar

-- Separate tab area so STATUS can never cover the VISUALS button.
local TabArea = Instance.new("Frame")
TabArea.Name = "TabArea"
TabArea.Size = UDim2.new(1, -18, 1, -78)
TabArea.Position = UDim2.fromOffset(9, 9)
TabArea.BackgroundTransparency = 1
TabArea.ZIndex = 5
TabArea.Parent = Sidebar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = TabArea

local TabButtons = {}

local function createTab(name)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
    b.BackgroundTransparency = 0.12
    b.BorderSizePixel = 0
    b.Text = "  " .. name
    b.TextColor3 = Color3.fromRGB(210, 211, 218)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.ZIndex = 6
    b.Parent = TabArea

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    TabButtons[name] = b
    return b
end

for _, name in ipairs({"COMBAT", "VISUALS", "MOVEMENT", "MISC", "SETTINGS"}) do
    createTab(name)
end

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -18, 0, 58)
Status.Position = UDim2.new(0, 9, 1, -67)
Status.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
Status.BackgroundTransparency = 0.1
Status.BorderSizePixel = 0
Status.Text = "●  STATUS\n    READY"
Status.TextColor3 = Color3.fromRGB(70, 255, 70)
Status.Font = Enum.Font.GothamBold
Status.TextSize = 9
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.ZIndex = 8
Status.Parent = Sidebar

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 7)
statusCorner.Parent = Status

--==================================================
-- CONTENT / PAGES
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -165, 1, -84)
Content.Position = UDim2.fromOffset(155, 74)
Content.BackgroundTransparency = 1
Content.ZIndex = 4
Content.Parent = Main

local Pages = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1,1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageTransparency = 0.25
    page.Visible = false
    page.ZIndex = 5
    page.Parent = Content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize =
            UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 20)
    end)

    Pages[name] = page
    return page
end

local Combat = createPage("COMBAT")
local Visuals = createPage("VISUALS")
local Movement = createPage("MOVEMENT")
local Misc = createPage("MISC")
local SettingsPage = createPage("SETTINGS")

--==================================================
-- UI HELPERS
--==================================================

local function section(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,150,20)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    label.Parent = parent
    return label
end

local function card(parent, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,40)
    frame.BackgroundColor3 = Color3.fromRGB(12,13,17)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.ZIndex = 6
    frame.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-22,1,0)
    label.Position = UDim2.fromOffset(11,0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(225,226,232)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 7
    label.Parent = frame

    return frame
end

local function toggle(parent, name, value, callback)
    local frame = card(parent, name)

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(52,27)
    button.Position = UDim2.new(1,-63,0.5,-13)
    button.Text = ""
    button.BorderSizePixel = 0
    button.ZIndex = 8
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1,0)
    corner.Parent = button

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(19,19)
    knob.BorderSizePixel = 0
    knob.ZIndex = 9
    knob.Parent = button

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1,0)
    knobCorner.Parent = knob

    local state = value

    local function refresh()
        button.BackgroundColor3 =
            state and Color3.fromHSV(Hue,0.75,1)
            or Color3.fromRGB(55,56,63)

        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.Position =
            state
            and UDim2.new(1,-23,0,4)
            or UDim2.fromOffset(4,4)
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)

    refresh()
    return frame
end

local function slider(parent, name, minValue, maxValue, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,64)
    frame.BackgroundColor3 = Color3.fromRGB(12,13,17)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.ZIndex = 6
    frame.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-90,0,24)
    label.Position = UDim2.fromOffset(11,5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(225,226,232)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 7
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(70,24)
    valueLabel.Position = UDim2.new(1,-80,0,5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromHSV(Hue,0.75,1)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 7
    valueLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-22,0,7)
    bar.Position = UDim2.fromOffset(11,43)
    bar.BackgroundColor3 = Color3.fromRGB(48,49,56)
    bar.BorderSizePixel = 0
    bar.ZIndex = 7
    bar.Parent = frame

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1,0)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.BorderSizePixel = 0
    fill.ZIndex = 8
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1,0)
    fc.Parent = fill

    local dragging = false

    local function setValue(x)
        local width = bar.AbsoluteSize.X
        if width <= 0 then return end

        local percent = math.clamp(
            (x - bar.AbsolutePosition.X) / width,
            0,1
        )

        local number =
            math.floor(
                minValue +
                (maxValue-minValue)*percent + 0.5
            )

        fill.Size = UDim2.new(percent,0,1,0)
        valueLabel.Text = tostring(number)
        callback(number)
    end

    local initial =
        math.clamp(
            (default-minValue)/(maxValue-minValue),
            0,1
        )

    fill.Size = UDim2.new(initial,0,1,0)

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setValue(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and
            (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setValue(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

local function button(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,40)
    b.BackgroundColor3 = Color3.fromRGB(17,18,23)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230,231,236)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.ZIndex = 6
    b.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = b

    b.MouseButton1Click:Connect(callback)
    return b
end

local function dropdown(parent, name, options, default, callback)
    local frame = card(parent, name .. ": " .. default)
    local current = default

    frame.Size = UDim2.new(1,0,0,42)

    frame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local index = table.find(options,current) or 1
        index = index % #options + 1
        current = options[index]

        local label = frame:FindFirstChildOfClass("TextLabel")
        if label then
            label.Text = name .. ": " .. current
        end

        callback(current)
    end)

    return frame
end

--==================================================
-- COMBAT
--==================================================

section(Combat, "AIM ASSIST")

toggle(Combat,"Aimbot (Hold RMB)",Settings.Aimbot,function(v)
    Settings.Aimbot = v
end)

toggle(Combat,"Target Lock",Settings.TargetLock,function(v)
    Settings.TargetLock = v
    if not v then Settings.LockedTarget = nil end
end)

toggle(Combat,"Team Check",Settings.TeamCheck,function(v)
    Settings.TeamCheck = v
end)

toggle(Combat,"Wall Check",Settings.WallCheck,function(v)
    Settings.WallCheck = v
end)

section(Combat, "AIM SETTINGS")

slider(Combat,"FOV",25,500,Settings.FOV,function(v)
    Settings.FOV = v
end)

slider(Combat,"Smoothness",1,100,Settings.Smoothness,function(v)
    Settings.Smoothness = v
end)

slider(Combat,"Max Distance",50,2000,Settings.MaxDistance,function(v)
    Settings.MaxDistance = v
end)

section(Combat, "TARGET PART")

dropdown(
    Combat,
    "Target Part",
    {"Head","HumanoidRootPart"},
    Settings.AimPart,
    function(v)
        Settings.AimPart = v
    end
)

button(Combat,"RAGE MODE",function()
    Settings.Smoothness = 1
end)

button(Combat,"LEGIT MODE",function()
    Settings.Smoothness = 45
end)

section(Combat, "TARGET STATUS")

local TargetLabel = card(Combat,"LOCKED TARGET: None")

--==================================================
-- VISUALS
--==================================================

section(Visuals, "VISUALS / ESP")

toggle(Visuals,"ESP Boxes",Settings.ESP,function(v)
    Settings.ESP = v
end)

toggle(Visuals,"ESP Lines",Settings.ESPLine,function(v)
    Settings.ESPLine = v
end)

toggle(Visuals,"FOV Circle",false,function(v)
    FOVFrame.Visible = v
end)

button(Visuals,"CLEAR ESP",function()
    for _,obj in pairs(ESPObjects) do
        if obj then obj:Destroy() end
    end
    table.clear(ESPObjects)

    for _,obj in pairs(LineObjects) do
        if obj then obj:Destroy() end
    end
    table.clear(LineObjects)
end)

--==================================================
-- MOVEMENT
--==================================================

section(Movement, "MOVEMENT")

slider(Movement,"WalkSpeed",8,100,Settings.WalkSpeed,function(v)
    Settings.WalkSpeed = v
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Settings.WalkSpeed end
end)

slider(Movement,"JumpPower",25,150,Settings.JumpPower,function(v)
    Settings.JumpPower = v
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        if h.UseJumpPower then
            h.JumpPower = Settings.JumpPower
        else
            h.JumpHeight = math.clamp(Settings.JumpPower / 7, 1, 20)
        end
    end
end)

button(Movement,"RESET MOVEMENT",function()
    Settings.WalkSpeed = 16
    Settings.JumpPower = 50
end)

--==================================================
-- MISC
--==================================================

section(Misc,"STUDIO WEAPON TESTING")

toggle(Misc,"Infinite Ammo",Settings.InfiniteAmmo,function(v)
    Settings.InfiniteAmmo = v
    -- Connect this boolean to YOUR weapon system.
end)

toggle(Misc,"No Recoil",Settings.NoRecoil,function(v)
    Settings.NoRecoil = v
    -- Connect this boolean to YOUR weapon system.
end)

section(Misc,"MUSIC")

toggle(Misc,"Music Enabled",Settings.MusicEnabled,function(v)
    Settings.MusicEnabled = v
end)

slider(Misc,"Music Volume (1-500)",1,500,Settings.MusicVolume,function(v)
    Settings.MusicVolume = v
end)

button(Misc,"RESTART MUSIC",function()
    Music:Stop()
    Music.TimePosition = 0
    if Settings.MusicEnabled then
        pcall(function() Music:Play() end)
    end
end)

--==================================================
-- SETTINGS
--==================================================

section(SettingsPage,"RESET")

button(SettingsPage,"RESET AIM",function()
    Settings.FOV = 150
    Settings.Smoothness = 35
    Settings.MaxDistance = 1000
    Settings.AimPart = "Head"
end)

button(SettingsPage,"RESET MOVEMENT",function()
    Settings.WalkSpeed = 16
    Settings.JumpPower = 50
end)

button(SettingsPage,"RESTART BACKGROUND",function()
    Background.Image = BACKGROUND_IMAGE_ID
if BACKGROUND_IMAGE_ID == "" then
    Background.ImageTransparency = 1
end
end)

section(SettingsPage,"KEYBINDS")

local hints = card(
    SettingsPage,
    "Q = Target Lock    |    RMB = Hold to Aim"
)
hints.Size = UDim2.new(1,0,0,52)

--==================================================
-- FOV UI
--==================================================

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "VoidScriptFOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 2
FOVGui.Parent = PlayerGui

FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVCircle"
FOVFrame.AnchorPoint = Vector2.new(0.5,0.5)
FOVFrame.Position = UDim2.fromScale(0.5,0.5)
FOVFrame.Size = UDim2.fromOffset(Settings.FOV*2,Settings.FOV*2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false
FOVFrame.ZIndex = 2
FOVFrame.Parent = FOVGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1,0)
fovCorner.Parent = FOVFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1
fovStroke.Transparency = 0.1
fovStroke.Parent = FOVFrame

--==================================================
-- ESP
--==================================================

ESPObjects = {}
LineObjects = {}

local function removeESP(player)
    local highlight = ESPObjects[player]
    if highlight then
        pcall(function() highlight.Adornee = nil end)
        pcall(function() highlight:Destroy() end)
        ESPObjects[player] = nil
    end

    local line = LineObjects[player]
    if line then
        pcall(function() line:Destroy() end)
        LineObjects[player] = nil
    end
end

local function updateESP()
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character,humanoid,root = getCharacter(player)

            if character and root then
                if Settings.ESP then
                    local highlight = ESPObjects[player]

                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "VoidESP"
                        highlight.DepthMode =
                            Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillTransparency = 0.65
                        highlight.OutlineTransparency = 0
                        highlight.Parent = workspace
                        ESPObjects[player] = highlight
                    end

                    highlight.Adornee = character
                    highlight.Enabled = true
                    highlight.FillColor =
                        Color3.fromHSV(Hue,0.8,1)
                    highlight.OutlineColor =
                        Color3.new(1,1,1)
                elseif ESPObjects[player] then
                    ESPObjects[player]:Destroy()
                    ESPObjects[player] = nil
                end

                if Settings.ESPLine then
                    local line = LineObjects[player]

                    if not line then
                        line = Instance.new("Frame")
                        line.Name = "ESPLine"
                        line.AnchorPoint = Vector2.new(0,0.5)
                        line.BorderSizePixel = 0
                        line.ZIndex = 3
                        line.Parent = FOVGui
                        LineObjects[player] = line
                    end

                    local camera = workspace.CurrentCamera
                    local rootLocal = getLocalRoot()

                    if camera and rootLocal then
                        local a,va =
                            camera:WorldToViewportPoint(rootLocal.Position)
                        local b,vb =
                            camera:WorldToViewportPoint(root.Position)

                        if va and vb then
                            local p1 = Vector2.new(a.X,a.Y)
                            local p2 = Vector2.new(b.X,b.Y)
                            local delta = p2-p1

                            line.Position =
                                UDim2.fromOffset(p1.X,p1.Y)
                            line.Size =
                                UDim2.fromOffset(delta.Magnitude,2)
                            line.Rotation =
                                math.deg(math.atan2(delta.Y,delta.X))
                            line.BackgroundColor3 =
                                Color3.fromHSV(Hue,0.8,1)
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                elseif LineObjects[player] then
                    LineObjects[player]:Destroy()
                    LineObjects[player] = nil
                end
            else
                removeESP(player)
            end
        else
            removeESP(player)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if Settings.LockedTarget == player then
        Settings.LockedTarget = nil
    end
end)

--==================================================
-- MUSIC
--==================================================

local Music = Instance.new("Sound")
Music.Name = "VoidScriptMusic"
Music.SoundId = MUSIC_ID
Music.Looped = true
Music.Volume = math.clamp(Settings.MusicVolume / 100, 0, 5)
Music.Parent = PlayerGui

task.spawn(function()
    task.wait(1)
    if Settings.MusicEnabled then
        pcall(function() Music:Play() end)
    end
end)

--==================================================
-- TABS
--==================================================

local function showTab(name)
    CurrentTab = name

    for pageName,page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for tabName,b in pairs(TabButtons) do
        if tabName == name then
            b.BackgroundColor3 =
                Color3.fromHSV(Hue,0.75,0.7)
            b.TextColor3 = Color3.new(1,1,1)
        else
            b.BackgroundColor3 =
                Color3.fromRGB(20,21,26)
            b.TextColor3 =
                Color3.fromRGB(210,211,218)
        end
    end
end

for name,b in pairs(TabButtons) do
    b.MouseButton1Click:Connect(function()
        showTab(name)
    end)
end

showTab("COMBAT")

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- MINIMIZE / CLOSE
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    Sidebar.Visible = not minimized
    Content.Visible = not minimized

    if minimized then
        Main.Size = UDim2.fromOffset(900,68)
        Minimize.Text = "+"
    else
        Main.Size = UDim2.fromOffset(700,460)
        Minimize.Text = "−"
    end
end)

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    FOVGui:Destroy()
    pcall(function() Music:Stop() end)
    Music:Destroy()

    for _,obj in pairs(ESPObjects) do
        if obj then obj:Destroy() end
    end

    for _,obj in pairs(LineObjects) do
        if obj then obj:Destroy() end
    end
end)

--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Settings.HoldingAim = true
    end

    if input.KeyCode == Enum.KeyCode.Q then
        Settings.TargetLock = not Settings.TargetLock
        Settings.LockedTarget = Settings.TargetLock and getBestTarget() or nil
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Settings.HoldingAim = false
    end
end)

--==================================================
-- MOVEMENT
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.25)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 3)
    if humanoid then
        humanoid.WalkSpeed = Settings.WalkSpeed
        if humanoid.UseJumpPower then
            humanoid.JumpPower = Settings.JumpPower
        else
            humanoid.JumpHeight = math.clamp(Settings.JumpPower / 7, 1, 20)
        end
    end
end)

local function updateMovement()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.WalkSpeed =
        math.clamp(Settings.WalkSpeed,8,100)

    if humanoid.UseJumpPower then
        humanoid.JumpPower =
            math.clamp(Settings.JumpPower,25,150)
    else
        humanoid.JumpHeight =
            math.clamp(Settings.JumpPower/7,1,20)
    end
end

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()
    Hue = (Hue + 0.0025) % 1

    local rainbow = Color3.fromHSV(Hue,0.85,1)

    mainStroke.Color = rainbow
    fovStroke.Color = rainbow

    -- FOV
    FOVFrame.Size =
        UDim2.fromOffset(
            Settings.FOV*2,
            Settings.FOV*2
        )

    -- Aim assist
    if Settings.Aimbot and Settings.HoldingAim then
        if Settings.TargetLock then
            if not Settings.LockedTarget then
                Settings.LockedTarget = getBestTarget()
            end

            if Settings.LockedTarget then
                aimAt(Settings.LockedTarget)
            end
        else
            local target = getBestTarget()
            if target then
                aimAt(target)
            end
        end
    end

    -- Target lock
    if Settings.TargetLock then
        local target = Settings.LockedTarget

        if target then
            local character,humanoid,root =
                getCharacter(target)

            if not character
                or not isEnemy(target)
                or getDistance(root.Position) > Settings.MaxDistance then
                Settings.LockedTarget = nil
            else
                aimAt(target)
            end
        end

        if not Settings.LockedTarget then
            Settings.LockedTarget = getBestTarget()
        end
    end

    if Settings.LockedTarget then
        TargetLabel.Text =
            "LOCKED TARGET: " ..
            Settings.LockedTarget.Name
        TargetLabel.TextColor3 = rainbow
    else
        TargetLabel.Text = "LOCKED TARGET: None"
        TargetLabel.TextColor3 =
            Color3.fromRGB(225,226,232)
    end

    -- ESP
    updateESP()

    if Settings.ESP or Settings.ESPLine then
        Status.Text = "●  STATUS\\n    VISUALS ACTIVE"
        Status.TextColor3 = rainbow
    else
        Status.Text = "●  STATUS\\n    READY"
        Status.TextColor3 = Color3.fromRGB(70,255,70)
    end

    -- Movement
    updateMovement()

    -- Music
    Music.Volume = math.clamp(Settings.MusicVolume / 100, 0, 5)

    if Settings.MusicEnabled then
        if not Music.IsPlaying then
            pcall(function() Music:Play() end)
        end
    elseif Music.IsPlaying then
        Music:Pause()
    end

    -- Highlight active tab
    for name,b in pairs(TabButtons) do
        if name == CurrentTab then
            b.BackgroundColor3 = rainbow
        end
    end
end)

print("VOID SCRIPT loaded successfully.")
print("RMB = Hold to Aim | Q = Target Lock")
