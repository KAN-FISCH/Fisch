local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local castRemote = nil
local heartbeatConn = nil
local bobberConn = nil
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
local lastTargetHrpPos = nil
local lastCalculatedCF = nil
local function GetTargetPosition(hrp, bobberPart)
    if not hrp then
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    if not hrp then return nil end
    local hrpPos = hrp.Position
    if lastTargetHrpPos and lastCalculatedCF and (hrpPos - lastTargetHrpPos).Magnitude < 2 then
        return lastCalculatedCF
    end
    local carrotSecretFolder = workspace:FindFirstChild("world")
        and workspace.world:FindFirstChild("map")
        and workspace.world.map:FindFirstChild("Carrot Secret")
    if carrotSecretFolder then
        local closestDist = math.huge
        local closestMesh = nil
        for _, model in ipairs(carrotSecretFolder:GetChildren()) do
            local mesh = model:FindFirstChild("Meshes/CarrotPool_Cube.001 (1)")
            if mesh and mesh:IsA("MeshPart") then
                local dist = (hrpPos - mesh.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestMesh = mesh
                end
            end
        end
        if closestMesh and closestDist < 50 then
            return CFrame.new(closestMesh.Position - Vector3.new(0, 3, 0))
        end
    end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Include
    Params.FilterDescendantsInstances = {workspace.Terrain}
    Params.IgnoreWater = false
    local scanY = hrpPos.Y + 50
    local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
    local lookVec = hrp.CFrame.LookVector
    local distances = {10, 15, 20, 25, 30, 35, 45}
    for _, dist in ipairs(distances) do
        local testPos = hrpPos + (lookVec * dist)
        local origin = Vector3.new(testPos.X, scanY, testPos.Z)
        local RaycastResult = workspace:Raycast(origin, Vector3.new(0, -300, 0), Params)
        if RaycastResult and RaycastResult.Instance:IsA("Terrain") and RaycastResult.Material == Enum.Material.Water then
            return CFrame.new(RaycastResult.Position - Vector3.new(0, 3, 0))
        end
    end
    local bestPos = nil
    local bestDist = math.huge
    for i = 0, 23 do
        local angle = (i / 24) * (math.pi * 2)
        local cosA = math.cos(angle)
        local sinA = math.sin(angle)
        for _, radius in ipairs({8, 12, 16, 22, 30, 40}) do
            local sx = hrpPos.X + cosA * radius
            local sz = hrpPos.Z + sinA * radius
            local result = workspace:Raycast(Vector3.new(sx, scanY, sz), Vector3.new(0, -300, 0), Params)
            if result and result.Instance:IsA("Terrain") and result.Material == Enum.Material.Water then
                if radius < bestDist then
                    bestDist = radius
                    bestPos = result.Position
                end
                break
            end
        end
    end
    local finalPos = nil
    if closestMesh and closestDist < 50 then
        finalPos = closestMesh.Position - Vector3.new(0, 3, 0)
    elseif bestPos then
        finalPos = bestPos - Vector3.new(0, 3, 0)
    else
        local basePos = head and head.Position or hrpPos
        finalPos = basePos + (lookVec * 10) - Vector3.new(0, 11, 0)
    end
    lastTargetHrpPos = hrpPos
    lastCalculatedCF = CFrame.new(finalPos)
    return lastCalculatedCF
end
local function InstantTeleportBobber(bobber, targetCF, hrp)
    if not bobber or not bobber.Parent then return targetCF end
    local humanoidRootPart = hrp or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
    local finalCF = targetCF or GetTargetPosition(humanoidRootPart, bobber)
    if not finalCF then return targetCF end
    pcall(function()
        bobber:PivotTo(finalCF)
    end)
    return finalCF
end
_G.InstantTeleportBobber = InstantTeleportBobber
_G.GetTargetPosition = GetTargetPosition
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
    if bypassCooldown then
        lastCastTick = 0
    end
    bobberRef = nil
    if bobberConn then bobberConn:Disconnect(); bobberConn = nil end
end
_G.ResetAutoCastState = resetState
task.spawn(function()
    while true do
        task.wait(1)
        if not (_G.Config and _G.Config.AutoCast) then continue end
        if _G.IsReeling then continue end
        local now = tick()
        if state == S_LOCK and lockStartTick > 0 and (now - lockStartTick > 4) then
            pcall(function()
                local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
                local dropRod = events and (events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber"))
                if dropRod then dropRod:FireServer() end
            end)
            resetState(true)
        end
    end
end)
local MIN_CAST_INTERVAL = 0.25
local function doCast(rod, hrp)
    local now = tick()
    if now - lastCastTick < MIN_CAST_INTERVAL then return end
    local remote = getCastRemote()
    if not remote then return end
    lastCastTick = now
    state = S_WAIT
    bobberHandled = false
    lockedCF = nil
    bobberRef = nil
    task.spawn(function()
        pcall(function()
            local power = (math.random(10) > 7) and math.random(95, 99) or 100
            local perfect = math.random(100) <= (type(_G.Config.perfectCastEnabled) == "number" and _G.Config.perfectCastEnabled or 0)
            remote:InvokeServer(power, perfect)
        end)
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
        if _G.IsReeling then return end
        if char:GetAttribute("Reeling") then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local reelGui = playerGui and playerGui:FindFirstChild("reel")
            local shakeui = playerGui and playerGui:FindFirstChild("shakeui")
            local isActivelyReeling = (reelGui and reelGui.Enabled) or (shakeui and shakeui.Enabled)
            if isActivelyReeling then
                return
            end
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
            doCast(rod, hrp)
        elseif state == S_WAIT then
            local b = rod:FindFirstChild("bobber") or rod:FindFirstChild("Bobber")
            if b and b.Parent then
                bobberHandled = true
                if _G.Config and _G.Config.InstantCast then
                    lockedCF = InstantTeleportBobber(b, nil, hrp)
                end
                bobberRef = b
                state = S_LOCK
                lockStartTick = tick()
            elseif now - lastCastTick > 0.85 then
                state = S_CAST
            end
        elseif state == S_LOCK then
            if _G.Config and _G.Config.InstantCast and lockedCF and bobberRef and bobberRef.Parent then
                pcall(function()
                    bobberRef:PivotTo(lockedCF)
                end)
            end
            if lockStartTick > 0 and (now - lockStartTick > 4) then
                pcall(function()
                    local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
                    local dropRod = events and (events:FindFirstChild("drop_bobber") or events:FindFirstChild("DropBobber"))
                    if dropRod then dropRod:FireServer() end
                end)
                resetState()
                return
            end
            if not (bobberRef and bobberRef.Parent) then
                local reelStarting = _G.IsReeling or char:GetAttribute("Reeling")
                if reelStarting then
                    return
                end
                if not _G._bobberGoneTick then
                    _G._bobberGoneTick = now
                end
                if now - _G._bobberGoneTick < 0.15 then
                    return
                end
                _G._bobberGoneTick = nil
                resetState()
                return
            else
                _G._bobberGoneTick = nil
            end
        end
    end)
end
task.spawn(startLoop)
local AutoCast = function(value)
    _G.Config.AutoCast = value
    if not value then resetState() end
end
return AutoCast