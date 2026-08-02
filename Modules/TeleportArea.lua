local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local previousLocation = nil
local lastTargetCFrame = nil

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if lastTargetCFrame then
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if humanoid and hrp then
                    -- Cari boat player secara dinamis
                    local active = workspace:FindFirstChild("active")
                    local boats = active and active:FindFirstChild("boats")
                    local myBoats = boats and boats:FindFirstChild(LocalPlayer.Name)
                    local boat = myBoats and (myBoats:FindFirstChild("Rowboat") or myBoats:FindFirstChildOfClass("Model"))
                    
                    if boat then
                        local boatCF = boat:GetPivot()
                        -- Jika tinggi Y player jatuh di bawah dek kapal (2.5 studs di bawah pivot kapal)
                        if hrp.Position.Y < boatCF.Y - 2.5 then
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            hrp.CFrame = boatCF + Vector3.new(0, 5, 0)
                            warn("[TeleportArea] Player fell below boat! Teleporting back onto deck.")
                        end
                    else
                        -- Jika tidak ada kapal, teleport jika jatuh terlalu dalam dari target awal
                        if humanoid:GetState() == Enum.HumanoidStateType.Swimming and hrp.Position.Y < lastTargetCFrame.Y - 5 then
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            hrp.CFrame = lastTargetCFrame + Vector3.new(0, 5, 0)
                            warn("[TeleportArea] Swimming in deep water! Teleporting back to spot.")
                        end
                    end
                end
            end
        end)
    end
end)

local cachedWaterParts = nil
local lastCacheTime = 0
local CACHE_LIFETIME = 15

local function getWaterParts()
    local now = tick()
    if cachedWaterParts and (now - lastCacheTime) < CACHE_LIFETIME then
        local active = {}
        for _, part in ipairs(cachedWaterParts) do
            if part and part.Parent then
                table.insert(active, part)
            end
        end
        return active
    end

    cachedWaterParts = {workspace.Terrain}
    lastCacheTime = now

    local function scanParts(parent, depth)
        if depth > 4 then return end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:match("water") or n:match("pool") or n:match("ocean") or n:match("lake") or n:match("river") or n:match("sea") or parent.Name:lower():find("fishing") then
                    table.insert(cachedWaterParts, v)
                end
            elseif v:IsA("Model") or v:IsA("Folder") then
                scanParts(v, depth + 1)
            end
        end
    end

    local world = workspace:FindFirstChild("world")
    local map = world and world:FindFirstChild("map")
    if map then
        pcall(scanParts, map, 0)
    end
    
    local zones = workspace:FindFirstChild("zones")
    if zones then
        local fishing = zones:FindFirstChild("fishing")
        if fishing then
            pcall(scanParts, fishing, 0)
        end
    end

    return cachedWaterParts
end

local function getFishingZones()
    local zones = workspace:FindFirstChild("zones")
    local fishingFolder = zones and zones:FindFirstChild("fishing")
    if not fishingFolder then return {}, {} end
    local positions = {}
    for _, z in pairs(fishingFolder:GetChildren()) do
        if z:IsA("BasePart") then
            if not positions[z.Name] then positions[z.Name] = {} end
            table.insert(positions[z.Name], z)
        elseif z:IsA("Model") then
            for _, p in pairs(z:GetChildren()) do
                if p:IsA("BasePart") then
                    if not positions[z.Name] then positions[z.Name] = {} end
                    table.insert(positions[z.Name], p)
                end
            end
        end
    end
    local list = {}
    for k in pairs(positions) do table.insert(list, k) end
    table.sort(list)
    return list, positions
end

local function FreezeCharacter(freeze)
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = freeze end
    end
end

local function autoEquipRod()
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Rod") or tool.Name:find("Fishing")) then
            char.Humanoid:EquipTool(tool)
            break
        end
    end
end

local function spawnBoatIfNeeded(Character, HumanoidRootPart)
    local player = LocalPlayer
    local active = workspace:FindFirstChild("active")
    local boats = active and active:FindFirstChild("boats")
    local myBoats = boats and boats:FindFirstChild(player.Name)
    local boat = myBoats and (myBoats:FindFirstChild("Rowboat") or myBoats:FindFirstChildOfClass("Model"))

    if not boat then
        -- Find shipwright NPC secara dinamis
        local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
        local shipwright = nil
        if npcs then
            for _, npc in ipairs(npcs:GetChildren()) do
                if npc.Name:lower():find("shipwright") then
                    shipwright = npc
                    break
                end
            end
        end
        if not shipwright and npcs then
            shipwright = npcs:WaitForChild("Moosewood Shipwright", 2)
        end
        if not shipwright then
            -- Fallback: return nil agar player di-teleport langsung
            warn("[TeleportArea] Shipwright NPC not found!")
            return nil
        end

        HumanoidRootPart.CFrame = CFrame.new(362, 134, 259)
        task.wait(0.5)

        local description = shipwright:FindFirstChild("description")
        local idle = description and description:FindFirstChild("idle")
        local shipwrightRF = shipwright:FindFirstChild("giveUI", true)

        if shipwrightRF then
            local args = {{
                voice = 8,
                idle = idle,
                npc = shipwright,
            }}
            pcall(function()
                shipwrightRF:InvokeServer(unpack(args))
            end)
        end
        task.wait(0.2)

        local net = game:GetService("ReplicatedStorage"):WaitForChild("packages", 2)
            and game:GetService("ReplicatedStorage").packages:WaitForChild("Net", 2)
        
        local purchaseRF = net and net:WaitForChild("RF/Boats/Purchase", 2)
        if purchaseRF then
            pcall(function()
                purchaseRF:InvokeServer("Rowboat")
            end)
        end
        task.wait(0.5)

        local spawnRF = net and net:WaitForChild("RF/Boats/Spawn", 2)
        if spawnRF then
            pcall(function()
                spawnRF:InvokeServer("Rowboat")
            end)
        end
        task.wait(0.3)

        local closeRE = net and net:WaitForChild("RE/Boats/Close", 2)
        if closeRE then
            pcall(function()
                closeRE:FireServer()
            end)
        end
        task.wait(0.5)
        autoEquipRod()

        local gui = player:FindFirstChild("PlayerGui")
        local hudGui = gui and gui:FindFirstChild("hud")
        local shipwrightGui = hudGui and hudGui:FindFirstChild("safezone") and hudGui.safezone:FindFirstChild("shipwright")
        if shipwrightGui then shipwrightGui.Visible = false end

        -- Re-find boat
        active = workspace:FindFirstChild("active")
        boats = active and active:FindFirstChild("boats")
        myBoats = boats and boats:FindFirstChild(player.Name)
        boat = myBoats and (myBoats:FindFirstChild("Rowboat") or myBoats:FindFirstChildOfClass("Model"))
    end

    return boat
end

local function teleportToFishingZone(zoneName)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    if zoneName == "None" and previousLocation then
        lastTargetCFrame = nil
        HumanoidRootPart.CFrame = previousLocation
        FreezeCharacter(false)
        return
    end

    local _, zonesData = getFishingZones()

    local targetParts = zonesData[zoneName]
    if not targetParts or #targetParts == 0 then
        warn("[TeleportArea] Zone not found: " .. tostring(zoneName))
        return
    end

    local foundValidPos = false
    local finalCFrame = nil

    local waterParts = getWaterParts()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = waterParts
    rayParams.IgnoreWater = false

    for i = 1, 10 do
        local randomPart = targetParts[math.random(#targetParts)]
        local size = randomPart.Size
        local cf = randomPart.CFrame
        local randomOffset = Vector3.new(
            math.random() * size.X - size.X / 2,
            0,
            math.random() * size.Z - size.Z / 2
        )
        local testPos = (cf * CFrame.new(randomOffset)).Position
        local rayOrigin = Vector3.new(testPos.X, testPos.Y + 1000, testPos.Z)
        
        local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -2000, 0), rayParams)
        if rayResult then
            local heightOffset = (zoneName == "Forsaken Veil") and 80 or 0
            finalCFrame = CFrame.new(testPos.X, rayResult.Position.Y + heightOffset, testPos.Z)
            foundValidPos = true
            break
        end
    end

    if not foundValidPos then
        local randomPart = targetParts[math.random(#targetParts)]
        finalCFrame = randomPart.CFrame + Vector3.new(0, 5, 0)
    end

    previousLocation = HumanoidRootPart.CFrame

    -- Get or spawn boat
    local boat = spawnBoatIfNeeded(Character, HumanoidRootPart)

    if not boat then
        -- Fallback: teleport player directly
        if finalCFrame then HumanoidRootPart.CFrame = finalCFrame end
        return
    end

    -- Remove boat sit prompts
    for _, descendant in ipairs(boat:GetDescendants()) do
        local name = descendant.Name:lower()
        if name == "sitprompt" then descendant:Destroy() end
    end

    -- Adjust to water level
    local checkParams = RaycastParams.new()
    checkParams.FilterType = Enum.RaycastFilterType.Include
    checkParams.FilterDescendantsInstances = waterParts
    checkParams.IgnoreWater = false

    for i = 1, 3 do
        local fp = finalCFrame.Position
        local waterCheck = workspace:Raycast(Vector3.new(fp.X, 500, fp.Z), Vector3.new(0, -1000, 0), checkParams)
        if waterCheck then
            finalCFrame = CFrame.new(fp.X, waterCheck.Position.Y + 5.5, fp.Z)
        end
        task.wait(0.1)
    end

    boat:PivotTo(finalCFrame)
    HumanoidRootPart.CFrame = finalCFrame + Vector3.new(0, 5.0, 0)
    task.wait(0.5)
    boat:PivotTo(finalCFrame)
    HumanoidRootPart.CFrame = finalCFrame + Vector3.new(0, 5.0, 0)

    -- Auto equip rod
    task.wait(0.3)
    autoEquipRod()
    FreezeCharacter(false)
    lastTargetCFrame = finalCFrame
end

local function GetZoneList()
    local list, _ = getFishingZones()
    table.insert(list, 1, "None")
    table.insert(list, "Crystal Cove")
    return list
end

return {
    TeleportToZone = teleportToFishingZone,
    GetZoneList = GetZoneList,
    GetFishingZones = getFishingZones,
}
