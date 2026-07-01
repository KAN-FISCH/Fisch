local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Helper getMod loader
local function getMod(name)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    return success and result or nil
end

local STATE_CAST = "CAST"
local STATE_WAIT = "WAIT"
local STATE_LOCK = "LOCK"
local HEARTBEAT_THROTTLE = 0.05

local state = STATE_CAST
local lockedCFrame = nil
local bobberRef = nil
local lastSpamCast = 0
local bobberHandled = false
local cachedBP = nil
local cachedBG = nil
local castPending = false
local lastHeartbeat = 0
local lastCastTime = 0

local heartbeatConnection = nil
local bobberConnection = nil

local castRemoteCache = nil
pcall(function()
    castRemoteCache = game:GetService("ReplicatedStorage")
        :WaitForChild("packages", 10)
        :WaitForChild("Net", 10)
        :WaitForChild("RF/FishingRod/Cast", 10)
end)

local function getRodName()
    local success, result = pcall(function()
        return workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
    end)
    return success and result or nil
end

local function safeDisconnect(connName)
    if connName == "bobber" and bobberConnection then
        pcall(function() bobberConnection:Disconnect() end)
        bobberConnection = nil
    elseif connName == "heartbeat" and heartbeatConnection then
        pcall(function() heartbeatConnection:Disconnect() end)
        heartbeatConnection = nil
    end
end

local function setupBobberWatch(rod, hrp)
    local InstantBobber = getMod("InstantBobber")
    if not InstantBobber then return end

    safeDisconnect("bobber")
    if not rod or not rod.Parent then return end
    bobberConnection = rod.ChildAdded:Connect(function(child)
        if child.Name == "bobber" and child:IsA("BasePart") and not bobberHandled then
            bobberHandled = true
            pcall(function()
                if not hrp or not hrp.Parent then return end
                local targetCFrame = InstantBobber.GetTargetPosition(hrp)
                if targetCFrame and child and child.Parent then
                    InstantBobber.InstantTeleportBobber(child, targetCFrame, hrp)
                    lockedCFrame = targetCFrame
                    bobberRef = child
                    cachedBP = child:FindFirstChild("HoldPos")
                    cachedBG = child:FindFirstChild("HoldRot")
                    state = STATE_LOCK
                end
            end)
            safeDisconnect("bobber")
        end
    end)
end

-- Initialize Loop
task.spawn(function()
    local InstantBobber = getMod("InstantBobber")
    while not InstantBobber do
        task.wait(0.5)
        InstantBobber = getMod("InstantBobber")
    end

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastHeartbeat < HEARTBEAT_THROTTLE then return end
        lastHeartbeat = now

        if not _G.Config or not _G.Config.AutoCast then
            state = STATE_CAST
            bobberRef = nil
            lockedCFrame = nil
            cachedBP = nil
            cachedBG = nil
            bobberHandled = false
            castPending = false
            return
        end

        local char = LocalPlayer.Character
        if not char or not char.Parent then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end

        local rodName = getRodName()
        if not rodName then return end
        local rod = char:FindFirstChild(rodName)
        if not rod or not rod.Parent then
            return
        end

        local ok, err = pcall(function()
            if state == STATE_CAST then
                if castPending then return end
                local events = rod:FindFirstChild("events")
                if events then
                    castPending = true
                    task.spawn(function()
                        pcall(function()
                            task.wait(0.01)
                            local basePower = 100
                            if math.random(1, 10) > 7 then
                                basePower = math.random(95, 99)
                            end
                            local perfectChance = 100
                            if _G.Config and type(_G.Config.perfectCastEnabled) == "number" then
                                perfectChance = _G.Config.perfectCastEnabled
                            end
                            local isPerfect = math.random(1, 100) <= perfectChance
                            if castRemoteCache then
                                castRemoteCache:InvokeServer(basePower, isPerfect)
                            end
                        end)
                        lastCastTime = tick()
                        state = STATE_WAIT
                        bobberRef = nil
                        lockedCFrame = nil
                        cachedBP = nil
                        cachedBG = nil
                        lastSpamCast = tick()
                        bobberHandled = false
                        castPending = false
                        if rod and rod.Parent and hrp and hrp.Parent then
                            setupBobberWatch(rod, hrp)
                        end
                    end)
                end

            elseif state == STATE_WAIT then
                if not bobberHandled then
                    local bobber = rod:FindFirstChild("bobber")
                    if bobber and bobber:IsA("BasePart") and bobber.Parent then
                        bobberHandled = true
                        local targetCFrame = InstantBobber.GetTargetPosition(hrp)
                        if targetCFrame then
                            InstantBobber.InstantTeleportBobber(bobber, targetCFrame, hrp)
                            lockedCFrame = targetCFrame
                            bobberRef = bobber
                            cachedBP = bobber:FindFirstChild("HoldPos")
                            cachedBG = bobber:FindFirstChild("HoldRot")
                            state = STATE_LOCK
                        end
                        safeDisconnect("bobber")
                    end
                end
                if not bobberHandled and now - lastCastTime >= 0.6 then
                    safeDisconnect("bobber")
                    state = STATE_CAST
                end

            elseif state == STATE_LOCK then
                if not bobberRef or not bobberRef.Parent then
                    cachedBP = nil; cachedBG = nil; state = STATE_CAST; return
                end
                if not lockedCFrame then state = STATE_CAST; return end
                local currentDist = (hrp.Position - bobberRef.Position).Magnitude
                if currentDist > 60 then
                    cachedBP = nil; cachedBG = nil; state = STATE_CAST; return
                end
                if cachedBP and cachedBP.Parent then
                    cachedBP.Position = lockedCFrame.Position
                end
                if cachedBG and cachedBG.Parent then
                    cachedBG.CFrame = lockedCFrame
                end
                local drift = (bobberRef.Position - lockedCFrame.Position).Magnitude
                if drift > 4 then
                    if drift <= 20 then
                        bobberRef.CFrame = lockedCFrame
                        bobberRef.AssemblyLinearVelocity = Vector3.zero
                        bobberRef.AssemblyAngularVelocity = Vector3.zero
                    else
                        cachedBP = nil; cachedBG = nil; state = STATE_CAST; return
                    end
                end
            end
        end)

        if not ok then
            state = STATE_CAST
            cachedBP = nil; cachedBG = nil; bobberRef = nil
        end
    end)
end)

local AutoCast = {}
setmetatable(AutoCast, {
    __call = function(self, value)
        _G.Config.AutoCast = value
    end
})

return AutoCast
