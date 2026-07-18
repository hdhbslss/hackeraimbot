-- // Rivals Hub - 最終完整版 | PC & Mobile | 全自訂瞄準部位
if getgenv().RivalsHub then return end
getgenv().RivalsHub = true

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- // 平台偵測
local IsMobile = UIS.TouchEnabled
local IsPC = not IsMobile

-- // 設定
local _A = {
    SilentAim = true,
    ESP = true,
    Aimbot = false,
    Fly = false,
    ShowFOV = true,
    FOV = 200,
    WallCheck = true,
    AimPart = "Head",             -- 預設瞄頭
    AimbotPart = "Head",          -- 🔥 Aimbot獨立部位設定
    Smooth = 0.35,
    FlySpeed = 50,
    FlySmooth = 0.12,
    ESPColor = Color3.fromRGB(255, 60, 60)
}

-- // 可選部位
local AimParts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}

-- // 🛡️ 防Ban
local _AD = {
    PanicMode = true,
    HideUIOnPanic = true,
    RandomSessionID = HttpService:GenerateGUID(),
}

-- // FOV 圈
local circle = Drawing.new("Circle")
circle.Color = Color3.fromRGB(255, 80, 80)
circle.Thickness = 1.2
circle.NumSides = 60
circle.Filled = false
circle.Visible = _A.ShowFOV
circle.Transparency = 0.4

-- // 變數
local _T = nil          -- Silent Aim 目標
local _AT = nil         -- 🔥 Aimbot 目標（獨立）
local flyGyro = nil
local flyVel = nil
local targetVel = Vector3.zero
local currentVel = Vector3.zero
local _P = false
local frame = nil

-- // UI參考
local _AB = nil
local _FL = nil
local _FSL = nil
local _SAPB = nil    -- Silent Aim 部位按鈕
local _AAPB = nil    -- 🔥 Aimbot 部位按鈕

-- // 更新UI
local function _UA()
    if _AB then
        if _A.Aimbot then
            _AB.Text = "🔫 Aimbot ✅"
            _AB.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        else
            _AB.Text = "🔫 Aimbot"
            _AB.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        end
    end
end

local function _UF()
    if _FL then _FL.Text = "FOV: " .. _A.FOV end
end

local function _UFS()
    if _FSL then _FSL.Text = "速度: " .. _A.FlySpeed end
end

local function _USAP()
    if _SAPB then _SAPB.Text = "🎯 子彈追蹤: " .. _A.AimPart end
end

local function _UAAP()
    if _AAPB then _AAPB.Text = "🔫 自瞄部位: " .. _A.AimbotPart end
end

local function _CF()
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    targetVel = Vector3.zero
    currentVel = Vector3.zero
end

-- // 🛡️ 緊急模式
local function _PANIC()
    _P = true
    _A.Aimbot = false
    _A.SilentAim = false
    _A.ESP = false
    _A.Fly = false
    _A.ShowFOV = false
    _T = nil
    _AT = nil
    _CF()
    circle.Visible = false
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hl = p.Character:FindFirstChild("RivalsESP")
            if hl then hl:Destroy() end
        end
    end
    
    if _AD.HideUIOnPanic and frame then
        frame.Visible = false
    end
    
    _UA()
    print("🛑 已緊急關閉全部功能")
end

-- // 主迴圈
RunService.RenderStepped:Connect(function(dt)
    if _P then return end
    
    local size = Camera.ViewportSize
    circle.Position = Vector2.new(size.X/2, size.Y/2)
    circle.Radius = _A.FOV
    circle.Visible = _A.ShowFOV
    
    -- 🔥 Aimbot 用 AimbotPart，找獨立目標
    if _A.Aimbot and _AT then
        local lookAt = CFrame.lookAt(Camera.CFrame.Position, _AT.Position)
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, _A.Smooth)
    end
    
    if _A.Fly and IsPC and LP.Character then
        local char = LP.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if hrp and hum then
            if not flyGyro then
                flyGyro = Instance.new("BodyGyro")
                flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyGyro.P = 30000
                flyGyro.D = 1000
                flyGyro.CFrame = hrp.CFrame
                flyGyro.Parent = hrp
            end
            
            if not flyVel then
                flyVel = Instance.new("BodyVelocity")
                flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyVel.P = 5000
                flyVel.Velocity = Vector3.zero
                flyVel.Parent = hrp
            end
            
            local moveDir = hum.MoveDirection
            local camForward = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector
            
            local horizontalDir = (camRight * moveDir.X) + (camForward * moveDir.Z)
            if horizontalDir.Magnitude > 0 then
                horizontalDir = horizontalDir.Unit
            end
            
            local verticalSpeed = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                verticalSpeed = 1
            elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then
                verticalSpeed = -1
            end
            
            targetVel = (horizontalDir * _A.FlySpeed) + (Vector3.new(0, verticalSpeed * _A.FlySpeed, 0))
            
            local smooth = math.clamp(_A.FlySmooth, 0.01, 1)
            currentVel = currentVel:Lerp(targetVel, smooth)
            
            flyVel.Velocity = currentVel
            flyGyro.CFrame = Camera.CFrame
        end
    else
        _CF()
    end
end)

-- // 🌸 美化UI
local gui = Instance.new("ScreenGui")
gui.Name = "UI_" .. _AD.RandomSessionID:sub(1, 6)
gui.Parent = game:GetService("CoreGui")
gui.ResetOnSpawn = false

frame = Instance.new("Frame")
frame.Size = IsMobile and UDim2.new(0, 195, 0, 560) or UDim2.new(0, 215, 0, 600)
frame.Position = IsMobile and UDim2.new(0, 10, 0.5, -280) or UDim2.new(0.5, -107, 0.5, -300)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true
frame.Parent = gui

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 60, 60)
stroke.Thickness = 1
stroke.Transparency = 0.5

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- 頂部標題欄
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "🎯 Rivals Hub"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = IsMobile and 15 or 17

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 13)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

-- // 按鈕函數
local function _NB(text, y, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = IsMobile and 12 or 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    end)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function _TB(text, y, setting, extraAction)
    local btn = _NB(text, y)
    
    local function update()
        if _A[setting] then
            btn.Text = text .. " ✅"
            btn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        else
            btn.Text = text
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        end
    end
    update()
    
    btn.MouseButton1Click:Connect(function()
        _A[setting] = not _A[setting]
        update()
        if extraAction then extraAction() end
    end)
    
    return btn
end

-- // 選單項目
local y = 50

-- Silent Aim
_TB("🎯 Silent Aim", y, "SilentAim")
y += 37

-- 🔥 Silent Aim 部位選擇
_SAPB = _NB("🎯 子彈追蹤: " .. _A.AimPart, y, function()
    local idx = 1
    for i, part in ipairs(AimParts) do
        if part == _A.AimPart then idx = i break end
    end
    idx = idx % #AimParts + 1
    _A.AimPart = AimParts[idx]
    _USAP()
end)
y += 37

-- 分隔
local div1 = Instance.new("Frame", frame)
div1.Size = UDim2.new(1, -20, 0, 1)
div1.Position = UDim2.new(0, 10, 0, y)
div1.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
div1.BorderSizePixel = 0
y += 10

-- Aimbot
_AB = _TB("🔫 Aimbot", y, "Aimbot", function()
    if not _A.Aimbot then _AT = nil end
end)
y += 37

-- 🔥 Aimbot 部位選擇
_AAPB = _NB("🔫 自瞄部位: " .. _A.AimbotPart, y, function()
    local idx = 1
    for i, part in ipairs(AimParts) do
        if part == _A.AimbotPart then idx = i break end
    end
    idx = idx % #AimParts + 1
    _A.AimbotPart = AimParts[idx]
    _UAAP()
end)
y += 37

-- 分隔
local div2 = Instance.new("Frame", frame)
div2.Size = UDim2.new(1, -20, 0, 1)
div2.Position = UDim2.new(0, 10, 0, y)
div2.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
div2.BorderSizePixel = 0
y += 10

-- ESP
_TB("👁️ ESP 透視", y, "ESP")
y += 37

-- 穿牆檢查
_TB("🧱 穿牆檢查", y, "WallCheck")
y += 37

-- FOV圈
_TB("⭕ 顯示FOV圈", y, "ShowFOV")
y += 37

-- FOV調整
_FL = Instance.new("TextLabel", frame)
_FL.Size = UDim2.new(1, -20, 0, 22)
_FL.Position = UDim2.new(0, 10, 0, y)
_FL.BackgroundTransparency = 1
_FL.Text = "FOV: " .. _A.FOV
_FL.TextColor3 = Color3.fromRGB(255, 180, 80)
_FL.Font = Enum.Font.GothamBold
_FL.TextSize = IsMobile and 12 or 13
y += 25

_NB("FOV +10", y, function()
    _A.FOV = math.min(_A.FOV + 10, 1000)
    _UF()
end)
y += 37

_NB("FOV -10", y, function()
    _A.FOV = math.max(_A.FOV - 10, 1)
    _UF()
end)
y += 37

_NB("重置FOV (200)", y, function()
    _A.FOV = 200
    _UF()
end)
y += 37

-- 飛行（僅PC）
if IsPC then
    local div3 = Instance.new("Frame", frame)
    div3.Size = UDim2.new(1, -20, 0, 1)
    div3.Position = UDim2.new(0, 10, 0, y)
    div3.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    div3.BorderSizePixel = 0
    y += 10
    
    _TB("✈️ 飛行", y, "Fly", function()
        if not _A.Fly then _CF() end
    end)
    y += 37
    
    _FSL = Instance.new("TextLabel", frame)
    _FSL.Size = UDim2.new(1, -20, 0, 22)
    _FSL.Position = UDim2.new(0, 10, 0, y)
    _FSL.BackgroundTransparency = 1
    _FSL.Text = "速度: " .. _A.FlySpeed
    _FSL.TextColor3 = Color3.fromRGB(100, 200, 255)
    _FSL.Font = Enum.Font.GothamBold
    _FSL.TextSize = IsMobile and 12 or 13
    y += 25
    
    _NB("速度 +10", y, function()
        _A.FlySpeed = math.min(_A.FlySpeed + 10, 500)
        _UFS()
    end)
    y += 37
    
    _NB("速度 -10", y, function()
        _A.FlySpeed = math.max(_A.FlySpeed - 10, 10)
        _UFS()
    end)
    y += 37
end

-- // 手機
if IsMobile then
    local _TC = 0
    local _TLT = 0
    
    UIS.TouchTapInWorld:Connect(function()
        local now = tick()
        if now - _TLT < 0.4 then
            _TC += 1
        else
            _TC = 1
        end
        _TLT = now
        
        if _TC >= 3 then
            frame.Visible = not frame.Visible
            _TC = 0
        end
    end)
end

-- // PC快捷鍵
if IsPC then
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        
        if input.KeyCode == Enum.KeyCode.Q then
            _A.Aimbot = not _A.Aimbot
            _UA()
            if not _A.Aimbot then _AT = nil end
        end
        
        if input.KeyCode == Enum.KeyCode.E then
            _A.Fly = not _A.Fly
            if not _A.Fly then _CF() end
        end
        
        if input.KeyCode == Enum.KeyCode.RightShift then
            frame.Visible = not frame.Visible
        end
        
        -- 🛡️ 緊急按鈕
        if input.KeyCode == Enum.KeyCode.F2 then
            _PANIC()
        end
    end)
end

-- // 🔥 目標尋找（雙目標：Silent Aim + Aimbot 各自找）
task.spawn(function()
    while task.wait(0.06) do
        if _P then continue end
        
        local silentTarget = nil
        local aimbotTarget = nil
        local silentDist = _A.FOV
        local aimbotDist = _A.FOV
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            
            -- 找 Silent Aim 部位
            local saPart = p.Character:FindFirstChild(_A.AimPart)
            -- 找 Aimbot 部位
            local aaPart = p.Character:FindFirstChild(_A.AimbotPart)
            
            if not saPart and not aaPart then continue end
            
            -- 穿牆檢查（共用）
            local canSee = true
            if _A.WallCheck then
                local checkPart = saPart or aaPart
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Blacklist
                rp.FilterDescendantsInstances = {LP.Character}
                
                local origin = Camera.CFrame.Position
                local dir = checkPart.Position - origin
                local ray = workspace:Raycast(origin, dir, rp)
                
                if ray and not ray.Instance:IsDescendantOf(p.Character) then
                    canSee = false
                end
            end
            
            if canSee then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                
                -- Silent Aim 目標
                if _A.SilentAim and saPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(saPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < silentDist then
                            silentDist = dist
                            silentTarget = saPart
                        end
                    end
                end
                
                -- Aimbot 目標
                if _A.Aimbot and aaPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(aaPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < aimbotDist then
                            aimbotDist = dist
                            aimbotTarget = aaPart
                        end
                    end
                end
            end
        end
        
        _T = silentTarget
        _AT = aimbotTarget
    end
end)

-- // ESP
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
                    hl.FillColor = _A.ESPColor
                    hl.OutlineColor = _A.ESPColor
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0.2
                    hl.Parent = p.Character
                end
            elseif hl then
                hl:Destroy()
            end
        end
    end
end)

-- // Silent Aim（用 AimPart）
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if not _P and _A.SilentAim and _T and method == "Raycast" then
            if args[1] and typeof(args[1]) == "Vector3" then
                local origin = args[1]
                local direction = (_T.Position - origin).Unit * 1000
                return old(self, origin, direction, select(3, ...))
            end
        end
        
        return old(self, ...)
    end)
    
    setreadonly(mt, true)
end

-- // 載入提示
print("✅ Rivals Hub 已載入 - " .. (IsMobile and "📱手機版" or "🖥️PC版"))
print("🎯 子彈追蹤: " .. _A.AimPart)
print("🔫 自瞄部位: " .. _A.AimbotPart)
print("👁️ ESP: " .. (_A.ESP and "開啟" or "關閉"))
print("⭕ FOV: " .. _A.FOV)
if IsPC then
    print("✈️ 飛行: " .. (_A.Fly and "開啟" or "關閉"))
    print("⌨️ Q=自瞄 | E=飛行 | RShift=選單 | F2=緊急關閉")
end
print("⚠️ 使用風險自負！")
