local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local previousLocation = nil

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
    local boat = workspace:FindFirstChild("active")
        and workspace.active:FindFirstChild("boats")
        and workspace.active.boats:FindFirstChild(player.Name)
        and workspace.active.boats[player.Name]:FindFirstChild("Rowboat")

    if not boat then
        HumanoidRootPart.CFrame = CFrame.new(362, 134, 259)
        task.wait(0.5)
        local args = {{
            voice = 8,
            idle = workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Moosewood Shipwright"):WaitForChild("description"):WaitForChild("idle"),
            npc = workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Moosewood Shipwright"),
        }}
        pcall(function()
            workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Moosewood Shipwright"):WaitForChild("shipwright"):WaitForChild("giveUI"):InvokeServer(unpack(args))
        end)
        task.wait(0.2)
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/Boats/Purchase"):InvokeServer("Rowboat")
        end)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/Boats/Spawn"):InvokeServer("Rowboat")
        end)
        task.wait(0.3)
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Boats/Close"):FireServer()
        end)
        task.wait(0.5)
        autoEquipRod()

        local gui = player:FindFirstChild("PlayerGui")
        local hudGui = gui and gui:FindFirstChild("hud")
        local shipwright = hudGui and hudGui:FindFirstChild("safezone") and hudGui.safezone:FindFirstChild("shipwright")
        if shipwright then shipwright.Visible = false end

        -- Re-find boat
        boat = workspace:FindFirstChild("active")
            and workspace.active:FindFirstChild("boats")
            and workspace.active.boats:FindFirstChild(player.Name)
            and workspace.active.boats[player.Name]:FindFirstChild("Rowboat")
    end

    return boat
end

local function teleportToFishingZone(zoneName)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    if zoneName == "None" and previousLocation then
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
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {Character}
        rayParams.IgnoreWater = false
        local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -2000, 0), rayParams)
        if rayResult and rayResult.Material == Enum.Material.Water then
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
        if name == "sitprompt" or name == "body" then descendant:Destroy() end
    end

    -- Adjust to water level
    local checkParams = RaycastParams.new()
    checkParams.FilterType = Enum.RaycastFilterType.Whitelist
    checkParams.FilterDescendantsInstances = {workspace.Terrain}
    checkParams.IgnoreWater = false

    for i = 1, 3 do
        local fp = finalCFrame.Position
        local waterCheck = workspace:Raycast(Vector3.new(fp.X, 500, fp.Z), Vector3.new(0, -1000, 0), checkParams)
        if waterCheck and waterCheck.Material == Enum.Material.Water then
            finalCFrame = CFrame.new(fp.X, waterCheck.Position.Y + 3.5, fp.Z)
        end
        task.wait(0.1)
    end

    boat:PivotTo(finalCFrame)
    task.wait(0.5)
    boat:PivotTo(finalCFrame)

    -- Auto equip rod
    task.wait(0.3)
    autoEquipRod()
    FreezeCharacter(true)
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
