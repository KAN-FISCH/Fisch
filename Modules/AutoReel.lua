local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function startAutoReelHook()
    if not _G.ReelLogicHooked then
        _G.ReelLogicHooked = true
        task.spawn(function()
            local success, RC = pcall(function() 
                return require(game:GetService("ReplicatedStorage").client.legacyControllers.ReelController) 
            end)
            if success and RC and RC.Update then
                if RC.StartReel then
                    local oldStartReel = RC.StartReel
                    RC.StartReel = function(self, data)
                        local catchChance = tonumber(_G.__var and _G.__var.perfectCatchEnabled) or 0
                        local isPerfect = (math.random(1, 100) <= catchChance)
                        if data then
                            data.perfect = isPerfect
                        end
                        return oldStartReel(self, data)
                    end
                end

                local oldUpdate = RC.Update
                RC.Update = function(self, dt)
                    pcall(function()
                        if not self._autoReelStart then
                            self._autoReelStart = tick()
                        end
                    end)

                    if _G.Config.ReelMode ~= "Manual" and _G.__var.barSize and _G.__var.barSize > 0 then
                        if self.AddModifier then
                            self:AddModifier("barSize", "force", _G.__var.barSize)
                            self:AddModifier("minBarSize", "force", _G.__var.barSize)
                        else
                            self.barSize = _G.__var.barSize * 10
                        end
                    end

                    pcall(function()
                        oldUpdate(self, dt)
                    end)

                    if _G.Config.AutoReel then
                        pcall(function()
                            local mode = _G.Config.ReelMode
                            local elapsed = tick() - (self._autoReelStart or tick())

                            if self._isPerfectCatch == nil then
                                local catchChance = tonumber(_G.__var and _G.__var.perfectCatchEnabled) or 100
                                self._isPerfectCatch = (math.random(1, 100) <= catchChance)
                            end

                            -- Set property bawaan gamenya agar mengikuti persentase kita
                            self.perfect = self._isPerfectCatch

                            -- Paskan bar secara visual hanya jika roll-nya perfect
                            if mode ~= "Manual" and self._isPerfectCatch then
                                self.fishPosition = self.barPosition
                            end

                            if mode == "Super Instant" then
                                self.progress = 100
                            elseif mode == "Instant" and elapsed >= 1 then
                                self.progress = 100
                            elseif mode == "5 Notif" and elapsed >= 5 then
                                self.progress = 100
                            end

                            -- Visual update agar terlihat penuh
                            if self.progress >= 100 and self.reel_progress and self.reel_progress.bar then
                                self.reel_progress.bar.Size = UDim2.fromScale(1, 1)
                            end
                        end)
                    end
                end
            end
        end)
    end
end

local function init(value)
    print("[NewFish5] AutoReel toggled:", value)
    _G.Config.AutoReel = value
    _G.__var.autoReelEnabled = value

    if value then
        startAutoReelHook()

        if _G.__var.reelConnection then
            _G.__var.reelConnection:Disconnect()
            _G.__var.reelConnection = nil
        end

        local lastReel = nil
        _G.__var.isReeling = false

        _G.__var.reelConnection = RunService.Heartbeat:Connect(function()
            if not _G.__var.autoReelEnabled then return end

            local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
            if not PlayerGui then return end

            local reel = PlayerGui:FindFirstChild('reel')
            if reel and reel ~= lastReel and not _G.__var.isReeling then
                _G.__var.isReeling = true
                lastReel = reel

                task.spawn(function()
                    -- Tunggu game yang menyelesaikan minigamenya secara natural dari ReelController
                    -- Kita hanya mengubah state `isReeling` jika reel UI sudah hilang
                    repeat task.wait(0.5) until not PlayerGui:FindFirstChild('reel')
                    _G.__var.isReeling = false
                end)
            elseif not reel then
                _G.__var.isReeling = false
            end
        end)
    else
        if _G.__var.reelConnection then
            _G.__var.reelConnection:Disconnect()
            _G.__var.reelConnection = nil
        end
    end
end

return init