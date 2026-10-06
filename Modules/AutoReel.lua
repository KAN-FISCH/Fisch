local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shieldReelHooked = false
local shieldOriginalStartReel = nil
task.spawn(function()
    if shieldReelHooked then return end
    local elapsed = 0
    while not ReplicatedStorage:FindFirstChild("client") and elapsed < 10 do
        task.wait(0.5)
        elapsed = elapsed + 0.5
    end
    if not ReplicatedStorage:FindFirstChild("client") then return end
    local ok, controller = pcall(require, ReplicatedStorage.client.legacyControllers.ReelController)
    if not ok or not controller then return end
    shieldOriginalStartReel = controller.StartReel
    shieldReelHooked = true
    if controller.Update then
        local oldUpdate = controller.Update
        controller.Update = function(self, dt)
            local barMult = (_G.__var and _G.__var.barSize) or (_G.Config and _G.Config.barSize) or 1
            if barMult and barMult > 1 then
                if self.barScale then self.barScale = math.clamp(self.barScale * barMult, 0.05, 1) end
            end
            oldUpdate(self, dt)
            if _G.Config and _G.Config.AutoReel and _G.Config.ReelMode == "Legit" then
                self.fishPosition = self.barPosition
            end
        end
    end
    task.spawn(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local function applyBarScale(gui)
            if not gui then return end
            local barMult = (_G.__var and _G.__var.barSize) or (_G.Config and _G.Config.barSize) or 1
            pcall(function()
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("GuiObject") then
                        local n = obj.Name:lower()
                        if (n == "playerbar" or n == "player_bar" or n == "whitebar" or n == "catchbar") and not obj:FindFirstChild("fish") and not obj:FindFirstChild("Fish") then
                            local baseSize = obj:GetAttribute("BaseSizeXScale")
                            if not baseSize then
                                baseSize = obj.Size.X.Scale
                                if baseSize > 0 then
                                    obj:SetAttribute("BaseSizeXScale", baseSize)
                                end
                            end
                            if baseSize and baseSize > 0 then
                                if barMult and barMult > 1 then
                                    obj.Size = UDim2.new(math.clamp(baseSize * barMult, 0.02, 1), obj.Size.X.Offset, obj.Size.Y.Scale, obj.Size.Y.Offset)
                                else
                                    obj.Size = UDim2.new(baseSize, obj.Size.X.Offset, obj.Size.Y.Scale, obj.Size.Y.Offset)
                                end
                            end
                        end
                    end
                end
            end)
        end
        local function onReelGui(rGui)
            if not rGui then return end
            rGui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if rGui.Enabled then applyBarScale(rGui) end
            end)
            if rGui.Enabled then applyBarScale(rGui) end
        end
        local rGui = playerGui:FindFirstChild("reel") or playerGui:FindFirstChild("Reel")
        if rGui then onReelGui(rGui) end
        playerGui.ChildAdded:Connect(function(child)
            if child.Name == "reel" or child.Name == "Reel" then
                onReelGui(child)
            end
        end)
    end)
    local isSnapping = false
    controller.StartReel = function(data)
        if not data or not _G.Config then
            return shieldOriginalStartReel(data)
        end
        local myReelTick = tick()
        _G.IsReeling = true
        _G.ReelStartTick = myReelTick
        if _G.ShowCatchNotification and data.fish then
            task.spawn(_G.ShowCatchNotification, data.fish)
        end
        if data.fish then
            local fish = data.fish
            local mutStr = tostring(fish.Mutation or ""):lower()
            local fishName = tostring(fish.Name or fish):lower()
            if mutStr:find("shady", 1, true) or mutStr:find("sludge", 1, true) or fishName:find("shady", 1, true) or fishName:find("sludge", 1, true) then
                _G.ShadyInInventory = true
                _G.LastShadyStartReelTime = tick()
            end
        end
        if not isSnapping and _G.__var and _G.__var.AutoSnapEnabled and _G.CheckSnapFilter then
            local char = LocalPlayer.Character
            local gameIsReeling = char and char:GetAttribute("Reeling")
            if not gameIsReeling then
                local shouldKeep = _G.CheckSnapFilter(data.fish)
                if not shouldKeep then
                    isSnapping = true
                    pcall(function()
                        local events = ReplicatedStorage:FindFirstChild("events")
                        if events then
                            local dropRod = events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber")
                            if dropRod then dropRod:FireServer() end
                        end
                    end)
                    pcall(function()
                        local pkg = ReplicatedStorage:FindFirstChild("packages")
                        local netMod = pkg and pkg:FindFirstChild("Net")
                        if netMod then
                            local okNet, Net = pcall(require, netMod)
                            if okNet and Net then
                                local finishEvent = Net:RemoteEvent("Reel/Finish")
                                if finishEvent then
                                    finishEvent:FireServer({
                                        e = -0.033138427883387,
                                        p = false,
                                        l = {},
                                        d = {}
                                    })
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
                    if _G.ReelStartTick == myReelTick then
                        _G.LastCatchTick = 0
                        _G.IsReeling = false
                        if _G.ResetAutoCastState then pcall(_G.ResetAutoCastState, true) end
                    end
                    isSnapping = false
                    return dummyInstance
                end
            end
        end
        local ok, instance = pcall(shieldOriginalStartReel, data)
        if not ok or not instance then
            if _G.ReelStartTick == myReelTick then
                _G.IsReeling = false
            end
            return instance
        end
        local barMult = (_G.__var and _G.__var.barSize) or (_G.Config and _G.Config.barSize) or 1
        if barMult and barMult > 1 then
            pcall(function()
                if instance.barScale then instance.barScale = math.clamp(instance.barScale * barMult, 0.05, 1) end
            end)
        end
        _G.LastCatchTick = tick()
        if _G.Config and (_G.Config.InstantReel or _G.Config.AutoPerfectCatch) then
            local perfectChance = 100
            if type(_G.Config.PerfectCatchChance) == "number" then
                perfectChance = _G.Config.PerfectCatchChance
            elseif type(_G.Config.perfectCatchEnabled) == "number" then
                perfectChance = _G.Config.perfectCatchEnabled
            end
            local isPerfect = (math.random(100) <= perfectChance)
            instance.perfect = isPerfect
            task.spawn(function()
                local char = LocalPlayer.Character
                if not char then return end
                if not char:GetAttribute("Reeling") then
                    local reelTimeout = 3
                    local t = 0
                    local reeling = false
                    local conn = char:GetAttributeChangedSignal("Reeling"):Connect(function()
                        reeling = char:GetAttribute("Reeling")
                    end)
                    while not reeling and t < reelTimeout do
                        task.wait(0.05)
                        t = t + 0.05
                    end
                    conn:Disconnect()
                end
                if not instance.ready then
                    local readyTimeout = 3
                    local t = 0
                    local isReady = false
                    if instance.OnReady then
                        local conn = instance.OnReady:Connect(function() isReady = true end)
                        while not isReady and t < readyTimeout do
                            task.wait(0.05)
                            t = t + 0.05
                        end
                        conn:Disconnect()
                    else
                        while not instance.ready and t < readyTimeout do
                            task.wait(0.05)
                            t = t + 0.05
                        end
                    end
                end
                if _G.Config and _G.Config.InstantReel then
                    task.wait(0.28)
                    instance.active = true
                    instance.ready = true
                    local isBreakStreak = false
                    if _G.Config and _G.Config.BreakStreakEnabled then
                        local gameStreak = 0
                        pcall(function()
                            local ps = workspace:FindFirstChild("PlayerStats")
                            local pf = ps and ps:FindFirstChild(LocalPlayer.Name)
                            local tf = pf and (pf:FindFirstChild("T") and pf.T:FindFirstChild(LocalPlayer.Name) or pf)
                            local stats = tf and (tf:FindFirstChild("Stats") or tf)
                            if stats then
                                local sVal = stats:FindFirstChild("tracker_streak") or stats:FindFirstChild("streak")
                                if sVal then gameStreak = sVal.Value end
                            end
                        end)
                        local currentStreak = (gameStreak > 0) and gameStreak or (_G.LocalCurrentStreak or _G.Config.BreakStreakCurrent or 0)
                        _G.Config.BreakStreakCurrent = currentStreak + 1
                        local targetStreak = _G.Config.BreakStreakCount or 10
                        if _G.Config.BreakStreakCurrent >= targetStreak then
                            isBreakStreak = true
                            _G.Config.BreakStreakCurrent = 0
                        end
                    end
                    pcall(function()
                        if isBreakStreak then
                            _G.LocalReelsBroken = (_G.LocalReelsBroken or 0) + 1
                            _G.LocalCurrentStreak = 0
                            instance.progress = 0
                            if typeof(instance.Finish) == "function" then
                                instance:Finish(false)
                            elseif typeof(instance.EndMinigame) == "function" then
                                instance:EndMinigame(false)
                            elseif instance.OnReelFinished then
                                instance.OnReelFinished:Fire(false)
                            end
                        else
                            _G.LocalFishCaught = (_G.LocalFishCaught or 0) + 1
                            _G.LocalCurrentStreak = (_G.LocalCurrentStreak or 0) + 1
                            if instance.perfect then
                                _G.LocalPerfectCatches = (_G.LocalPerfectCatches or 0) + 1
                            end

                            -- Auto Lullaby / Metronome Passive (Zenith Hub Style)
                            pcall(function()
                                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                local isLullaby = tool and tool.Name:lower():find("lullaby")
                                local isMetronome = (instance.reel and instance.reel:FindFirstChild("bar") 
                                    and instance.reel.bar:FindFirstChild("Details") 
                                    and instance.reel.bar.Details:FindFirstChild("Metronome")) or isLullaby

                                if _G.Config and (_G.Config.AutoMetronome or _G.Config.AutoLullaby) and isMetronome then
                                    local mode = _G.Config.LullabyMode or "Rage (100 Hits)"
                                    local hits = tonumber(_G.Config.LullabyHitCount) or 100
                                    local misses = tonumber(_G.Config.LullabyMissCount) or 0
                                    
                                    local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
                                    local remote = net and net:FindFirstChild("RE/MetronomeBuff/Input")

                                    if mode == "Rage (100 Hits)" or mode == "Custom Hits" then
                                        if remote then
                                            task.spawn(function()
                                                for i = 1, hits do
                                                    remote:FireServer(true)
                                                    task.wait(0.01)
                                                end
                                            end)
                                        end
                                        if instance.BuildEndingData then
                                            local oldInvoke = instance.BuildEndingData.InvokeAsync
                                            instance.BuildEndingData.InvokeAsync = function(self)
                                                local data = oldInvoke(self)
                                                if typeof(data) == "table" then
                                                    data.Lullaby_HitCount = hits
                                                    data.Lullaby_MissCount = misses
                                                end
                                                return data
                                            end
                                        end
                                    elseif mode == "Legit" then
                                        if remote then
                                            remote:FireServer(true)
                                        end
                                        if instance.BuildEndingData then
                                            local oldInvoke = instance.BuildEndingData.InvokeAsync
                                            instance.BuildEndingData.InvokeAsync = function(self)
                                                local data = oldInvoke(self)
                                                if typeof(data) == "table" then
                                                    data.Lullaby_HitCount = math.max(1, hits)
                                                    data.Lullaby_MissCount = misses
                                                end
                                                return data
                                            end
                                        end
                                    end
                                end
                            end)

                            instance.progress = 100
                            if typeof(instance.Finish) == "function" then
                                instance:Finish(true)
                            elseif typeof(instance.EndMinigame) == "function" then
                                instance:EndMinigame(true)
                            elseif instance.OnReelFinished then
                                instance.OnReelFinished:Fire(true)
                            end
                        end
                    end)
                    task.wait(0.05)
                    if _G.ReelStartTick == myReelTick then
                        _G.IsReeling = false
                        _G.LastCatchTick = 0
                        if _G.ResetAutoCastState then pcall(_G.ResetAutoCastState, true) end
                    end
                    return
                end
                if _G.ReelStartTick == myReelTick then
                    _G.IsReeling = false
                end
            end)
            return instance
        end
        if _G.ReelStartTick == myReelTick then
            _G.IsReeling = false
        end
        return instance
    end
    task.spawn(function()
        while true do
            task.wait(5)
            if _G.IsReeling and _G.ReelStartTick and (tick() - _G.ReelStartTick > 10) then
                _G.IsReeling = false
                isSnapping = false
                _G.LastCatchTick = 0
                if _G.ResetAutoCastState then pcall(_G.ResetAutoCastState, true) end
            end
            if isSnapping and _G.ReelStartTick and (tick() - _G.ReelStartTick > 5) then
                isSnapping = false
            end
        end
    end)
end)
local function dropAndReel()
    task.wait(0.3)
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        if events then
            local dropRod = events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber")
            if dropRod then dropRod:FireServer() end
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    dropAndReel()
end)
if LocalPlayer.Character then
    task.spawn(dropAndReel)
end
local AutoReel = function(value)
    _G.Config.AutoReel = value
    if not value then
        _G.Config.InstantReel = false
    end
end
return AutoReel