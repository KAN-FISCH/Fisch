local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local shieldReelHooked = false
local shieldOriginalStartReel = nil

-- Hook controller automatically on import
task.spawn(function()
    if shieldReelHooked then return end
    local RS = game:GetService("ReplicatedStorage")
    local elapsed = 0
    while not RS:FindFirstChild("client") and elapsed < 10 do
        task.wait(0.5); elapsed = elapsed + 0.5
    end
    if not RS:FindFirstChild("client") then return end

    local ok, controller = pcall(require, RS.client.legacyControllers.ReelController)
    if not ok or not controller then return end

    shieldOriginalStartReel = controller.StartReel
    shieldReelHooked = true

    controller.StartReel = function(data)
        -- If AutoPerfectCatch not enabled, use original
        if not data or not _G.Config or (not _G.Config.AutoPerfectCatch and not _G.Config.InstantReel) then
            return shieldOriginalStartReel(data)
        end

        local perfectChance = 100
        if type(_G.Config.PerfectCatchChance) == "number" then
            perfectChance = _G.Config.PerfectCatchChance
        elseif type(_G.Config.perfectCatchEnabled) == "number" then
            perfectChance = _G.Config.perfectCatchEnabled
        end
        local isPerfect = math.random(100) <= perfectChance
        if data then data.perfect = isPerfect end

        local ok2, instance = pcall(shieldOriginalStartReel, data)
        if not ok2 or not instance then return instance end

        _G.LastCatchTick = tick()

        local reelGui = instance.reel
        if reelGui then
            reelGui:SetAttribute("ShieldStarting", true)
            task.delay(2.8, function()
                if reelGui and reelGui.Parent then
                    reelGui:SetAttribute("ShieldStarting", false)
                    if _G.Config and _G.Config.InstantReel then
                        reelGui.Enabled = false
                    end
                end
            end)
        end

        task.spawn(function()
            local char = LocalPlayer.Character
            if not char then return end

            if not char:GetAttribute("Reeling") then
                local t, reeling = 0, false
                local conn = char:GetAttributeChangedSignal("Reeling"):Connect(function()
                    reeling = char:GetAttribute("Reeling")
                end)
                while not reeling and t < 5 do task.wait(0.1); t = t + 0.1 end
                conn:Disconnect()
                if not reeling then return end
            end

            if not instance.ready then
                local t, isReady = 0, false
                if instance.OnReady then
                    local conn = instance.OnReady:Connect(function() isReady = true end)
                    while not isReady and t < 5 do task.wait(0.1); t = t + 0.1 end
                    conn:Disconnect()
                else
                    while not instance.ready and t < 5 do task.wait(0.1); t = t + 0.1 end
                    isReady = instance and instance.ready
                end
                if not isReady then return end
            end

            instance.perfect = isPerfect
            task.wait(0.32)

            local hbConn, hbStart = nil, tick()
            hbConn = RunService.Heartbeat:Connect(function()
                if tick() - hbStart > 30 then hbConn:Disconnect(); return end
                local ch = LocalPlayer.Character
                if not ch or not ch:GetAttribute("Reeling") then
                    if _G.Config and _G.Config.InstantReel then
                        pcall(function() instance.progress = 100 end)
                    end
                    hbConn:Disconnect(); return
                end
                if _G.Config and _G.Config.InstantReel then
                    pcall(function()
                        instance.progress = 100
                        if typeof(instance.Finish) == "function" then
                            instance:Finish(true)
                        elseif instance.OnReelFinished then
                            instance.OnReelFinished:Fire(true)
                        end
                    end)
                end
            end)
        end)

        return instance
    end
end)

local PerfectCatch = {}
setmetatable(PerfectCatch, {
    __call = function(self, value)
        _G.Config.AutoPerfectCatch = value
    end
})

return PerfectCatch
