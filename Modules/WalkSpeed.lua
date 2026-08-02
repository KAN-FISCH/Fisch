local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local speedEnabled = false
local speedValue = 16
local speedConn = nil
local jumpConn = nil
local infJumpConn = nil

local function updateSpeedConnection()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    if speedEnabled then
        speedConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = speedValue end
        end)
    else
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

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
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = value or 50
                hum.JumpHeight = value or 50
            end
        end)
    else
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = 50; hum.JumpHeight = 7.2 end
    end
end

local function SetInfJump(enabled)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    if enabled then
        infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local function SetNoClip(enabled)
    if not enabled then return end
    RunService.Stepped:Connect(function()
        if not enabled then return end
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
end

local function SetRemoveFog(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.FogEnd = 1e9
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm:Destroy() end
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
