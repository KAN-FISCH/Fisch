local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Helper getMod loader (no script dependency)
local function getMod(name)
    if _G.getMod then return _G.getMod(name) end
    local core = game:GetService("ReplicatedStorage"):FindFirstChild("Shield_Core")
    if core then
        local folder = core:FindFirstChild(name)
        if folder then
            local src = ""
            if folder:IsA("Folder") then
                for i = 1, #folder:GetChildren() do
                    local chunk = folder:FindFirstChild(tostring(i))
                    if chunk then src = src .. chunk.Value end
                end
            else
                src = folder.Value
            end
            local fn, err = loadstring(src)
            if not fn then
                warn("[NewFish5] Failed to load module '" .. tostring(name) .. "': " .. tostring(err))
                return nil
            end
            local success, res = pcall(fn)
            if not success then
                warn("[NewFish5] Error executing module '" .. tostring(name) .. "': " .. tostring(res))
                return nil
            end
            return res
        end
    end
    return nil
end

local function Init(Main, SAVEPOSTION, NPCSection, BallonSection)

    ---------------------------------------------------------
    -- 1. NPC Teleport Section
    ---------------------------------------------------------
    local cachedNpcLocations = {}
    local knownLocations = {
        ["Angler (Moosewood)"] = CFrame.new(481, 151, 299),
        ["Angler (Roslit)"] = CFrame.new(-1512, 140, 688),
        ["Angler (Sunstone)"] = CFrame.new(-885, 135, -1115),
        ["Angler (Terrapin)"] = CFrame.new(-153, 144, 1954),
        ["Angler (Depths)"] = CFrame.new(980, -700, 1230),
        ["Angler (Ancient)"] = CFrame.new(5737, 177, -57),
        ["Angler (Forsaken)"] = CFrame.new(-2702, 169, 1798),
        ["Angler (Crimson)"] = CFrame.new(-1069, -361, -4811),
        ["Angler (Luminescent)"] = CFrame.new(-1050, -337, -4078),
        ["Angler (Jungle)"] = CFrame.new(-2726, 226, -2186),
        ["Merlin"] = CFrame.new(-929, 224, -996),
        ["Pierre"] = CFrame.new(387, 133, 258),
        ["Halt"] = CFrame.new(-1319, 133, 412),
        ["Appraiser (Roslit)"] = CFrame.new(-1644, 137, 727),
        ["Appraiser (Moosewood)"] = CFrame.new(446, 150, 230),
        ["Appraiser (Terrapin)"] = CFrame.new(-109, 157, 1956),
    }

    for n, c in pairs(knownLocations) do
        cachedNpcLocations[n] = c
    end

    local function cacheCurrentNpcs()
        local world = workspace:FindFirstChild("world")
        local npcs = world and world:FindFirstChild("npcs")
        if npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                if npc:IsA("Model") then
                    local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                    if root then
                        cachedNpcLocations[npc.Name] = root.CFrame
                    end
                end
            end
        end
    end

    local npcNames = {}
    local function updateNpcList()
        cacheCurrentNpcs()
        npcNames = {}
        for name in pairs(cachedNpcLocations) do
            table.insert(npcNames, name)
        end
        table.sort(npcNames)
    end
    updateNpcList()

    local selectedNpcToTp = nil
    local NpcDropdown = NPCSection:AddDropdown({
        Title = "Select NPC",
        Options = npcNames,
        Default = "None",
        Callback = function(Value)
            selectedNpcToTp = Value
        end
    })

    NPCSection:AddButton({
        Title = "Teleport",
        Callback = function()
            if not selectedNpcToTp then return end
            local targetCFrame = cachedNpcLocations[selectedNpcToTp]
            local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            local npc = npcs and npcs:FindFirstChild(selectedNpcToTp)
            if npc then
                local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                if root then
                    targetCFrame = root.CFrame
                end
            end

            if targetCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
            else
                print("NPC location unknown or character not ready.")
            end
        end
    })

    NPCSection:AddButton({
        Title = "Refresh NPC List",
        Callback = function()
            updateNpcList()
            pcall(function()
                if NpcDropdown.SetValues then
                    NpcDropdown:SetValues(npcNames)
                elseif NpcDropdown.SetOptions then
                    NpcDropdown:SetOptions(npcNames)
                elseif NpcDropdown.Refresh then
                    NpcDropdown:Refresh(npcNames)
                end
            end)
        end
    })

    ---------------------------------------------------------
    -- 2. Main (Area TP) Section
    ---------------------------------------------------------
    local previousLocation = nil
    local teleportData = {}

    local function getTpSpots()
        local world = workspace:FindFirstChild("world")
        local spawns = world and world:FindFirstChild("spawns")
        local TpSpotsFolder = spawns and spawns:FindFirstChild("TpSpots")

        if not TpSpotsFolder then
            return { "None" }
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

    local teleportSpots = getTpSpots()
    Main:AddDropdown({
        Title = "TP Area",
        Content = "Choose an area to teleport",
        Options = teleportSpots,
        Default = "None",
        Callback = function(selected)
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if selected == "None" and previousLocation then
                hrp.CFrame = previousLocation
                return
            end

            local targetCFrame = teleportData[selected]
            if targetCFrame then
                previousLocation = hrp.CFrame
                hrp.CFrame = targetCFrame
            end
        end
    })

    local tpCoord = nil
    Main:AddInput({
        Title = "Teleport Coordinate",
        Default = "",
        Callback = function(val)
            if val and val ~= "" then
                local numbers = {}
                for num in string.gmatch(val, "[-%d%.]+") do
                    table.insert(numbers, tonumber(num))
                end
                if #numbers >= 3 then
                    tpCoord = Vector3.new(numbers[1], numbers[2], numbers[3])
                end
            end
        end
    })

    Main:AddButton({
        Title = "Teleport Coords",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and tpCoord then
                char.HumanoidRootPart.CFrame = CFrame.new(tpCoord)
            end
        end
    })

    -- Fishing Zone Teleport
    local function getFishingZones()
        local zones = workspace:FindFirstChild("zones")
        local FishingZonesFolder = zones and zones:FindFirstChild("fishing")
        if not FishingZonesFolder then
            return { 'None' }, {}
        end
        local spots = {}
        local zonesData = {}
        for _, spot in pairs(FishingZonesFolder:GetChildren()) do
            if spot:IsA('Part') then
                if not zonesData[spot.Name] then
                    zonesData[spot.Name] = {}
                    table.insert(spots, spot.Name)
                end
                table.insert(zonesData[spot.Name], spot)
            end
        end
        table.sort(spots)
        table.insert(spots, 1, 'None')
        return spots, zonesData
    end

    local fishingSpots, zonesData = getFishingZones()
    local function AddZone(name)
        for _, spot in ipairs(fishingSpots) do
            if spot == name then return end
        end
        table.insert(fishingSpots, name)
    end
    AddZone("Crystal Cove")

    local function TeleportFishingZoneNoFrezeandNoBoat(zoneName)
        local Character = LocalPlayer.Character
        if not Character then return end
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local _, currentZones = getFishingZones()
        local targetParts = currentZones[zoneName]

        if targetParts and #targetParts > 0 then
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
                rayParams.FilterDescendantsInstances = { Character }
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
                hrp.CFrame = finalCFrame
            end
        end
    end

    local zoneDropdown = Main:AddDropdown({
        Title = "Teleport Zone",
        Content = "Teleport to selected zone",
        Options = fishingSpots,
        Default = _G.Config.selectedZone or "None",
        Callback = function(selected)
            _G.Config.selectedZone = selected
        end
    })
    if getgenv().regUIElement then
        getgenv().regUIElement(zoneDropdown, "selectedZone", function(selected)
            _G.Config.selectedZone = selected
        end)
    end

    Main:AddButton({
        Title = "Teleport Zone",
        Content = "Teleport to selected zone",
        Callback = function()
            if _G.Config.selectedZone and _G.Config.selectedZone ~= "None" then
                task.spawn(function()
                    TeleportFishingZoneNoFrezeandNoBoat(_G.Config.selectedZone)
                end)
            end
        end
    })

    -- Player Teleport
    local selectedPlayer = "None"
    local function getPlayerNames()
        local names = {"None"}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end

    local teleportPlayerDropdown
    teleportPlayerDropdown = Main:AddDropdown({
        Title = "Teleport Player",
        Options = getPlayerNames(),
        Default = "None",
        Callback = function(selected)
            selectedPlayer = selected
        end
    })

    local function breakVelocity()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local function teleportToPlayer(playerName)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetPlayer = Players:FindFirstChild(playerName)
        if not root or not targetPlayer or not targetPlayer.Character then return end
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local targetCFrame = targetRoot.CFrame + Vector3.new(3, 1, 0)
        root.Anchored = true
        task.wait(0.05)
        local distance = (root.Position - targetRoot.Position).Magnitude
        if distance > 500 then
            local midPoint = root.CFrame:Lerp(targetCFrame, 0.5)
            root.CFrame = midPoint
            task.wait(0.1)
        end
        root.CFrame = targetCFrame
        task.wait(0.05)
        root.Anchored = false
        breakVelocity()
    end

    Main:AddButton({
        Title = "Teleport ke Pemain",
        Callback = function()
            if selectedPlayer ~= "None" then
                teleportToPlayer(selectedPlayer)
            end
        end
    })

    ---------------------------------------------------------
    -- 3. Ballon Teleport Section
    ---------------------------------------------------------
    local BalloonSpots = {
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

    BallonSection:AddSeperator({
        Title = 'Ballon Teleport',
    })

    local function teleportToBallonPos(pos)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end

    for idx, spot in ipairs(BalloonSpots) do
        BallonSection:AddButton({
            Title = "Teleport ke " .. spot.name,
            Callback = function()
                teleportToBallonPos(spot.pos)
            end
        })
    end

    ---------------------------------------------------------
    -- 4. SAVEPOSTION Section
    ---------------------------------------------------------
    local savedPositions = {}
    local savedPositionName = "SHIELD"
    local selectedPosition = "None"
    local saveFileName = "saved_positions_shieldteam.json"

    local function loadSavedPositions()
        local success, result = pcall(function()
            if isfile and isfile(saveFileName) then
                local jsonData = readfile(saveFileName)
                return HttpService:JSONDecode(jsonData)
            end
            return {}
        end)
        if success and type(result) == "table" then
            return result
        end
        return {}
    end

    local function savePositionsToFile()
        pcall(function()
            if writefile then
                local jsonData = HttpService:JSONEncode(savedPositions)
                writefile(saveFileName, jsonData)
            end
        end)
    end

    savedPositions = loadSavedPositions()

    local function getPositionNames()
        local names = {"None"}
        for name in pairs(savedPositions) do
            table.insert(names, name)
        end
        return names
    end

    SAVEPOSTION:AddInput({
        Title = "Name Spot",
        Default = savedPositionName,
        Callback = function(val)
            if val and val ~= "" then
                savedPositionName = val
            end
        end
    })

    local teleportPositionDropdown
    teleportPositionDropdown = SAVEPOSTION:AddDropdown({
        Title = "Saved Positions",
        Content = "Select a saved position to teleport",
        Multi = false,
        Options = getPositionNames(),
        Default = "None",
        Callback = function(val)
            selectedPosition = val
        end
    })

    local function refreshDropdown()
        local names = getPositionNames()
        pcall(function()
            if teleportPositionDropdown.SetValues then
                teleportPositionDropdown:SetValues(names)
            elseif teleportPositionDropdown.SetOptions then
                teleportPositionDropdown:SetOptions(names)
            elseif teleportPositionDropdown.Refresh then
                teleportPositionDropdown:Refresh(names)
            end
        end)
    end

    SAVEPOSTION:AddButton({
        Title = "Save Position",
        Callback = function()
            if savedPositionName and savedPositionName ~= "" then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos = root.Position
                    savedPositions[savedPositionName] = {
                        X = pos.X,
                        Y = pos.Y,
                        Z = pos.Z
                    }
                    savePositionsToFile()
                    refreshDropdown()
                end
            end
        end
    })

    SAVEPOSTION:AddButton({
        Title = "Teleport ke Posisi",
        Callback = function()
            if selectedPosition ~= "None" and savedPositions[selectedPosition] then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local posData = savedPositions[selectedPosition]
                    root.CFrame = CFrame.new(Vector3.new(posData.X, posData.Y, posData.Z))
                end
            end
        end
    })

    SAVEPOSTION:AddButton({
        Title = "Delete Selected Position",
        Callback = function()
            if selectedPosition ~= "None" and savedPositions[selectedPosition] then
                savedPositions[selectedPosition] = nil
                savePositionsToFile()
                refreshDropdown()
                selectedPosition = "None"
            end
        end
    })
end

return Init
