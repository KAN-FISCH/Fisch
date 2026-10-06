local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local antiAfkConnection = nil
local flyKeyDown = nil
local flyKeyUp = nil
local FLYING = false
local flySpeed = 1
local QEfly = true
local function SetAntiAFK(state)
    if state then
        pcall(function()
            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then conn:Disable()
                elseif conn.Disconnect then conn:Disconnect() end
            end
        end)
    end
end
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end
local function SetFly(enabled)
    FLYING = enabled
    if not enabled then
        if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown = nil end
        if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp = nil end
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
                local root = getRoot(char)
                if root then
                    local bg = root:FindFirstChildOfClass("BodyGyro")
                    if bg then bg:Destroy() end
                    local bv = root:FindFirstChildOfClass("BodyVelocity")
                    if bv then bv:Destroy() end
                end
            end
        end)
        return
    end
    task.spawn(function()
        repeat task.wait() until LocalPlayer.Character and getRoot(LocalPlayer.Character) and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if flyKeyDown then flyKeyDown:Disconnect() end
        if flyKeyUp then flyKeyUp:Disconnect() end
        local T = getRoot(LocalPlayer.Character)
        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0
        local BG = Instance.new('BodyGyro')
        local BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.cframe = T.CFrame
        BV.velocity = Vector3.new(0, 0, 0)
        BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            repeat task.wait()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass('Humanoid')
                    if hum then hum.PlatformStand = true end
                end
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50 * flySpeed
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                else
                    BV.velocity = Vector3.new(0, 0, 0)
                end
                BG.cframe = workspace.CurrentCamera.CoordinateFrame
            until not FLYING
            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass('Humanoid')
                    if hum then hum.PlatformStand = false end
                end
            end)
        end)
        flyKeyDown = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            local KEY = input.KeyCode.Name:lower()
            if KEY == 'w' then
                CONTROL.F = flySpeed
            elseif KEY == 's' then
                CONTROL.B = -flySpeed
            elseif KEY == 'a' then
                CONTROL.L = -flySpeed
            elseif KEY == 'd' then
                CONTROL.R = flySpeed
            elseif QEfly and KEY == 'e' then
                CONTROL.Q = flySpeed * 2
            elseif QEfly and KEY == 'q' then
                CONTROL.E = -flySpeed * 2
            end
        end)
        flyKeyUp = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            local KEY = input.KeyCode.Name:lower()
            if KEY == 'w' then CONTROL.F = 0
            elseif KEY == 's' then CONTROL.B = 0
            elseif KEY == 'a' then CONTROL.L = 0
            elseif KEY == 'd' then CONTROL.R = 0
            elseif KEY == 'e' then CONTROL.Q = 0
            elseif KEY == 'q' then CONTROL.E = 0
            end
        end)
    end)
end
local removeFogConn = nil
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart
local function SetRemoveFog(enabled)
    if enabled then
        pcall(function()
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 0
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") then
                    v.Density = 0
                    v.Haze = 0
                end
            end
        end)
        if not removeFogConn then
            removeFogConn = Lighting.Changed:Connect(function()
                if _G.Config and _G.Config.RemoveFog then
                    Lighting.FogEnd = 1000000
                    Lighting.FogStart = 0
                end
            end)
        end
    else
        if removeFogConn then removeFogConn:Disconnect(); removeFogConn = nil end
        pcall(function()
            Lighting.FogEnd = originalFogEnd or 10000
            Lighting.FogStart = originalFogStart or 0
        end)
    end
end
local boostFpsDescConn = nil
local function optimizeFpsInstance(v)
    if v:IsA("BasePart") then
        pcall(function()
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
        end)
    elseif v:IsA("Decal") or v:IsA("Texture") then
        pcall(function() v.Transparency = 1 end)
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
        pcall(function()
            v.Enabled = false
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            end
        end)
    elseif v:IsA("Explosion") then
        pcall(function()
            v.BlastPressure = 1
            v.BlastRadius = 1
        end)
    end
end
local function SetBoostFPS(enabled)
    if boostFpsDescConn then boostFpsDescConn:Disconnect(); boostFpsDescConn = nil end
    if enabled then
        pcall(function()
            local Terrain = workspace:FindFirstChildOfClass("Terrain")
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect")
                or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("PostEffect") then
                    pcall(function() v.Enabled = false end)
                end
            end
            for _, v in ipairs(workspace:GetDescendants()) do
                optimizeFpsInstance(v)
            end
        end)
        boostFpsDescConn = workspace.DescendantAdded:Connect(function(child)
            optimizeFpsInstance(child)
        end)
    else
        if boostFpsDescConn then
            boostFpsDescConn:Disconnect()
            boostFpsDescConn = nil
        end
        pcall(function()
            Lighting.GlobalShadows = true
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end)
    end
end
local screenSaverGui = nil
local function SetScreenSaver(enabled, colorType)
    if not enabled then
        if screenSaverGui then
            screenSaverGui:Destroy()
            screenSaverGui = nil
        end
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
        return
    end
    if screenSaverGui then screenSaverGui:Destroy() end
    local parentTarget = (typeof(gethui) == "function" and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    screenSaverGui = Instance.new("ScreenGui")
    screenSaverGui.Name = "Shield_ScreenSaver"
    screenSaverGui.DisplayOrder = 999999
    screenSaverGui.ResetOnSpawn = false
    screenSaverGui.Parent = parentTarget
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = (colorType == "White") and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = screenSaverGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 100)
    label.Position = UDim2.new(0, 0, 0.45, 0)
    label.BackgroundTransparency = 1
    label.Text = "SHIELD TEAM AFK MODE ACTIVE\n(Toggle in GUI to Disable)"
    label.TextColor3 = (colorType == "White") and Color3.new(0, 0, 0) or Color3.new(0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.Parent = frame
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end
return {
    SetAntiAFK = SetAntiAFK,
    SetFly = SetFly,
    SetFlySpeed = function(val) flySpeed = val end,
    SetRemoveFog = SetRemoveFog,
    SetBoostFPS = SetBoostFPS,
    SetScreenSaver = SetScreenSaver,
}