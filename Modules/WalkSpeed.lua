local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local speedEnabled = false
local speedValue = 16
local speedConn = nil
local humPropConn = nil
local jumpConn = nil
local infJumpConn = nil
local noClipConn = nil
local noClipEnabled = false
local lastJumpTime = 0
local mobileJumpConns = {}
local function bindHumanoidSpeed(hum)
    if humPropConn then humPropConn:Disconnect(); humPropConn = nil end
    if hum and speedEnabled then
        hum.WalkSpeed = speedValue
        humPropConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if speedEnabled and hum.WalkSpeed ~= speedValue then
                hum.WalkSpeed = speedValue
            end
        end)
    end
end
local function updateSpeedConnection()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    if humPropConn then humPropConn:Disconnect(); humPropConn = nil end
    if speedEnabled then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then bindHumanoidSpeed(hum) end
        speedConn = RunService.Heartbeat:Connect(function()
            if not speedEnabled then return end
            local c = player.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.WalkSpeed ~= speedValue then
                h.WalkSpeed = speedValue
            end
        end)
    else
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end
local function doJump()
    if not (_G.Config and (_G.Config.InfinityJump or _G.Config.InfiniteJump)) then return end
    local now = tick()
    if now - lastJumpTime < 0.15 then return end
    lastJumpTime = now
    pcall(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            if hrp:IsA("BasePart") then
                local curVel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(curVel.X, math.max(curVel.Y, 50), curVel.Z)
            end
        end
    end)
end
local function clearMobileConns()
    for _, c in ipairs(mobileJumpConns) do
        pcall(function() c:Disconnect() end)
    end
    mobileJumpConns = {}
end
local function bindMobileJump(char)
    clearMobileConns()
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        local c1 = hum:GetPropertyChangedSignal("Jump"):Connect(function()
            if hum.Jump then doJump() end
        end)
        table.insert(mobileJumpConns, c1)
        local c2 = hum.Jumping:Connect(function(isActive)
            if isActive then doJump() end
        end)
        table.insert(mobileJumpConns, c2)
    end
    task.spawn(function()
        local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 3)
        if playerGui then
            local touchGui = playerGui:FindFirstChild("TouchGui")
            if touchGui then
                local jumpButton = touchGui:FindFirstChild("JumpButton", true)
                if jumpButton then
                    local c3 = jumpButton.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                            doJump()
                        end
                    end)
                    table.insert(mobileJumpConns, c3)
                end
            end
        end
    end)
end
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if speedEnabled then
        updateSpeedConnection()
    end
    if _G.Config and (_G.Config.InfinityJump or _G.Config.InfiniteJump) then
        bindMobileJump(char)
    end
end)
local function SetSpeed(enabled, value)
    speedEnabled = enabled
    if value then speedValue = value end
    updateSpeedConnection()
end
local function SetJumpPower(enabled, value)
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    if enabled then
        jumpConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = value or 50
                hum.JumpHeight = value or 50
            end
        end)
    else
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 50; hum.JumpHeight = 7.2 end
    end
end
local function SetInfJump(enabled)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    clearMobileConns()
    _G.Config.InfinityJump = enabled
    _G.Config.InfiniteJump = enabled
    if enabled then
        infJumpConn = UserInputService.JumpRequest:Connect(doJump)
        bindMobileJump(player.Character)
    end
end
local function SetNoClip(enabled)
    noClipEnabled = enabled
    if noClipConn then noClipConn:Disconnect(); noClipConn = nil end
    if enabled then
        noClipConn = RunService.Stepped:Connect(function()
            if not noClipEnabled then return end
            local char = player.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end
local function SetRemoveFog(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.FogEnd = 1e9
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v.Density = 0
                v.Haze = 0
            end
        end
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 200
    end
end
local WalkSpeed = {
    SetSpeed = SetSpeed,
    SetJumpPower = SetJumpPower,
    SetInfJump = SetInfJump,
    SetNoClip = SetNoClip,
    SetRemoveFog = SetRemoveFog,
}
setmetatable(WalkSpeed, {
    __call = function(self, value)
        speedValue = tonumber(value) or 16
        speedEnabled = (speedValue > 16)
        updateSpeedConnection()
    end
})
return WalkSpeed