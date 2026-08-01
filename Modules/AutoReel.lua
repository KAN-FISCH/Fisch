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
    local lastBackpackCheck, lastReelCheck, lastHudCheck = 0, 0, 0
    -- FIX: Interval reel dinaikkan dari 0.05 (20x/s) ke 0.2 (5x/s) — cukup untuk suppress GUI
    local BACKPACK_INTERVAL, REEL_INTERVAL, HUD_INTERVAL = 0.5, 0.2, 0.5

    -- FIX: disableZoom() dihapus sepenuhnya — tidak perlu force CameraType/FOV
    -- Game fish (ReelController) membutuhkan CameraType = Scriptable saat animasi reel
    -- Memaksa balik ke Custom menyebabkan "camera fight" yang bikin lag/stutter

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

    -- FIX: ensureHudEnabled sekarang pakai throttle (HUD_INTERVAL = 0.5s)
    -- Sebelumnya dipanggil setiap heartbeat (~60x/s) tanpa throttle
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
            -- FIX: Hapus panggilan disableZoom() di sini — tidak memaksa kamera saat reel muncul
            if _G.Config and _G.Config.AutoCast then
                ensureHudEnabled()
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

    -- FIX: Heartbeat loop dibersihkan:
    --   1. REEL_INTERVAL dinaikkan ke 0.2s (dari 0.05s)
    --   2. Tidak ada lagi force FOV/CameraType di dalam loop
    --   3. ensureHudEnabled sekarang di-throttle dengan HUD_INTERVAL (0.5s)
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
        -- FIX: ensureHudEnabled sekarang pakai throttle (HUD_INTERVAL)
        if now - lastHudCheck >= HUD_INTERVAL then
            lastHudCheck = now
            ensureHudEnabled()
        end
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

    if controller.Update then
        local oldUpdate = controller.Update
        controller.Update = function(self, dt)
            pcall(function() oldUpdate(self, dt) end)
            if _G.Config and _G.Config.AutoReel and _G.Config.ReelMode == "Legit" then
                self.fishPosition = self.barPosition
            end
        end
    end

    local isSnapping = false

    controller.StartReel = function(data)
        if not data or not _G.Config then
            return shieldOriginalStartReel(data)
        end

        _G.IsReeling = true
        _G.ReelStartTick = tick()

        -- Show catch notification immediately for all bites (even if snapped!)
        if _G.ShowCatchNotification and data.fish then
            task.spawn(_G.ShowCatchNotification, data.fish)
        end

        -- Ultra-fast 0ms Snap Filter Check (Cancel WITHOUT spawning reel!)
        if not isSnapping and _G.__var and _G.__var.AutoSnapEnabled and _G.CheckSnapFilter then
            local shouldKeep = _G.CheckSnapFilter(data.fish)
            if not shouldKeep then
                isSnapping = true
                -- Ultra-fast 0ms Snap: Fire drop_bobber & finish abort payload immediately!
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local events = RS:FindFirstChild("events")
                    if events then
                        local dropRod = events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber")
                        if dropRod then dropRod:FireServer() end
                    end
                end)

                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local pkg = RS:FindFirstChild("packages")
                    local netMod = pkg and pkg:FindFirstChild("Net")
                    if netMod then
                        local okNet, Net = pcall(require, netMod)
                        if okNet and Net then
                            local finishEvent = Net:RemoteEvent("Reel/Finish")
                            if finishEvent then
                                pcall(function()
                                    finishEvent:FireServer({
                                        e = -0.033138427883387,
                                        p = false,
                                        l = {},
                                        d = {}
                                    })
                                end)
                            end
                        end
                    end
                end)

                local dummyInstance = {
                    active = false,
                    ready = false,
                    OnReady = { Connect = function() return { Disconnect = function() end } end },
                    Destroy = function() end,
                    Finish = function() end,
                    EndMinigame = function() end
                }

                pcall(function()
                    local char = Players.LocalPlayer.Character
                    if char and char:GetAttribute("Reeling") then
                        char:SetAttribute("Reeling", nil)
                    end
                end)

                _G.LastCatchTick = 0
                _G.IsReeling = false
                if _G.ResetAutoCastState then pcall(_G.ResetAutoCastState, true) end
                isSnapping = false
                return dummyInstance
            end
        end

        -- Call original StartReel to obtain authentic instance for KEPT fish
        local ok, instance = pcall(shieldOriginalStartReel, data)
        if not ok or not instance then
            _G.IsReeling = false
            return instance
        end

        _G.LastCatchTick = tick()

        -- Hide Reel GUI instantly for Kept Fish if InstantReel is enabled
        local reelGui = instance.reel
        if reelGui then
            reelGui:SetAttribute("ShieldStarting", true)
            if _G.Config and _G.Config.InstantReel then
                reelGui.Enabled = false
            end
        end

        -- Kept fish / Normal reel path
        if _G.Config and (_G.Config.InstantReel or _G.Config.AutoPerfectCatch) then
            local perfectChance = 100
            if type(_G.Config.PerfectCatchChance) == "number" then
                perfectChance = _G.Config.PerfectCatchChance
            elseif type(_G.Config.perfectCatchEnabled) == "number" then
                perfectChance = _G.Config.perfectCatchEnabled
            end
            local isPerfect = math.random(100) <= perfectChance
            instance.perfect = isPerfect

            task.spawn(function()
                -- Wait for ready if needed
                if not instance.ready then
                    local t, isReady = 0, false
                    if instance.OnReady then
                        local conn = instance.OnReady:Connect(function() isReady = true end)
                        while not isReady and t < 3 do task.wait(0.01); t = t + 0.01 end
                        conn:Disconnect()
                    else
                        while not instance.ready and t < 3 do task.wait(0.01); t = t + 0.01 end
                    end
                end

                if _G.Config and _G.Config.InstantReel then
                    local reelDelay = (_G.__var and _G.__var.AutoSnapEnabled) and 0.4 or 0.15
                    task.wait(reelDelay)
                    pcall(function()
                        instance.progress = 100
                        if typeof(instance.Finish) == "function" then
                            instance:Finish(true)
                        elseif instance.OnReelFinished then
                            instance.OnReelFinished:Fire(true)
                        end
                    end)
                    task.wait(0.12)
                    _G.IsReeling = false
                    _G.LastCatchTick = 0
                    if _G.ResetAutoCastState then pcall(_G.ResetAutoCastState, true) end
                    return
                end
                -- AutoPerfectCatch only path (no InstantReel) - release reel guard
                _G.IsReeling = false
            end)

            return instance
        end

        -- No InstantReel/AutoPerfectCatch: release guard and return
        _G.IsReeling = false
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

local AutoReel = function(value)
    _G.Config.AutoReel = value
    if not value then
        _G.Config.InstantReel = false
    end
end
return AutoReel
