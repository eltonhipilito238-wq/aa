--[[
                            QUANTUM ONYX HUB PROJECT
            This was made by Quantum Onyx Team ( discord.gg/quantumonyx )
            KEYSYSTEM UI built using claude ai
            Service by Luarmor.net
            Compiled by: Flazhy
            Copyright © 2022-2026 Quantum Onyx Team - All Rights Reserved.
]]--
local Directory = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Games"
local Api = "https://api.luarmor.net/files/v4/loaders"
local Scripts = {
    Free = {
        [994732206] = Directory .. "/BloxFruits.lua",
        [9186719164] = Directory .. "/SailorPiece.lua",
        [8191429227] = Directory .. "/CutTrees.lua",
    },
    Premium = {
        [994732206] = Api .. "/0ae9fe4cf963e3a13d25eed0e2ce5940.lua",
        [10004244222] = Api .. "/63980a492928552d074ceee243a918d6.lua",
        [9792947201] = Api .. "/50e8e00251d97215e14313c0bb012058.lua",
        [10200395747] = Api .. "/65265b2869c03f57430ee45357d8c3f9.lua"
    }
}
local SCRIPT_ID = "0ae9fe4cf963e3a13d25eed0e2ce5940"
local FOLDER = "Quantum Onyx Hub"
local KEY_FILE = FOLDER .. "/Key.json"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local gameId = game.GameId

local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function Protect(gui)
    local env = (getgenv and getgenv()) or _G
    if env.HIDEUI then
        gui.Parent = env.HIDEUI
    elseif gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui.Parent = game:GetService("CoreGui")
    end
end

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Children" and k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Children then
        for _, c in ipairs(props.Children) do
            pcall(function() c.Parent = inst end)
        end
    end
    inst.Parent = props.Parent or parent
    return inst
end

local function CircleRipple(btn, mx, my)
    task.spawn(function()
        btn.ClipsDescendants = true
        local nx = mx - btn.AbsolutePosition.X
        local ny = my - btn.AbsolutePosition.Y
        local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.6
        local c = New("ImageLabel", {
            Name = "Ripple",
            Image = "rbxassetid://266543268",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0.82,
            BackgroundTransparency = 1,
            ZIndex = btn.ZIndex + 5,
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, nx, 0, ny),
        }, btn)
        Tween(c, { Size = UDim2.new(0, sz, 0, sz), Position = UDim2.new(0.5, -sz/2, 0.5, -sz/2) }, 0.45, Enum.EasingStyle.Quad)
        Tween(c, { ImageTransparency = 1 }, 0.45, Enum.EasingStyle.Linear)
        task.wait(0.46)
        c:Destroy()
    end)
end

local StarterGui = game:GetService("StarterGui")
local function Notify(title, desc, accent, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Quantum Onyx",
            Text = desc or "",
            Duration = duration or 5,
        })
    end)
end

local function ToTime(expire)
    if not expire or expire <= 0 then return "Lifetime" end
    local left = expire - os.time()
    if left < 0 then return "Expired" end
    local days = math.floor(left / 86400)
    local hours = math.floor((left % 86400) / 3600)
    local minutes = math.floor((left % 3600) / 60)
    if days > 0 then return string.format("%dd %dh", days, hours) end
    if hours > 0 then return string.format("%dh %dm", hours, minutes) end
    return string.format("%dm", minutes)
end

local function SaveKey(key)
    if not isfolder(FOLDER) then makefolder(FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({ key = key }))
end

local function LoadSavedKey()
    if isfolder(FOLDER) and isfile(KEY_FILE) then
        local ok, v = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_FILE))
        end)
        if ok and type(v) == "table" and v.key then return v.key end
    end
    return ""
end

local function ClearKey()
    if not isfolder(FOLDER) then makefolder(FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({}))
end

local function apply_script_key(key)
    getgenv().script_key = key
    getgenv().key = key
    if type(_G) == "table" then _G.script_key = key end
    if type(shared) == "table" then shared.script_key = key end
    pcall(function()
        if type(getrenv) == "function" then
            local env = getrenv()
            if type(env) == "table" then env.script_key = key end
        end
    end)
end

local function LoadScript(tier, key)
    local tbl = Scripts[tier]
    if not tbl then return end
    local url = tbl[gameId]
    if not url then
        warn("[Quantum Onyx] No " .. tier .. " script for GameId: " .. tostring(gameId))
        return
    end
    if tier == "Premium" and key then apply_script_key(key) end
    local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
    if not ok then warn("[Quantum Onyx] Error: " .. tostring(err)) end
end

-- The remainder of the supplied loader contains the large key-system UI,
-- Luarmor verification, saved-key handling, and authentication flow.
-- It is preserved in the original text supplied in the conversation.
