local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shieldReelHooked = false
local shieldOriginalStartReel = nil

-- Monitor GUI, start automatically on import
task.spawn(function()
    local player = Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")
    local hudCache = gui:FindFirstChild("hud")
    local camera = workspace.CurrentCamera
    local backpackCache, hotbarCache, reelCache = nil, nil, nil
    local lastBackpackCheck, lastReelCheck, lastZoomCheck = 0, 0, 0
    local BACKPACK_INTERVAL, REEL_INTERVAL = 0.5, 0.05
    local lockedFOV = nil

    local function disableZoom()
        if not _G.Config or not _G.Config.AutoCast then return end
        if not lockedFOV then lockedFOV = camera.FieldOfView end
        if not camera:GetAttribute("ZoomLocked") then
            camera:SetAttribute("ZoomLocked", true)
            camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if not _G.Config or not _G.Config.AutoCast then return end
                if lockedFOV and camera.FieldOfView ~= lockedFOV then
                    camera.FieldOfView = lockedFOV
                end
            end)
        end
        if camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom
        end
    end

    local function disableReel(reel)
        if not _G.Config or not _G.Config.InstantReel then return end
        if not reel or not reel:IsA("ScreenGui") then return end
        if reel:GetAttribute("ShieldStarting") then return end
        reel.Enabled = false
        reel.ResetOnSpawn = false
    end

    local function stickyGui(obj)
        if not _G.Config or not _G.Config.AutoCast then return end
        if not obj then return end
        if obj:IsA("ScreenGui") then
            if not obj.Enabled then obj.Enabled = true end
            if not obj:GetAttribute("StickyConnected") then
                obj:SetAttribute("StickyConnected", true)
                obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if not _G.Config or not _G.Config.AutoCast then return end
                    if not obj.Enabled then obj.Enabled = true end
                end)
            end
        elseif obj:IsA("GuiObject") then
            if not obj.Visible then obj.Visible = true end
            if not obj:GetAttribute("StickyConnected") then
                obj:SetAttribute("StickyConnected", true)
                obj:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not _G.Config or not _G.Config.AutoCast then return end
                    if not obj.Visible then obj.Visible = true end
                end)
            end
        end
    end

    local function ensureBackpackVisible()
        if not _G.Config or not _G.Config.AutoCast then return end
        if not backpackCache then
            backpackCache = gui:FindFirstChild("backpack") or gui:FindFirstChild("Backpack")
        end
        if backpackCache then
            stickyGui(backpackCache)
            if not hotbarCache then
                hotbarCache = backpackCache:FindFirstChild("hotbar") or backpackCache:FindFirstChild("Hotbar")
            end
            if hotbarCache then stickyGui(hotbarCache) end
        end
    end

    local function monitorReel(reel)
        if not reel or reel:GetAttribute("ReelMonitored") then return end
        reel:SetAttribute("ReelMonitored", true)
        reel:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not _G.Config or not _G.Config.InstantReel then return end
            if reel:GetAttribute("ShieldStarting") then return end
            if reel.Enabled then reel.Enabled = false end
        end)
    end

    local function ensureHudEnabled()
        if not _G.Config or not _G.Config.AutoCast then return end
        if hudCache and not hudCache.Enabled then hudCache.Enabled = true end
    end

    gui.ChildAdded:Connect(function(child)
        local cName = child.Name:lower()
        if child.Name == "reel" then
            reelCache = child
            disableReel(child)
            monitorReel(child)
            if _G.Config and _G.Config.AutoCast then
                ensureHudEnabled()
                disableZoom()
            end
            return
        end
        if not _G.Config or not _G.Config.AutoCast then return end
        if cName == "backpack" or cName == "hotbar" then
            if cName == "backpack" then backpackCache = child
            else hotbarCache = child end
            ensureBackpackVisible()
        elseif child.Name == "hud" then
            hudCache = child
            if not child:GetAttribute("HudMonitored") then
                child:SetAttribute("HudMonitored", true)
                child:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if not _G.Config or not _G.Config.AutoCast then return end
                    if not child.Enabled then child.Enabled = true end
                end)
            end
        end
    end)

    reelCache = gui:FindFirstChild("reel")
    if reelCache then
        disableReel(reelCache)
        monitorReel(reelCache)
    end

    RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastReelCheck >= REEL_INTERVAL then
            lastReelCheck = now
            if _G.Config and _G.Config.InstantReel then
                if not reelCache then reelCache = gui:FindFirstChild("reel") end
                if reelCache and reelCache:IsA("ScreenGui") and reelCache.Enabled
                    and not reelCache:GetAttribute("ShieldStarting") then
                    reelCache.Enabled = false
                end
            end
        end
        if not _G.Config or not _G.Config.AutoCast then return end
        if now - lastBackpackCheck >= BACKPACK_INTERVAL then
            lastBackpackCheck = now
            ensureBackpackVisible()
        end
        if now - lastZoomCheck >= 0.05 then
            lastZoomCheck = now
            if lockedFOV and camera.FieldOfView ~= lockedFOV then
                camera.FieldOfView = lockedFOV
            end
        end
        ensureHudEnabled()
    end)
end)

-- Hook ReelController automatically on import
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
        if not data or not _G.Config or not _G.Config.InstantReel then
            return shieldOriginalStartReel(data)
        end

        local perfectChance = 100
        if _G.Config and type(_G.Config.PerfectCatchChance) == "number" then
            perfectChance = _G.Config.PerfectCatchChance
        elseif _G.Config and type(_G.Config.perfectCatchEnabled) == "number" then
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
            local char = Players.LocalPlayer.Character
            if not char then return end
            -- Wait for Reeling attribute
            if not char:GetAttribute("Reeling") then
                local reelTimeout, t, reeling = 5, 0, false
                local conn = char:GetAttributeChangedSignal("Reeling"):Connect(function()
                    reeling = char:GetAttribute("Reeling")
                end)
                while not reeling and t < reelTimeout do task.wait(0.1); t = t + 0.1 end
                conn:Disconnect()
                if not reeling then return end
            end

            -- Wait for ready
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
                local ch = Players.LocalPlayer.Character
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

-- Character respawn handler
local function dropAndReel()
    task.wait(0.3)
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local events = RS:FindFirstChild("events")
        if events then
            local dropRod = events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber")
            if dropRod then pcall(function() dropRod:FireServer() end) end
        end
    end)
end

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    dropAndReel()
end)
if Players.LocalPlayer.Character then
    task.spawn(dropAndReel)
end

local AutoReel = {}
setmetatable(AutoReel, {
    __call = function(self, value)
        _G.Config.InstantReel = value
    end
})

return AutoReel
