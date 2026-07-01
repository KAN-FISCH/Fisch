local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local heartbeatConnection = nil
local lastHeartbeat = 0
local HEARTBEAT_THROTTLE = 0.03

local castRemoteCache = nil
pcall(function()
    castRemoteCache = game:GetService("ReplicatedStorage")
        :WaitForChild("packages", 10)
        :WaitForChild("Net", 10)
        :WaitForChild("RF/FishingRod/Cast", 10)
end)

local function safeDisconnect()
    if heartbeatConnection then
        pcall(function() heartbeatConnection:Disconnect() end)
        heartbeatConnection = nil
    end
end

local function checkReel(reel)
    if _G.Config and _G.Config.AutoReel and reel and reel:IsA("ScreenGui") then
        if _G.__var and _G.__var.reelConnection then
        end
    end
end

local function getRodName()
    local rodName = nil
    pcall(function()
        local stats = workspace:FindFirstChild("PlayerStats")
        local lpStats = stats and stats:FindFirstChild(LocalPlayer.Name)
        local t = lpStats and lpStats:FindFirstChild("T")
        local statsDir = t and t:FindFirstChild(LocalPlayer.Name) and t[LocalPlayer.Name]:FindFirstChild("Stats")
        if statsDir and statsDir:FindFirstChild("rod") then
            rodName = statsDir.rod.Value
        end
    end)
    return rodName
end

local function startCastLoop()
    safeDisconnect()

    local STATE_CAST = 1
    local STATE_WAIT = 2
    local state = STATE_CAST
    local castPending = false

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastHeartbeat < HEARTBEAT_THROTTLE then return end
        lastHeartbeat = now

        if not _G.Config or not _G.Config.AutoCast then
            safeDisconnect()
            return
        end

        local rodName = getRodName()
        if not rodName then return end

        local char = LocalPlayer.Character
        if not char or not char.Parent then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end

        local rod = char:FindFirstChild(rodName)
        if not rod or not rod.Parent then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local tool = backpack and backpack:FindFirstChild(rodName)
            if tool then equipAndClick(tool) end
            return 
        end

        local reel = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("reel")
        if reel and reel.Enabled then
            checkReel(reel)
            return 
        end

        pcall(function()
            if state == STATE_CAST then
                if castPending then return end
                local events = rod:FindFirstChild("events")
                if events then
                    castPending = true
                    task.spawn(function()
                        pcall(function()
                            task.wait(0.01)
                            local basePower = 100
                            if math.random(1, 10) > 7 then basePower = math.random(95, 99) end

                            local perfectChance = tonumber(_G.__var and _G.__var.perfectCastEnabled) or 0
                            local isPerfect = math.random(1, 100) <= perfectChance
                            if castRemoteCache then
                                castRemoteCache:InvokeServer(basePower, isPerfect)
                            end
                        end)
                        state = STATE_WAIT
                        castPending = false
                    end)
                end
            elseif state == STATE_WAIT then
                local bobber = rod:FindFirstChild("bobber")
                if bobber and bobber:IsA("BasePart") then
                elseif not bobber then
                    state = STATE_CAST
                end
            end
        end)
    end)
end

local function equipAndClick(tool)
    if not LocalPlayer.Character then return end
    LocalPlayer.Character.Humanoid:EquipTool(tool)
    task.wait(0.5)
    mouse1press()
    task.wait(0.1)
    mouse1release()
end

local function init(value)
    print("[NewFish5] AutoCast toggled:", value)
    _G.Config.AutoCast = value

    if value then
        startCastLoop()
    else
        safeDisconnect()
    end
end

return init