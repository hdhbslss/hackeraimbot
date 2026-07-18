-- // Rivals Hub - 旗艦版 | 完整整合
if getgenv().RivalsHub then return end
getgenv().RivalsHub = true

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- // 平台
local IsMobile = UIS.TouchEnabled
local IsPC = not IsMobile

-- // 保存設定
local function SaveSettings()
    local data = HttpService:JSONEncode(_A)
    if IsPC then writefile("RivalsHub_Settings.json", data)
    else getgenv().RivalsHubSettings = _A end
end

local function LoadSettings()
    local success, data = pcall(function()
        if IsPC then return readfile("RivalsHub_Settings.json") end
    end)
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do _A[k] = v end
        return true
    end
    if getgenv().RivalsHubSettings then
        for k, v in pairs(getgenv().RivalsHubSettings) do _A[k] = v end
        return true
    end
    return false
end

-- // 設定
local _A = {
    SilentAim = true, ESP = true, Aimbot = false, Fly = false, FPSBoost = false,
    ShowFOV = true, FOV = 200, WallCheck = true, TeamCheck = true,
    SilentWallCheck = true, SilentTeamCheck = true,
    AimPart = "Head", AimbotPart = "Head", Smooth = 0.35,
    FlySpeed = 50, FlySmooth = 0.12,
    ESPColor = Color3.fromRGB(255, 60, 60)
}

LoadSettings()

local AimParts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}

-- // 防Ban
local _AD = {
    RandomSessionID = HttpService:GenerateGUID(),
    PanicMode = true, HideUIOnPanic = true,
}

-- // FOV圈
local circle = Drawing.new("Circle")
circle.Color = Color3.fromRGB(255, 80, 80)
circle.Thickness = 1.2; circle.NumSides = 60
circle.Filled = false; circle.Visible = _A.ShowFOV; circle.Transparency = 0.4

-- // 變數
local _T, _AT = nil, nil
local flyGyro, flyVel = nil, nil
local targetVel, currentVel = Vector3.zero, Vector3.zero
local _P, _FPS = false, false
local frame = nil

-- // 🔥 保存原始Lighting設定
local _OrigLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    BloomSize = Lighting.BloomSize,
    BlurSize = Lighting.BlurSize,
    ClockTime = Lighting.ClockTime,
}

-- // UI參考
local _AB, _FL, _FSL, _SAPB, _AAPB = nil, nil, nil, nil, nil
local _SWB, _STB, _AWB, _ATB = nil, nil, nil, nil
local _FPSB = nil

-- // 更新UI
local function _UA()
    if _AB then
        _AB.Text = _A.Aimbot and "🔫 Aimbot ✅" or "🔫 Aimbot"
        _AB.BackgroundColor3 = _A.Aimbot and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(35, 35, 42)
    end
end
local function _UF() if _FL then _FL.Text = "FOV: " .. _A.FOV end end
local function _UFS() if _FSL then _FSL.Text = "速度: " .. _A.FlySpeed end end
local function _USAP() if _SAPB then _SAPB.Text = "部位: " .. _A.AimPart end end
local function _UAAP() if _AAPB then _AAPB.Text = "部位: " .. _A.AimbotPart end end

local function _USW()
    if _SWB then
        _SWB.Text = _A.SilentWallCheck and "🧱 ✅" or "🧱 ❌"
        _SWB.BackgroundColor3 = _A.SilentWallCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50)
    end
end
local function _UST()
    if _STB then
        _STB.Text = _A.SilentTeamCheck and "👥 ✅" or "👥 ❌"
        _STB.BackgroundColor3 = _A.SilentTeamCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50)
    end
end
local function _UAW()
    if _AWB then
        _AWB.Text = _A.WallCheck and "🧱 ✅" or "🧱 ❌"
        _AWB.BackgroundColor3 = _A.WallCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50)
    end
end
local function _UAT()
    if _ATB then
        _ATB.Text = _A.TeamCheck and "👥 ✅" or "👥 ❌"
        _ATB.BackgroundColor3 = _A.TeamCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50)
    end
end
local function _UFPS()
    if _FPSB then
        _FPSB.Text = _A.FPSBoost and "⚡ FPS ✅" or "⚡ FPS"
        _FPSB.BackgroundColor3 = _A.FPSBoost and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(35, 35, 42)
    end
end

local function _CF()
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    targetVel, currentVel = Vector3.zero, Vector3.zero
end

-- // 🛡️ 緊急
local function _PANIC()
    _P = true
    _A.Aimbot, _A.SilentAim, _A.ESP = false, false, false
    _A.Fly, _A.ShowFOV = false, false
    if _A.FPSBoost then
        _A.FPSBoost = false
        _FPSOFF()
    end
    _T, _AT = nil, nil; _CF(); circle.Visible = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hl = p.Character:FindFirstChild("RivalsESP")
            if hl then hl:Destroy() end
        end
    end
    if _AD.HideUIOnPanic and frame then frame.Visible = false end
    _UA(); _UFPS()
    SaveSettings()
end

-- // 🔥 FPS ON
local function _FPSON()
    _FPS = true
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then v:Destroy() end
    end
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    Lighting.FogEnd = 999999; Lighting.FogStart = 0
    Lighting.Brightness = 2.5; Lighting.GlobalShadows = false
    Lighting.BloomSize = 0; Lighting.BlurSize = 0
    pcall(function()
        if Lighting:FindFirstChild("Bloom") then Lighting.Bloom:Destroy() end
        if Lighting:FindFirstChild("Blur") then Lighting.Blur:Destroy() end
        if Lighting:FindFirstChild("SunRays") then Lighting.SunRays:Destroy() end
        if Lighting:FindFirstChild("DepthOfField") then Lighting.DepthOfField:Destroy() end
    end)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Texture") or v:IsA("Decal") then pcall(function() v:Destroy() end) end
        if v:IsA("ParticleEmitter") then pcall(function() v:Destroy() end) end
        if v:IsA("BasePart") then v.CastShadow = false end
    end
    _UFPS()
end

-- // 🔥 FPS OFF（恢復正常）
local function _FPSOFF()
    _FPS = false
    Lighting.Brightness = _OrigLighting.Brightness
    Lighting.GlobalShadows = _OrigLighting.GlobalShadows
    Lighting.FogEnd = _OrigLighting.FogEnd
    Lighting.FogStart = _OrigLighting.FogStart
    Lighting.OutdoorAmbient = _OrigLighting.OutdoorAmbient
    Lighting.Ambient = _OrigLighting.Ambient
    Lighting.BloomSize = _OrigLighting.BloomSize
    Lighting.BlurSize = _OrigLighting.BlurSize
    _UFPS()
end

-- // 隊伍檢查
local function _IsTeam(player)
    if LP.Team and player.Team then
        return LP.Team == player.Team
    end
    return false
end

-- // 🔥 開場動畫
local function PlayIntroAnimation()
    local ag = Instance.new("ScreenGui", game:GetService("CoreGui"))
    ag.Name = "Intro"; ag.ResetOnSpawn = false
    
    local bg = Instance.new("Frame", ag)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0
    
    local logo = Instance.new("TextLabel", bg)
    logo.Size = UDim2.new(0, 300, 0, 60)
    logo.Position = UDim2.new(0.5, -150, 0.5, -30)
    logo.BackgroundTransparency = 1
    logo.Text = "🎯 RIVALS HUB"
    logo.TextColor3 = Color3.fromRGB(255, 60, 60)
    logo.Font = Enum.Font.GothamBlack; logo.TextSize = 36
    logo.TextTransparency = 1
    
    local sub = Instance.new("TextLabel", bg)
    sub.Size = UDim2.new(0, 300, 0, 30)
    sub.Position = UDim2.new(0.5, -150, 0.5, 30)
    sub.BackgroundTransparency = 1
    sub.Text = "旗艦版 | 防Ban | 自動保存"
    sub.TextColor3 = Color3.fromRGB(255, 100, 100)
    sub.Font = Enum.Font.GothamBold; sub.TextSize = 16
    sub.TextTransparency = 1
    
    local ti = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(bg, ti, {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(logo, ti, {TextTransparency = 0}):Play()
    TweenService:Create(sub, ti, {TextTransparency = 0}):Play()
    
    task.delay(2, function()
        local fo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(logo, fo, {TextTransparency = 1}):Play()
        TweenService:Create(sub, fo, {TextTransparency = 1}):Play()
        TweenService:Create(bg, fo, {BackgroundTransparency = 1}):Play()
        task.delay(0.6, function() ag:Destroy() end)
    end)
end

PlayIntroAnimation()
task.wait(0.5)

-- // 主迴圈
RunService.RenderStepped:Connect(function(dt)
    if _P then return end
    
    local size = Camera.ViewportSize
    circle.Position = Vector2.new(size.X/2, size.Y/2)
    circle.Radius = _A.FOV
    circle.Visible = _A.ShowFOV
    
    if _A.Aimbot and _AT then
        local lookAt = CFrame.lookAt(Camera.CFrame.Position, _AT.Position)
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, _A.Smooth)
    end
    
    if _FPS then
        Workspace.StreamingMinRadius = 32
        Workspace.StreamingTargetRadius = 32
    end
    
    if _A.Fly and LP.Character then
        local char = LP.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if hrp and hum then
            if not flyGyro then
                flyGyro = Instance.new("BodyGyro")
                flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyGyro.P = 30000; flyGyro.D = 1000
                flyGyro.CFrame = hrp.CFrame; flyGyro.Parent = hrp
            end
            if not flyVel then
                flyVel = Instance.new("BodyVelocity")
                flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyVel.P = 5000; flyVel.Velocity = Vector3.zero; flyVel.Parent = hrp
            end
            
            local moveDir = Vector3.zero
            if IsPC then
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0, 0, -1) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0, 0, 1) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1, 0, 0) end
            else
                moveDir = hum.MoveDirection
            end
            
            local horizontalDir = (Camera.CFrame.RightVector * moveDir.X) + (Camera.CFrame.LookVector * moveDir.Z)
            if horizontalDir.Magnitude > 0 then horizontalDir = horizontalDir.Unit end
            
            local vSpeed = 0
            if IsPC then
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vSpeed = 1
                elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then vSpeed = -1 end
            else
                vSpeed = moveDir.Y
            end
            
            targetVel = (horizontalDir * _A.FlySpeed) + (Vector3.new(0, vSpeed * _A.FlySpeed, 0))
            currentVel = currentVel:Lerp(targetVel, math.clamp(_A.FlySmooth, 0.01, 1))
            flyVel.Velocity = currentVel
            flyGyro.CFrame = Camera.CFrame
            if IsMobile then hum.PlatformStand = true end
        end
    else
        _CF()
        if IsMobile and LP.Character then
            local hum = LP.Character:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end
end)

Workspace.DescendantAdded:Connect(function(v)
    if _FPS then
        if v:IsA("Texture") or v:IsA("Decal") then pcall(function() v:Destroy() end) end
        if v:IsA("ParticleEmitter") then pcall(function() v:Destroy() end) end
        if v:IsA("BasePart") then v.CastShadow = false end
    end
end)

-- // 🌸 UI
local gui = Instance.new("ScreenGui")
gui.Name = "UI_" .. _AD.RandomSessionID:sub(1, 6)
gui.Parent = game:GetService("CoreGui"); gui.ResetOnSpawn = false

frame = Instance.new("Frame")
frame.Size = IsMobile and UDim2.new(0, 200, 0, 680) or UDim2.new(0, 220, 0, 700)
frame.Position = IsMobile and UDim2.new(0, 10, 0.5, -340) or UDim2.new(0.5, -110, 0.5, -350)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true; frame.Visible = true
frame.Parent = gui

Instance.new("UIStroke", frame).Color = Color3.fromRGB(255, 60, 60)
Instance.new("UIStroke", frame).Thickness = 1.5
Instance.new("UIStroke", frame).Transparency = 0.4
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28); topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0); title.BackgroundTransparency = 1
title.Text = "🎯 Rivals Hub"; title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.Font = Enum.Font.GothamBold; title.TextSize = IsMobile and 15 or 17

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 26, 0, 26); closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 13)
closeBtn.MouseButton1Click:Connect(function() SaveSettings(); frame.Visible = false end)

local function _NB(text, y, callback, w)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(w or 1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    btn.TextColor3 = Color3.new(1, 1, 1); btn.Text = text
    btn.Font = Enum.Font.Gotham; btn.TextSize = IsMobile and 11 or 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42) end)
    btn.MouseButton1Click:Connect(function() callback(); SaveSettings() end)
    return btn
end

local function _TB(text, y, setting, extraAction)
    local btn = _NB(text, y)
    local function u()
        btn.Text = _A[setting] and text .. " ✅" or text
        btn.BackgroundColor3 = _A[setting] and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(35, 35, 42)
    end
    u()
    btn.MouseButton1Click:Connect(function() _A[setting] = not _A[setting]; u(); if extraAction then extraAction() end; SaveSettings() end)
    return btn
end

local y = 50

-- 子彈追蹤
local l1 = Instance.new("TextLabel", frame)
l1.Size = UDim2.new(1, -20, 0, 22); l1.Position = UDim2.new(0, 10, 0, y)
l1.BackgroundTransparency = 1; l1.Text = "🎯 子彈追蹤"
l1.TextColor3 = Color3.fromRGB(255, 150, 50)
l1.Font = Enum.Font.GothamBold; l1.TextSize = IsMobile and 13 or 14; y += 25

_TB("Silent Aim", y, "SilentAim"); y += 37

_SAPB = _NB("部位: " .. _A.AimPart, y, function()
    local idx = 1
    for i, p in ipairs(AimParts) do if p == _A.AimPart then idx = i break end end
    idx = idx % #AimParts + 1; _A.AimPart = AimParts[idx]; _USAP()
end); y += 37

_SWB = _NB(_A.SilentWallCheck and "🧱 ✅" or "🧱 ❌", y, function()
    _A.SilentWallCheck = not _A.SilentWallCheck; _USW()
end, 0.47); _SWB.Position = UDim2.new(0, 10, 0, y)

_STB = _NB(_A.SilentTeamCheck and "👥 ✅" or "👥 ❌", y, function()
    _A.SilentTeamCheck = not _A.SilentTeamCheck; _UST()
end, 0.47); _STB.Position = UDim2.new(0.53, 0, 0, y); y += 37

local d1 = Instance.new("Frame", frame)
d1.Size = UDim2.new(1, -20, 0, 1); d1.Position = UDim2.new(0, 10, 0, y)
d1.BackgroundColor3 = Color3.fromRGB(60, 60, 70); d1.BorderSizePixel = 0; y += 10

-- Aimbot
local l2 = Instance.new("TextLabel", frame)
l2.Size = UDim2.new(1, -20, 0, 22); l2.Position = UDim2.new(0, 10, 0, y)
l2.BackgroundTransparency = 1; l2.Text = "🔫 Aimbot 自瞄"
l2.TextColor3 = Color3.fromRGB(255, 150, 50)
l2.Font = Enum.Font.GothamBold; l2.TextSize = IsMobile and 13 or 14; y += 25

_AB = _TB("Aimbot", y, "Aimbot", function() if not _A.Aimbot then _AT = nil end end); y += 37

_AAPB = _NB("部位: " .. _A.AimbotPart, y, function()
    local idx = 1
    for i, p in ipairs(AimParts) do if p == _A.AimbotPart then idx = i break end end
    idx = idx % #AimParts + 1; _A.AimbotPart = AimParts[idx]; _UAAP()
end); y += 37

_AWB = _NB(_A.WallCheck and "🧱 ✅" or "🧱 ❌", y, function()
    _A.WallCheck = not _A.WallCheck; _UAW()
end, 0.47); _AWB.Position = UDim2.new(0, 10, 0, y)

_ATB = _NB(_A.TeamCheck and "👥 ✅" or "👥 ❌", y, function()
    _A.TeamCheck = not _A.TeamCheck; _UAT()
end, 0.47); _ATB.Position = UDim2.new(0.53, 0, 0, y); y += 37

local d2 = Instance.new("Frame", frame)
d2.Size = UDim2.new(1, -20, 0, 1); d2.Position = UDim2.new(0, 10, 0, y)
d2.BackgroundColor3 = Color3.fromRGB(60, 60, 70); d2.BorderSizePixel = 0; y += 10

-- ESP
_TB("👁️ ESP 透視", y, "ESP"); y += 37
_TB("⭕ 顯示FOV圈", y, "ShowFOV"); y += 37

-- FOV
_FL = Instance.new("TextLabel", frame)
_FL.Size = UDim2.new(1, -20, 0, 22); _FL.Position = UDim2.new(0, 10, 0, y)
_FL.BackgroundTransparency = 1; _FL.Text = "FOV: " .. _A.FOV
_FL.TextColor3 = Color3.fromRGB(255, 180, 80)
_FL.Font = Enum.Font.GothamBold; _FL.TextSize = IsMobile and 12 or 13; y += 25

_NB("FOV +10", y, function() _A.FOV = math.min(_A.FOV + 10, 1000); _UF() end); y += 37
_NB("FOV -10", y, function() _A.FOV = math.max(_A.FOV - 10, 1); _UF() end); y += 37
_NB("重置FOV", y, function() _A.FOV = 200; _UF() end); y += 37

local d3 = Instance.new("Frame", frame)
d3.Size = UDim2.new(1, -20, 0, 1); d3.Position = UDim2.new(0, 10, 0, y)
d3.BackgroundColor3 = Color3.fromRGB(60, 60, 70); d3.BorderSizePixel = 0; y += 10

-- 🔥 FPS按鈕（開關）
_FPSB = _NB(_A.FPSBoost and "⚡ FPS ✅" or "⚡ FPS", y, function()
    _A.FPSBoost = not _A.FPSBoost
    if _A.FPSBoost then _FPSON() else _FPSOFF() end
end); y += 37

local d4 = Instance.new("Frame", frame)
d4.Size = UDim2.new(1, -20, 0, 1); d4.Position = UDim2.new(0, 10, 0, y)
d4.BackgroundColor3 = Color3.fromRGB(60, 60, 70); d4.BorderSizePixel = 0; y += 10

-- 飛行
_TB("✈️ 飛行", y, "Fly", function() if not _A.Fly then _CF() end end); y += 37

_FSL = Instance.new("TextLabel", frame)
_FSL.Size = UDim2.new(1, -20, 0, 22); _FSL.Position = UDim2.new(0, 10, 0, y)
_FSL.BackgroundTransparency = 1; _FSL.Text = "速度: " .. _A.FlySpeed
_FSL.TextColor3 = Color3.fromRGB(100, 200, 255)
_FSL.Font = Enum.Font.GothamBold; _FSL.TextSize = IsMobile and 12 or 13; y += 25

_NB("速度 +10", y, function() _A.FlySpeed = math.min(_A.FlySpeed + 10, 500); _UFS() end); y += 37
_NB("速度 -10", y, function() _A.FlySpeed = math.max(_A.FlySpeed - 10, 10); _UFS() end); y += 37

-- 手機
if IsMobile then
    local _TC, _TLT = 0, 0
    UIS.TouchTapInWorld:Connect(function()
        local now = tick()
        if now - _TLT < 0.4 then _TC += 1 else _TC = 1 end
        _TLT = now
        if _TC >= 3 then frame.Visible = not frame.Visible; _TC = 0 end
    end)
end

-- PC快捷鍵
if IsPC then
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Q then _A.Aimbot = not _A.Aimbot; _UA(); if not _A.Aimbot then _AT = nil end; SaveSettings() end
        if input.KeyCode == Enum.KeyCode.E then _A.Fly = not _A.Fly; if not _A.Fly then _CF() end; SaveSettings() end
        if input.KeyCode == Enum.KeyCode.RightShift then frame.Visible = not frame.Visible end
        if input.KeyCode == Enum.KeyCode.F2 then _PANIC() end
    end)
end

-- 目標尋找
task.spawn(function()
    while task.wait(0.06) do
        if _P then continue end
        local st, at = nil, nil
        local sd, ad = _A.FOV, _A.FOV
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            
            if (_A.SilentTeamCheck or _A.TeamCheck) and _IsTeam(p) then continue end
            
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            
            local sa = _A.SilentAim and p.Character:FindFirstChild(_A.AimPart)
            local aa = _A.Aimbot and p.Character:FindFirstChild(_A.AimbotPart)
            
            local saSee = true
            if _A.SilentWallCheck and sa then
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Blacklist
                rp.FilterDescendantsInstances = {LP.Character}
                local ray = workspace:Raycast(Camera.CFrame.Position, sa.Position - Camera.CFrame.Position, rp)
                if ray and not ray.Instance:IsDescendantOf(p.Character) then saSee = false end
            end
            
            local aaSee = true
            if _A.WallCheck and aa then
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Blacklist
                rp.FilterDescendantsInstances = {LP.Character}
                local ray = workspace:Raycast(Camera.CFrame.Position, aa.Position - Camera.CFrame.Position, rp)
                if ray and not ray.Instance:IsDescendantOf(p.Character) then aaSee = false end
            end
            
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            
            if saSee and sa then
                local pos, on = Camera:WorldToViewportPoint(sa.Position)
                if on then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < sd then sd = d; st = sa end
                end
            end
            
            if aaSee and aa then
                local pos, on = Camera:WorldToViewportPoint(aa.Position)
                if on then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < ad then ad = d; at = aa end
                end
            end
        end
        
        _T, _AT = st, at
    end
end)

-- ESP
task.spawn(function()
    while task.wait(0.5) do
        if _P then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            local hl = p.Character:FindFirstChild("RivalsESP")
            if _A.ESP then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "RivalsESP"
                    hl.FillColor = _A.ESPColor; hl.OutlineColor = _A.ESPColor
                    hl.FillTransparency = 0.4; hl.OutlineTransparency = 0.2
                    hl.Parent = p.Character
                end
            elseif hl then hl:Destroy() end
        end
    end
end)

-- Silent Aim
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if not _P and _A.SilentAim and _T and getnamecallmethod() == "Raycast" then
            if args[1] and typeof(args[1]) == "Vector3" then
                local newArgs = {args[1], (_T.Position - args[1]).Unit * 1000}
                for i = 3, #args do newArgs[i] = args[i] end
                return old(self, unpack(newArgs))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

print("✅ Rivals Hub 旗艦版已載入")
print("🎬 開場動畫已完成")
print("📂 設定已自動載入")
print("🛡️ 防Ban系統已啟用")
print("⚡ FPS開關已就緒")
if IsPC then print("⌨️ Q=自瞄 | E=飛行 | F2=緊急") end
