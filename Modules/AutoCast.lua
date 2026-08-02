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
local lockStartTick = 0
local castPending = false
local bobberHandled = false
local lockedCF = nil
local bobberRef = nil

local THROTTLE = 0.01

local function cleanConstraints(char, bobber)
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("RopeConstraint") or v:IsA("RodConstraint") or v:IsA("SpringConstraint") then
                pcall(function()
                    v.Length = 99999
                end)
            end
        end
    end
    if bobber then
        for _, v in ipairs(bobber:GetDescendants()) do
            if v:IsA("RopeConstraint") or v:IsA("RodConstraint") or v:IsA("SpringConstraint") then
                pcall(function()
                    v.Length = 99999
                end)
            end
        end
    end
end

-- Bersihkan SEMUA ShieldWorldAtt dari Terrain (cegah menumpuk!)
local function cleanupWorldAttachments()
    pcall(function()
        for _, child in ipairs(workspace.Terrain:GetChildren()) do
            if child.Name == "ShieldWorldAtt" then
                child:Destroy()
            end
        end
    end)
end

-- Dynamic Cast Remote Fetcher with Retry
local function getCastRemote()
    if castRemote and castRemote.Parent then return castRemote end
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local pkg = rep:FindFirstChild("packages")
        local net = pkg and pkg:FindFirstChild("Net")
        if net then
            castRemote = net:FindFirstChild("RF/FishingRod/Cast")
        end
        if not castRemote then
            castRemote = rep:WaitForChild("packages", 5)
                :WaitForChild("Net", 5)
                :WaitForChild("RF/FishingRod/Cast", 5)
        end
    end)
    return castRemote
end

-- Rod helper: Cek Character -> Backpack auto-equip -> Tool fallback
local function getRod(char)
    if not char then return nil end
    local rodName = nil
    pcall(function()
        rodName = workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
    end)
    
    if rodName and rodName ~= "" then
        local rod = char:FindFirstChild(rodName)
        if rod then return rod end
    end
    
    -- Fallback: return sebarang Tool di Character
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v
        end
    end
    
    return nil
end

local function resetState(bypassCooldown)
    state = S_CAST
    castPending = false
    bobberHandled = false
    lockedCF = nil
    lockStartTick = 0
    _G.LastCatchTick = 0
    if bypassCooldown then
        lastCastTick = 0
    end
    bobberRef = nil
    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
    -- Bersihkan SEMUA world attachments (cegah menumpuk di Terrain!)
    cleanupWorldAttachments()
end
_G.ResetAutoCastState = resetState

-- AutoCast Watchdog: recover dari state S_LOCK/S_WAIT yang stuck (bug long-running)
task.spawn(function()
    while true do
        task.wait(10)
        if not (_G.Config and _G.Config.AutoCast) then continue end
        if _G.IsReeling then continue end
        -- Jika S_LOCK sudah > 15 detik tanpa bite, force reset
        if state == S_LOCK and lockStartTick > 0 and (tick() - lockStartTick > 15) then
            resetState(true)
        end
        -- Jika S_WAIT sudah > 5 detik, force reset (termasuk bobberHandled=true dead state!)
        if state == S_WAIT and lastCastTick > 0 and (tick() - lastCastTick > 5) then
            resetState(true)
        end
        -- Jika castPending sudah > 3 detik, clear
        if castPending and lastCastTick > 0 and (tick() - lastCastTick > 3) then
            castPending = false
            state = S_CAST
        end
    end
end)

local function lockBobber(bobber, cf, hrp)
    if not bobber or not bobber.Parent then return end
    local isLocked = false
    if _G.Config and _G.Config.InstantCast and IB then
        local finalCF = IB.InstantTeleportBobber(bobber, cf, hrp)
        if finalCF then
            lockedCF = finalCF
            -- Bersihkan SEMUA world attachments SEBELUM buat yang baru!
            cleanupWorldAttachments()
            
            local createOk = pcall(function()
                -- Bersihkan constraints lama di bobber
                local existing = bobber:FindFirstChild("ShieldBobberLock")
                if existing then existing:Destroy() end
                local existingAtt = bobber:FindFirstChild("ShieldBobberAtt")
                if existingAtt then existingAtt:Destroy() end

                -- World attachment (anchor di Terrain)
                local worldAtt = Instance.new("Attachment")
                worldAtt.Name = "ShieldWorldAtt"
                worldAtt.WorldCFrame = finalCF
                worldAtt.Parent = workspace.Terrain

                -- Bobber attachment
                local bobberAtt = Instance.new("Attachment")
                bobberAtt.Name = "ShieldBobberAtt"
                bobberAtt.Position = Vector3.zero
                bobberAtt.Parent = bobber

                -- AlignPosition: menahan bobber di posisi tanpa fight physics setiap frame
                local ap = Instance.new("AlignPosition")
                ap.Name = "ShieldBobberLock"
                ap.Attachment0 = bobberAtt
                ap.Attachment1 = worldAtt
                ap.MaxForce = math.huge
                ap.MaxVelocity = math.huge
                ap.Responsiveness = 200
                ap.RigidityEnabled = true
                ap.Parent = bobber

                bobber.CanCollide = false
                -- cleanConstraints hanya sekali saat lock
                cleanConstraints(LocalPlayer.Character, bobber)
            end)
            
            -- isLocked hanya true jika pcall SUKSES!
            isLocked = createOk
            if not createOk then
                lockedCF = nil
                cleanupWorldAttachments()
            end
        else
            lockedCF = nil
        end
    else
        lockedCF = nil
    end
    
    bobberRef = bobber
    if isLocked then
        state = S_LOCK
        lockStartTick = tick()
    else
        -- Lock gagal: JANGAN stay di S_WAIT dead state
        -- Langsung reset agar bisa cast ulang
        state = S_CAST
        castPending = false
        bobberHandled = false
        lockedCF = nil
        bobberRef = nil
        cleanupWorldAttachments()
    end
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

local MIN_CAST_INTERVAL = 0.05 -- Ultra-fast cast interval

local function doCast(rod, hrp)
    if tick() - lastCastTick < MIN_CAST_INTERVAL then return end
    local remote = getCastRemote()
    if not remote then return end
    castPending = true
    
    lastCastTick = tick()
    state = S_WAIT
    bobberHandled = false
    lockedCF = nil
    bobberRef = nil
    
    -- Bersihkan world attachments SEBELUM cast baru!
    cleanupWorldAttachments()
    
    watchBobber(rod, hrp)

    task.spawn(function()
        pcall(function()
            local power = (math.random(10) > 7) and math.random(95, 99) or 100
            local perfect = math.random(100) <= (type(_G.Config.perfectCastEnabled) == "number" and _G.Config.perfectCastEnabled or 0)
            remote:InvokeServer(power, perfect)
        end)
        castPending = false
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
        
        -- Protection: jangan ganggu reel yang sedang aktif
        if _G.IsReeling then return end

        -- Jika Reeling attribute masih aktif setelah reel selesai, cek apakah stuck
        if char:GetAttribute("Reeling") then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local reelGui = playerGui and playerGui:FindFirstChild("reel")
            local shakeui = playerGui and playerGui:FindFirstChild("shakeui")
            local rod = getRod(char)
            local hasBobber = rod and rod:FindFirstChild("bobber")
            local isActivelyReeling = (reelGui and reelGui.Enabled) or (shakeui and shakeui.Enabled) or hasBobber
            if isActivelyReeling then
                return -- reel masih aktif, jangan ganggu
            end
            -- Benar-benar stuck, bersihkan
            pcall(function() char:SetAttribute("Reeling", nil) end)
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rod = getRod(char)
        if not rod then
            resetState()
            return
        end

        if state == S_CAST then
            if not castPending then
                doCast(rod, hrp)
            elseif now - lastCastTick > 0.3 then
                -- Watchdog: casting stuck
                castPending = false
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
                elseif now - lastCastTick > 0.3 then
                    -- timeout, cast lagi
                    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
                    state = S_CAST
                    castPending = false
                end
            else
                -- bobberHandled = true tapi state masih S_WAIT (lockBobber gagal)
                -- Timeout 2 detik lalu reset
                if now - lastCastTick > 2 then
                    resetState(true)
                end
            end

        elseif state == S_LOCK then
            -- Watchdog: jika S_LOCK > 10 detik tanpa bite, reset
            if lockStartTick > 0 and (now - lockStartTick > 10) then
                resetState()
                return
            end
            if not (bobberRef and bobberRef.Parent) then
                resetState(); return
            end
            -- AlignPosition constraint menahan bobber — tidak perlu CFrame setiap frame
            if _G.Config and _G.Config.InstantCast then
                local isBite = false
                pcall(function()
                    if char:GetAttribute("Reeling") then
                        isBite = true; return
                    end
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local shakeui = playerGui and playerGui:FindFirstChild("shakeui")
                    if shakeui then
                        local safezone = shakeui:FindFirstChild("safezone")
                        if safezone then
                            for _, btn in ipairs(safezone:GetChildren()) do
                                if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible then
                                    isBite = true; return
                                end
                            end
                        end
                        if shakeui.Enabled then isBite = true end
                    end
                end)
                -- Jika bobber terlalu jauh dari player saat tidak ada bite, recast
                if not isBite then
                    local flatHrp = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                    local flatBobber = Vector3.new(bobberRef.Position.X, 0, bobberRef.Position.Z)
                    if (flatHrp - flatBobber).Magnitude > 250 then
                        resetState(); return
                    end
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

local AutoCast = function(value)
    _G.Config.AutoCast = value
    if not value then resetState() end
end
return AutoCast
