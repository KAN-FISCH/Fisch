local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local previousLocation = nil
local teleportData = {}

local function getFishingZones()
    local zones = workspace:FindFirstChild("zones")
    local fishingFolder = zones and zones:FindFirstChild("fishing")
    if not fishingFolder then return {}, {} end
    local spots = {}
    local zonesData = {}
    for _, spot in pairs(fishingFolder:GetChildren()) do
        if spot:IsA("BasePart") then
            if not zonesData[spot.Name] then
                zonesData[spot.Name] = {}
                table.insert(spots, spot.Name)
            end
            table.insert(zonesData[spot.Name], spot)
        end
    end
    table.sort(spots)
    table.insert(spots, 1, "None")
    return spots, zonesData
end

local function TeleportFishingZoneNoFrezeandNoBoat(zoneName)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    local _, zonesData = getFishingZones()
    local targetParts = zonesData[zoneName]

    if not targetParts or #targetParts == 0 then
        warn("[TeleportZone] Zone not found: " .. tostring(zoneName))
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
            finalCFrame = CFrame.new(testPos.X, rayResult.Position.Y + 10, testPos.Z)
            foundValidPos = true
            break
        end
    end

    if not foundValidPos then
        local randomPart = targetParts[math.random(#targetParts)]
        finalCFrame = randomPart.CFrame + Vector3.new(0, 10, 0)
    end

    if finalCFrame then
        HumanoidRootPart.CFrame = finalCFrame
    end
end

local function GetZoneList()
    local spots, _ = getFishingZones()
    return spots
end

return {
    TeleportToZone = TeleportFishingZoneNoFrezeandNoBoat,
    GetZoneList = GetZoneList,
}
