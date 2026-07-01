-- AutoCast.lua - Optimized lightweight version
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cache sekali saja, tidak di-poll ulang
local IB = nil -- InstantBobber cache
local castRemote = nil
local heartbeatConn = nil
local bobberConn = nil

-- State
local S_CAST, S_WAIT, S_LOCK = 1, 2, 3
local state = S_CAST
local lastTick = 0
local lastCastTick = 0
local castPending = false
local bobberHandled = false
local lockedCF = nil
local bobberRef = nil

local THROTTLE = 0.05

-- Cache Cast Remote
task.spawn(function()
    pcall(function()
        castRemote = game:GetService("ReplicatedStorage")
            :WaitForChild("packages", 15)
            :WaitForChild("Net", 15)
            :WaitForChild("RF/FishingRod/Cast", 15)
    end)
end)

-- Rod name helper - simple pcall, tidak loop
local function getRod(char)
    local ok, rodName = pcall(function()
        return workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
    end)
    if ok and rodName and rodName ~= "" then
        return char:FindFirstChild(rodName)
    end
end

local function resetState()
    state = S_CAST
    castPending = false
    bobberHandled = false
    lockedCF = nil
    bobberRef = nil
    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
end

local function lockBobber(bobber, cf, hrp)
    if not IB or not bobber or not bobber.Parent then return end
    IB.InstantTeleportBobber(bobber, cf, hrp)
    lockedCF = cf
    bobberRef = bobber
    state = S_LOCK
    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
end

local function watchBobber(rod, hrp)
    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
    if not rod or not rod.Parent then return end
    bobberConn = rod.ChildAdded:Connect(function(child)
        if child.Name == "bobber" and child:IsA("BasePart") and not bobberHandled then
            bobberHandled = true
            pcall(function()
                if not hrp or not hrp.Parent then return end
                local cf = IB and IB.GetTargetPosition(hrp)
                if cf then
                    lockBobber(child, cf, hrp)
                end
            end)
        end
    end)
end

local function doCast(rod, hrp)
    if not castRemote or not rod:FindFirstChild("events") then return end
    castPending = true
    task.spawn(function()
        pcall(function()
            local power = (math.random(10) > 7) and math.random(95, 99) or 100
            local perfect = math.random(100) <= (type(_G.Config.perfectCastEnabled) == "number" and _G.Config.perfectCastEnabled or 100)
            castRemote:InvokeServer(power, perfect)
        end)
        lastCastTick = tick()
        state = S_WAIT
        bobberHandled = false
        castPending = false
        lockedCF = nil; bobberRef = nil; cachedBP = nil; cachedBG = nil
        watchBobber(rod, hrp)
    end)
end

local function startLoop()
    if heartbeatConn then heartbeatConn:Disconnect() end
    heartbeatConn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastTick < THROTTLE then return end
        lastTick = now

        if not (_G.Config and _G.Config.AutoCast) then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rod = getRod(char)
        if not rod then return end

        if state == S_CAST then
            if not castPending then
                doCast(rod, hrp)
            end

        elseif state == S_WAIT then
            if not bobberHandled then
                local b = rod:FindFirstChild("bobber")
                if b and b:IsA("BasePart") and b.Parent then
                    bobberHandled = true
                    pcall(function()
                        local cf = IB and IB.GetTargetPosition(hrp)
                        if cf then lockBobber(b, cf, hrp) end
                    end)
                elseif now - lastCastTick > 0.8 then
                    -- timeout, cast lagi
                    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
                    state = S_CAST
                end
            end

        elseif state == S_LOCK then
            if not (bobberRef and bobberRef.Parent and lockedCF) then
                resetState(); return
            end
            -- Jika bobber terlalu jauh dari player, re-cast
            if (hrp.Position - bobberRef.Position).Magnitude > 65 then
                resetState(); return
            end
            -- Koreksi drift - bobber bisa bergeser sedikit karena physics
            local drift = (bobberRef.Position - lockedCF.Position).Magnitude
            if drift > 2 then
                if drift <= 22 then
                    pcall(function()
                        bobberRef.CFrame = lockedCF
                    end)
                else
                    resetState(); return
                end
            end
        end
    end)
end

-- Inisialisasi: tunggu _G.getMod siap lalu cache InstantBobber sekali saja
task.spawn(function()
    local t = 0
    while not _G.getMod and t < 10 do task.wait(0.3); t = t + 0.3 end
    if _G.getMod then
        IB = _G.getMod("InstantBobber")
    end
    startLoop()
end)

local AutoCast = {}
setmetatable(AutoCast, {
    __call = function(_, value)
        _G.Config.AutoCast = value
        if not value then resetState() end
    end
})

return AutoCast
