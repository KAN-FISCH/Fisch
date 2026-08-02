local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local previousLocation = nil
local teleportData = {}

local function getTpSpots()
    local world = workspace:FindFirstChild("world")
    local spawns = world and world:FindFirstChild("spawns")
    local TpSpotsFolder = spawns and spawns:FindFirstChild("TpSpots")

    if not TpSpotsFolder then
        return {"None"}
    end

    local spots = {}
    for _, spot in pairs(TpSpotsFolder:GetChildren()) do
        if spot:IsA("Part") or spot:IsA("CFrameValue") then
            table.insert(spots, spot.Name)
            if spot:IsA("Part") then
                teleportData[spot.Name] = spot.CFrame
            elseif spot:IsA("CFrameValue") then
                teleportData[spot.Name] = spot.Value
            end
        end
    end
    table.sort(spots)
    table.insert(spots, 1, "None")
    return spots
end

local function teleportTo(areaName)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    if areaName == "None" and previousLocation then
        HumanoidRootPart.CFrame = previousLocation
        return
    end

    local targetCFrame = teleportData[areaName]
    if targetCFrame then
        previousLocation = HumanoidRootPart.CFrame
        HumanoidRootPart.CFrame = targetCFrame
    end
end

local function teleportToCoords(x, y, z)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    end
end

local BALLOON_SPOTS = {
    {name = "Balon 1",  pos = Vector3.new(201.9, 162, -33.7)},
    {name = "Balon 2",  pos = Vector3.new(1005, 131, -1234)},
    {name = "Balon 3",  pos = Vector3.new(-2800, 260, 1550)},
    {name = "Balon 4",  pos = Vector3.new(-1244, 131, 1594)},
    {name = "Balon 5",  pos = Vector3.new(-2001, 190, 389)},
    {name = "Balon 6",  pos = Vector3.new(-1129, 228, -1158)},
    {name = "Balon 7",  pos = Vector3.new(1237, 140, 551)},
    {name = "Balon 8",  pos = Vector3.new(2747, 142, -785)},
    {name = "Balon 9",  pos = Vector3.new(-3881, 131, 326)},
    {name = "Balon 10", pos = Vector3.new(-1804, 188, 256)},
    {name = "Balon 11", pos = Vector3.new(-9.5, 157, -1079)},
    {name = "Balon 12", pos = Vector3.new(545, 295, -1887)},
    {name = "Balon 13", pos = Vector3.new(-2015, 224, -496)},
    {name = "Balon 14", pos = Vector3.new(506, 172, 220)},
    {name = "Balon 15", pos = Vector3.new(1742, 141, -2481)},
    {name = "Balon 16", pos = Vector3.new(1742, 141, -2481)},
    {name = "Balon 17", pos = Vector3.new(106, 184, 2074)},
    {name = "Balon 18", pos = Vector3.new(3019, -130, 2451)},
    {name = "Balon 19", pos = Vector3.new(5934, 259, 216)},
    {name = "Balon 20", pos = Vector3.new(-1520, 130, 2194)},
}

local function teleportToBalloon(index)
    local spot = BALLOON_SPOTS[index]
    if not spot then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(spot.pos)
    end
end

local function GetTpSpotList()
    return getTpSpots()
end

local function GetBalloonList()
    local names = {}
    for _, v in ipairs(BALLOON_SPOTS) do
        table.insert(names, v.name)
    end
    return names
end

return {
    TeleportTo = teleportTo,
    TeleportToCoords = teleportToCoords,
    TeleportToBalloon = teleportToBalloon,
    GetTpSpotList = GetTpSpotList,
    GetBalloonList = GetBalloonList,
    BalloonSpots = BALLOON_SPOTS,
}
