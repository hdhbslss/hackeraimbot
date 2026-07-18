-- // Rivals Hub - 最終版 | 無動畫 | FPS修復
if getgenv().RivalsHub then return end
getgenv().RivalsHub = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local IsMobile = UIS.TouchEnabled
local IsPC = not IsMobile

local _A = {
    SilentAim = true, ESP = true, Aimbot = false, Fly = false, FPSBoost = false,
    ShowFOV = true, FOV = 200, WallCheck = true, TeamCheck = true,
    SilentWallCheck = true, SilentTeamCheck = true,
    AimPart = "Head", AimbotPart = "Head", Smooth = 0.35,
    FlySpeed = 50, FlySmooth = 0.12,
}

local AimParts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
local _SID = HttpService:GenerateGUID():sub(1, 6)

local circle = Drawing.new("Circle")
circle.Color = Color3.fromRGB(255, 80, 80)
circle.Thickness = 1.2; circle.NumSides = 60
circle.Filled = false; circle.Visible = _A.ShowFOV; circle.Transparency = 0.4

local _T, _AT = nil, nil
local flyGyro, flyVel = nil, nil
local targetVel, currentVel = Vector3.zero, Vector3.zero
local _P, _FPS = false, false
local frame = nil

local _Orig = {
    Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    OutdoorAmbient = Lighting.OutdoorAmbient, Ambient = Lighting.Ambient,
    BloomSize = Lighting.BloomSize, BlurSize = Lighting.BlurSize,
}

local _AB, _FL, _FSL, _SAPB, _AAPB = nil, nil, nil, nil, nil
local _SWB, _STB, _AWB, _ATB, _FPSB = nil, nil, nil, nil, nil

local function _UA()
    if _AB then _AB.Text = _A.Aimbot and "🔫 Aimbot ✅" or "🔫 Aimbot"
        _AB.BackgroundColor3 = _A.Aimbot and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(35, 35, 42) end
end
local function _UF() if _FL then _FL.Text = "FOV: " .. _A.FOV end end
local function _UFS() if _FSL then _FSL.Text = "速度: " .. _A.FlySpeed end end
local function _USAP() if _SAPB then _SAPB.Text = "部位: " .. _A.AimPart end end
local function _UAAP() if _AAPB then _AAPB.Text = "部位: " .. _A.AimbotPart end end
local function _USW() if _SWB then _SWB.Text = _A.SilentWallCheck and "🧱 ✅" or "🧱 ❌"; _SWB.BackgroundColor3 = _A.SilentWallCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50) end end
local function _UST() if _STB then _STB.Text = _A.SilentTeamCheck and "👥 ✅" or "👥 ❌"; _STB.BackgroundColor3 = _A.SilentTeamCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50) end end
local function _UAW() if _AWB then _AWB.Text = _A.WallCheck and "🧱 ✅" or "🧱 ❌"; _AWB.BackgroundColor3 = _A.WallCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50) end end
local function _UAT() if _ATB then _ATB.Text = _A.TeamCheck and "👥 ✅" or "👥 ❌"; _ATB.BackgroundColor3 = _A.TeamCheck and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(150, 50, 50) end end
local function _UFPS() if _FPSB then _FPSB.Text = _A.FPSBoost and "⚡ FPS ✅" or "⚡ FPS"; _FPSB.BackgroundColor3 = _A.FPSBoost and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(35, 35, 42) end end

local function _CF()
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
    targetVel, currentVel = Vector3.zero, Vector3.zero
end

local function _FPSON()
    _FPS = true
    Lighting.GlobalShadows = false; Lighting.FogEnd = 999999; Lighting.FogStart = 0
    Lighting.Brightness = 3; Lighting.BloomSize = 0; Lighting.BlurSize = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    pcall(function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v.Name:find("Bloom") or v.Name:find("Blur") or v.Name:find("SunRays") or v.Name:find("Depth") then v:Destroy() end
        end
    end)
    for _, v in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
            if v:IsA("ParticleEmitter") then v:Destroy() end
            if v:IsA("BasePart") then v.CastShadow = false end
        end)
    end
end

local function _FPSOFF()
    _FPS = false
    Lighting.GlobalShadows = _Orig.GlobalShadows; Lighting.FogEnd = _Orig.FogEnd
    Lighting.FogStart = _Orig.FogStart; Lighting.Brightness = _Orig.Brightness
    Lighting.BloomSize = _Orig.BloomSize; Lighting.BlurSize = _Orig.BlurSize
    Lighting.OutdoorAmbient = _Orig.OutdoorAmbient; Lighting.Ambient = _Orig.Ambient
end

local function _IsTeam(p)
    if LP.Team and p.Team then return LP.Team == p.Team end
    return false
end

-- 主迴圈
RunService.RenderStepped:Connect(function()
    if _P then return end
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = _A.FOV; circle.Visible = _A.ShowFOV
    
    if _A.Aimbot and _AT then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, _AT.Position), _A.Smooth)
    end
    
    if _A.Fly and LP.Character then
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hrp and hum then
            if not flyGyro then
                flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyGyro.P = 30000; flyGyro.D = 1000; flyGyro.CFrame = hrp.CFrame; flyGyro.Parent = hrp
            end
            if not flyVel then
                flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyVel.P = 5000; flyVel.Velocity = Vector3.zero; flyVel.Parent = hrp
            end
            local md = Vector3.zero
            if IsPC then
                if UIS:IsKeyDown(Enum.KeyCode.W) then md += Vector3.new(0, 0, -1) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then md += Vector3.new(0, 0, 1) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then md += Vector3.new(-1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then md += Vector3.new(1, 0, 0) end
            else md = hum.MoveDirection end
            local hd = (Camera.CFrame.RightVector * md.X) + (Camera.CFrame.LookVector * md.Z)
            if hd.Magnitude > 0 then hd = hd.Unit end
            local vs = 0
            if IsPC then
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vs = 1
                elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then vs = -1 end
            else vs = md.Y end
            targetVel = (hd * _A.FlySpeed) + (Vector3.new(0, vs * _A.FlySpeed, 0))
            currentVel = currentVel:Lerp(targetVel, math.clamp(_A.FlySmooth, 0.01, 1))
            flyVel.Velocity = currentVel; flyGyro.CFrame = Camera.CFrame
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
        pcall(function()
            if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
            if v:IsA("ParticleEmitter") then v:Destroy() end
            if v:IsA("BasePart") then v.CastShadow = false end
        end)
    end
end)

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "UI_" .. _SID; gui.Parent = game:GetService("CoreGui"); gui.ResetOnSpawn = false

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 210, 0, 580); frame.Position = UDim2.new(0.5, -105, 0.5, -290)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true; frame.Visible = true
frame.Parent = gui

Instance.new("UIStroke", frame).Color = Color3.fromRGB(255, 60, 60)
Instance.new("UIStroke", frame).Thickness = 1.5; Instance.new("UIStroke", frame).Transparency = 0.4
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local tb = Instance.new("Frame", frame)
tb.Size = UDim2.new(1, 0, 0, 36); tb.BackgroundColor3 = Color3.fromRGB(20, 20, 28); tb.BorderSizePixel = 0
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

local ttl = Instance.new("TextLabel", tb)
ttl.Size = UDim2.new(1, 0, 1, 0); ttl.BackgroundTransparency = 1
ttl.Text = "🎯 Rivals Hub"; ttl.TextColor3 = Color3.fromRGB(255, 80, 80)
ttl.Font = Enum.Font.GothamBold; ttl.TextSize = 15

local function _NB(text, y, cb, w)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(w or 1, -16, 0, 30); btn.Position = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42); btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text; btn.Font = Enum.Font.Gotham; btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42) end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function _TB(text, y, s, ea)
    local btn = _NB(text, y)
    local function u()
        btn.Text = _A[s] and text .. " ✅" or text
        btn.BackgroundColor3 = _A[s] and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(35, 35, 42)
    end
    u()
    btn.MouseButton1Click:Connect(function() _A[s] = not _A[s]; u(); if ea then ea() end end)
    return btn
end

local y = 42

_TB("🎯 Silent Aim", y, "SilentAim"); y += 34
_SAPB = _NB("部位: " .. _A.AimPart, y, function()
    local idx = 1; for i, p in ipairs(AimParts) do if p == _A.AimPart then idx = i break end end
    idx = idx % #AimParts + 1; _A.AimPart = AimParts[idx]; _USAP()
end); y += 34

_SWB = _NB(_A.SilentWallCheck and "🧱 ✅" or "🧱 ❌", y, function() _A.SilentWallCheck = not _A.SilentWallCheck; _USW() end, 0.47)
_SWB.Position = UDim2.new(0, 8, 0, y)
_STB = _NB(_A.SilentTeamCheck and "👥 ✅" or "👥 ❌", y, function() _A.SilentTeamCheck = not _A.SilentTeamCheck; _UST() end, 0.47)
_STB.Position = UDim2.new(0.53, 0, 0, y); y += 34; y += 6

_AB = _TB("🔫 Aimbot", y, "Aimbot", function() if not _A.Aimbot then _AT = nil end end); y += 34
_AAPB = _NB("部位: " .. _A.AimbotPart, y, function()
    local idx = 1; for i, p in ipairs(AimParts) do if p == _A.AimbotPart then idx = i break end end
    idx = idx % #AimParts + 1; _A.AimbotPart = AimParts[idx]; _UAAP()
end); y += 34

_AWB = _NB(_A.WallCheck and "🧱 ✅" or "🧱 ❌", y, function() _A.WallCheck = not _A.WallCheck; _UAW() end, 0.47)
_AWB.Position = UDim2.new(0, 8, 0, y)
_ATB = _NB(_A.TeamCheck and "👥 ✅" or "👥 ❌", y, function() _A.TeamCheck = not _A.TeamCheck; _UAT() end, 0.47)
_ATB.Position = UDim2.new(0.53, 0, 0, y); y += 34; y += 6

_TB("👁️ ESP", y, "ESP"); y += 34
_TB("⭕ FOV圈", y, "ShowFOV"); y += 34

_FL = Instance.new("TextLabel", frame)
_FL.Size = UDim2.new(1, -16, 0, 20); _FL.Position = UDim2.new(0, 8, 0, y)
_FL.BackgroundTransparency = 1; _FL.Text = "FOV: " .. _A.FOV
_FL.TextColor3 = Color3.fromRGB(255, 180, 80)
_FL.Font = Enum.Font.GothamBold; _FL.TextSize = 12; y += 22

_NB("FOV +10", y, function() _A.FOV = math.min(_A.FOV + 10, 1000); _UF() end); y += 34
_NB("FOV -10", y, function() _A.FOV = math.max(_A.FOV - 10, 1); _UF() end); y += 34; y += 6

_FPSB = _NB(_A.FPSBoost and "⚡ FPS ✅" or "⚡ FPS", y, function()
    _A.FPSBoost = not _A.FPSBoost
    if _A.FPSBoost then _FPSON() else _FPSOFF() end
    _UFPS()
end); y += 34; y += 6

_TB("✈️ 飛行", y, "Fly", function() if not _A.Fly then _CF() end end); y += 34

_FSL = Instance.new("TextLabel", frame)
_FSL.Size = UDim2.new(1, -16, 0, 20); _FSL.Position = UDim2.new(0, 8, 0, y)
_FSL.BackgroundTransparency = 1; _FSL.Text = "速度: " .. _A.FlySpeed
_FSL.TextColor3 = Color3.fromRGB(100, 200, 255)
_FSL.Font = Enum.Font.GothamBold; _FSL.TextSize = 12; y += 22

_NB("速度 +10", y, function() _A.FlySpeed = math.min(_A.FlySpeed + 10, 500); _UFS() end); y += 34
_NB("速度 -10", y, function() _A.FlySpeed = math.max(_A.FlySpeed - 10, 10); _UFS() end); y += 34

if IsMobile then
    local tc, tlt = 0, 0
    UIS.TouchTapInWorld:Connect(function()
        local n = tick()
        if n - tlt < 0.4 then tc += 1 else tc = 1 end
        tlt = n
        if tc >= 3 then frame.Visible = not frame.Visible; tc = 0 end
    end)
end

if IsPC then
    UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Q then _A.Aimbot = not _A.Aimbot; _UA(); if not _A.Aimbot then _AT = nil end end
        if i.KeyCode == Enum.KeyCode.E then _A.Fly = not _A.Fly; if not _A.Fly then _CF() end end
        if i.KeyCode == Enum.KeyCode.RightShift then frame.Visible = not frame.Visible end
        if i.KeyCode == Enum.KeyCode.F2 then
            _P = true; _A.Aimbot = false; _A.SilentAim = false; _A.ESP = false; _A.Fly = false; _A.FPSBoost = false
            _FPSOFF(); _T = nil; _AT = nil; _CF(); circle.Visible = false
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local hl = p.Character:FindFirstChild("RivalsESP") if hl then hl:Destroy() end end end
            frame.Visible = false; _UA(); _UFPS()
        end
    end)
end

task.spawn(function()
    while task.wait(0.06) do
        if _P then continue end
        local st, at = nil, nil; local sd, ad = _A.FOV, _A.FOV
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            if (_A.SilentTeamCheck or _A.TeamCheck) and _IsTeam(p) then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local sa = _A.SilentAim and p.Character:FindFirstChild(_A.AimPart)
            local aa = _A.Aimbot and p.Character:FindFirstChild(_A.AimbotPart)
            local saSee, aaSee = true, true
            if _A.SilentWallCheck and sa then
                local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances = {LP.Character}
                local ray = workspace:Raycast(Camera.CFrame.Position, sa.Position - Camera.CFrame.Position, rp)
                if ray and not ray.Instance:IsDescendantOf(p.Character) then saSee = false end
            end
            if _A.WallCheck and aa then
                local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances = {LP.Character}
                local ray = workspace:Raycast(Camera.CFrame.Position, aa.Position - Camera.CFrame.Position, rp)
                if ray and not ray.Instance:IsDescendantOf(p.Character) then aaSee = false end
            end
            local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            if saSee and sa then
                local pos, on = Camera:WorldToViewportPoint(sa.Position)
                if on then local d = (Vector2.new(pos.X, pos.Y) - c).Magnitude
                    if d < sd then sd = d; st = sa end end
            end
            if aaSee and aa then
                local pos, on = Camera:WorldToViewportPoint(aa.Position)
                if on then local d = (Vector2.new(pos.X, pos.Y) - c).Magnitude
                    if d < ad then ad = d; at = aa end end
            end
        end
        _T, _AT = st, at
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _P then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            local hl = p.Character:FindFirstChild("RivalsESP")
            if _A.ESP then
                if not hl then
                    hl = Instance.new("Highlight"); hl.Name = "RivalsESP"
                    hl.FillColor = Color3.fromRGB(255, 60, 60); hl.OutlineColor = Color3.fromRGB(255, 60, 60)
                    hl.FillTransparency = 0.4; hl.OutlineTransparency = 0.2; hl.Parent = p.Character
                end
            elseif hl then hl:Destroy() end
        end
    end
end)

local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if not _P and _A.SilentAim and _T and getnamecallmethod() == "Raycast" then
            if args[1] and typeof(args[1]) == "Vector3" then
                local na = {args[1], (_T.Position - args[1]).Unit * 1000}
                for i = 3, #args do na[i] = args[i] end
                return old(self, unpack(na))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

print("✅ Rivals Hub 已載入")
print("⚡ FPS: " .. (_A.FPSBoost and "開啟" or "關閉"))
if IsPC then print("⌨️ Q=自瞄 | E=飛行 | F2=緊急") end
