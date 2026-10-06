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
                    local active = workspace:FindFirstChild("active")
                    local boats = active and active:FindFirstChild("boats")
                    local myBoats = boats and boats:FindFirstChild(LocalPlayer.Name)
                    local boat = myBoats and (myBoats:FindFirstChild("Rowboat") or myBoats:FindFirstChildOfClass("Model"))
                    if boat then
                        local boatCF = boat:GetPivot()
                        if hrp.Position.Y < boatCF.Y - 2.5 then
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            hrp.CFrame = boatCF + Vector3.new(0, 5, 0)
                            warn("[TeleportArea] Player fell below boat! Teleporting back onto deck.")
                        end
                    else
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
local function FreezeCharacter(freeze)
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = (freeze == true)
        end
    end)
end
local function autoEquipRod()
    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if char and not char:FindFirstChildOfClass("Tool") and bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("rod") or t:GetAttribute("ToolType") == "Rod") then
                    t.Parent = char
                    break
                end
            end
        end
    end)
end
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
        local playerFolder = zones:FindFirstChild("player")
        if playerFolder then
            pcall(scanParts, playerFolder, 0)
        end
        local fishing = zones:FindFirstChild("fishing")
        if fishing then
            pcall(scanParts, fishing, 0)
        end
    end
    return cachedWaterParts
end
local function getFishingZones()
    local zones = workspace:FindFirstChild("zones")
    if not zones then return {}, {} end
    local positions = {}
    local function addZonePart(name, part)
        if not positions[name] then positions[name] = {} end
        table.insert(positions[name], part)
    end
    local function processZoneItem(z)
        if not z then return end
        if z:IsA("BasePart") then
            addZonePart(z.Name, z)
        elseif z:IsA("Model") or z:IsA("Folder") then
            if z:IsA("Model") and z.PrimaryPart then
                addZonePart(z.Name, z.PrimaryPart)
            end
            for _, p in ipairs(z:GetChildren()) do
                if p:IsA("BasePart") then
                    addZonePart(z.Name, p)
                end
            end
        end
    end
    local playerFolder = zones:FindFirstChild("player")
    if playerFolder then
        for _, z in ipairs(playerFolder:GetChildren()) do
            processZoneItem(z)
        end
    end
    local fishingFolder = zones:FindFirstChild("fishing")
    if fishingFolder then
        for _, z in ipairs(fishingFolder:GetChildren()) do
            processZoneItem(z)
        end
    end
    for _, child in ipairs(zones:GetChildren()) do
        if child.Name ~= "player" and child.Name ~= "fishing" then
            if child:IsA("Folder") or child:IsA("Model") then
                for _, z in ipairs(child:GetChildren()) do
                    processZoneItem(z)
                end
            elseif child:IsA("BasePart") then
                processZoneItem(child)
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
        active = workspace:FindFirstChild("active")
        boats = active and active:FindFirstChild("boats")
        myBoats = boats and boats:FindFirstChild(player.Name)
        boat = myBoats and (myBoats:FindFirstChild("Rowboat") or myBoats:FindFirstChildOfClass("Model"))
    end
    return boat
end
local KNOWN_ZONES = {
    ["abaia"] = CFrame.new(3407.02, 1570.99, 954.06),
    ["Abaia's chamber"] = CFrame.new(3369.32, 1560.19, 929.4),
    ["above the clouds"] = CFrame.new(1501.94, 2594.98, -1755.2),
    ["above the clouds roaming"] = CFrame.new(1492.58, 2600.98, -1725.95),
    ["abovetheclouds"] = CFrame.new(1488.96, 2605.99, -1720.06),
    ["Abyssal zenith"] = CFrame.new(-97, -646.01, 962.99),
    ["Abyssal Zenith-Astral Cavern"] = CFrame.new(-13810, -11541, 106.92),
    ["abyssalzenith"] = CFrame.new(-13548.1, -11040, 123),
    ["abyssalzenithastral"] = CFrame.new(-13806.1, -11544, 140),
    ["Aether"] = CFrame.new(-97, -646.01, 962.99),
    ["altar"] = CFrame.new(1296.06, -802.01, -299.01),
    ["ancient"] = CFrame.new(6055.77, 198.77, 277.83),
    ["Ancient Archive"] = CFrame.new(-3163.59, -753.32, 1860.06),
    ["Ancient Archives"] = CFrame.new(5740, 135, 420),
    ["Ancient Isle"] = CFrame.new(5850, 135, 320),
    ["Ancient isle"] = CFrame.new(5965.37, 258.97, 223.25),
    ["Ancient isle Pond"] = CFrame.new(6013.55, 225.6, 328.48),
    ["Ancient isle Waterfall"] = CFrame.new(5938.43, 266.03, 515.68),
    ["ancientarchives"] = CFrame.new(-3156, -744.01, 2193.02),
    ["Anglerfish Abyss"] = CFrame.new(-10673.1, -9314.01, 260.99),
    ["apollo"] = CFrame.new(-8828.01, -2898.01, 659.93),
    ["Apollo's Song of Light"] = CFrame.new(-8846.62, -2876.13, 612.63),
    ["arch"] = CFrame.new(997.98, 133.94, -1237.84),
    ["Ashbrook Town"] = CFrame.new(-5160, 137.99, -1452.02),
    ["Astral Observatory - Abyssal Zenith"] = CFrame.new(-13812.8, -11537.2, 116.06),
    ["Astral Observatory - Boreal Pines"] = CFrame.new(21879.2, -116.19, 4275.96),
    ["Astral Observatory - Everturn Forest"] = CFrame.new(2532.35, -94.21, -2486.47),
    ["Astral Observatory - Northern Expedition"] = CFrame.new(-1865.75, -228.91, 3944.43),
    ["Astral Observatory - Snowcap Island"] = CFrame.new(2658.75, -377.11, 2465.93),
    ["Atlantean Storm"] = CFrame.new(-3665.97, 163.61, 739.04),
    ["Atlantis"] = CFrame.new(-4319.76, -603.71, 1716.2),
    ["Atlantis Ocean"] = CFrame.new(-4373.66, -573.79, 1855.99),
    ["Azure Lagoon"] = CFrame.new(1310, 80, 2113),
    ["bellona"] = CFrame.new(997.98, 133.94, -1237.84),
    ["Bellona's Frenzy of War"] = CFrame.new(-8822.93, -2333.1, 927.94),
    ["Birch Cay"] = CFrame.new(1740, 145.24, -2419),
    ["Blue Moon"] = CFrame.new(2723.81, 160.92, 2530.07),
    ["boreal"] = CFrame.new(21822, 164.99, 4301),
    ["Boreal Hollow"] = CFrame.new(849.78, -2580.61, 1602.86),
    ["Boreal Pines"] = CFrame.new(21634.3, 161.87, 4130.44),
    ["Boreal Pines - Cave"] = CFrame.new(21720, 162.87, 3979.72),
    ["Boreal Pines - Ice Fishing"] = CFrame.new(21894.5, 162.87, 4236.98),
    ["Boreal Pines - Peak"] = CFrame.new(21370.7, 280.06, 3827.5),
    ["Boreal Pines-Astral Cavern"] = CFrame.new(21871.1, -124.06, 4284.05),
    ["borealastral"] = CFrame.new(21884.1, -139.01, 4215.96),
    ["Brine Pool"] = CFrame.new(-1788.16, -114.06, -3385.05),
    ["Brine Pool Water"] = CFrame.new(-1788.51, -119.55, -3417.49),
    ["Calm Zone"] = CFrame.new(-4345.04, -11153, 3750.44),
    ["Carrot Garden"] = CFrame.new(3709.98, -1124.78, -1077.4),
    ["carrot garden"] = CFrame.new(3718.65, -1128.05, -1099.93),
    ["Castaway Cliffs"] = CFrame.new(690, 135, -1693),
    ["Castway Cliffs"] = CFrame.new(600.61, 191.04, -1859.15),
    ["Challanger's Deep"] = CFrame.new(775.03, -3331.04, -1641.02),
    ["Challenger's Deep"] = CFrame.new(732.13, -3363.06, -1628.91),
    ["Collapsed Ruins"] = CFrame.new(3141.63, -1068.53, 1644.13),
    ["Coral Bastion"] = CFrame.new(2512.75, -1076.03, 839),
    ["Crimson Cavern"] = CFrame.new(-998.65, -335.17, -4886.02),
    ["Crowned Ruins"] = CFrame.new(3125.87, -1107.03, 2153.71),
    ["Cryogenic Canal"] = CFrame.new(20068.4, 539.72, 5421.1),
    ["Cryogenic Canal-Astral Cavern"] = CFrame.new(-1850.07, -250.06, 3985.14),
    ["Crystal Cove"] = CFrame.new(1375.44, -576.03, 2337.07),
    ["Crystal Fissure"] = CFrame.new(21728, 142.92, 4002.83),
    ["Cultist Lair"] = CFrame.new(4320.59, -1981.93, -4676.62),
    ["Cultist Lair - Entrance"] = CFrame.new(49.99, -277, 1891.99),
    ["Cults Curse"] = CFrame.new(655, 2130, 16984),
    ["Cursed Isle"] = CFrame.new(1860, 135, 1210),
    ["Deep Ocean"] = CFrame.new(7665.12, 161.7, 552.53),
    ["Desolate Deep"] = CFrame.new(-1575.01, -200.17, -2904.31),
    ["Desolate Pocket"] = CFrame.new(-1650, -215, -2850),
    ["Desolete Deep Buoy"] = CFrame.new(-789.87, 64.77, -3102.24),
    ["Detonator's Rest"] = CFrame.new(-1404.19, -839.08, -3482.95),
    ["Dryland sand"] = CFrame.new(-6255.95, 215.15, -1376.75),
    ["Drylands"] = CFrame.new(-6305.26, 584.77, -1201.91),
    ["DuneHaven"] = CFrame.new(-6544.15, 233.97, -1835.28),
    ["Earmark Island"] = CFrame.new(1232.22, 208.77, 534.14),
    ["Emberreach"] = CFrame.new(2390, 83, -490),
    ["enchantarchive"] = CFrame.new(736.93, -750.01, -538.02),
    ["Enchanted Crevice"] = CFrame.new(774.81, -735.05, -437.26),
    ["Ethereal Abyys"] = CFrame.new(-3754.2, -536.75, 1832.01),
    ["Ethereal Trial"] = CFrame.new(-3804.16, -660.22, 1830.06),
    ["everturn"] = CFrame.new(2397, 146.36, -2435),
    ["Everturn Forest"] = CFrame.new(2499.76, 162.64, -2560.83),
    ["everturn forest (night)"] = CFrame.new(2542.15, 138.39, -2563.26),
    ["Everturn Forest-Astral Cavern"] = CFrame.new(2521.25, -113.19, -2476.05),
    ["Executive Headquarter"] = CFrame.new(-38.44, -243.31, 206.45),
    ["Forgotten Temple"] = CFrame.new(-5126.56, -1749.63, -9845.25),
    ["Forsaken Shores"] = CFrame.new(-2419.74, 161.91, 1440.13),
    ["Forsaken Shores ocean"] = CFrame.new(-3046.64, 161.66, 1451.26),
    ["Forsaken Shores Pond"] = CFrame.new(-2700.93, 195.26, 1748.89),
    ["Forsaken Veil"] = CFrame.new(-2383.57, -11193, 6865.13),
    ["forsakenveil"] = CFrame.new(-2356.05, -11185.2, 7098),
    ["Frigid Cavern"] = CFrame.new(19890.5, 464.62, 5607.77),
    ["Ghosts Tavern"] = CFrame.new(312.81, 801.56, -6890.95),
    ["Gilded Arch"] = CFrame.new(450, 90, 2850),
    ["Glacial Grotto"] = CFrame.new(20054.4, 909.54, 5639.11),
    ["Gloomy Crevice"] = CFrame.new(-127.87, -2498.21, -11490.8),
    ["Grand Reef"] = CFrame.new(-3576.44, 163.5, 541.85),
    ["Haddock Rock"] = CFrame.new(-551.18, 154.48, -464.37),
    ["Hades"] = CFrame.new(-8963.74, -4216.27, 357.21),
    ["hades"] = CFrame.new(-8650, -4243.18, 433.99),
    ["Hall of Whispers"] = CFrame.new(4372.35, -2203.13, -4678.92),
    ["Harvesters Spike"] = CFrame.new(-1260, 134, 1570),
    ["Hawaii"] = CFrame.new(-1354.25, 135.14, -39953),
    ["Heaven"] = CFrame.new(1466.99, 9005, -1687.01),
    ["Inner Tidefall Castle"] = CFrame.new(4536.99, -1087.01, 922.99),
    ["Isle of New Beginnings"] = CFrame.new(-300, 83, -380),
    ["Isonade"] = CFrame.new(88.86, 231.95, -888.06),
    ["Keepers Altar"] = CFrame.new(1330.08, -806.82, -122.73),
    ["Kraken Lair"] = CFrame.new(-4292.13, -944.05, 2076.08),
    ["Kraken Pool"] = CFrame.new(-4289.72, -971.06, 2077.97),
    ["Lava"] = CFrame.new(-1966.38, 201.96, 274.74),
    ["Living Garden"] = CFrame.new(-2385.1, -289.98, -2907.18),
    ["Lost Jungle"] = CFrame.new(-2869.57, 165.2, -2181.57),
    ["Lower deep"] = CFrame.new(1592.8, -2796.73, -11735),
    ["Luminescent Cavern"] = CFrame.new(-1018.35, -310.09, -4285.75),
    ["Lushgrove"] = CFrame.new(1133, 105, -560),
    ["Mariana's Veil"] = CFrame.new(-5692.73, -7309.23, 590.01),
    ["Merlin's Hut"] = CFrame.new(-931, 225.72, -992.22),
    ["Mermaid Cove"] = CFrame.new(-3846.95, -1287.89, 499.85),
    ["Mineshaft"] = CFrame.new(-685.41, -833.97, -110.32),
    ["Monty's Lab"] = CFrame.new(-10260.7, -494.02, 993.96),
    ["Moosewood"] = CFrame.new(482.25, 164.67, 385.08),
    ["Moosewood Pond"] = CFrame.new(525.99, 181.37, 285.76),
    ["Moosewood Village"] = CFrame.new(467, 150.93, 257),
    ["Mossjaw"] = CFrame.new(-4853.76, -1761.14, -10164.5),
    ["Mushgrove"] = CFrame.new(2670.82, 164.73, -716.37),
    ["Mushgrove Alligator"] = CFrame.new(2688.05, 125.99, -694.04),
    ["Mushgrove Swamp"] = CFrame.new(2450, 131, -730),
    ["NectarDen"] = CFrame.new(-2028.5, -271.98, -3290.16),
    ["Netter's Haven"] = CFrame.new(-640, 85, 1030),
    ["northern"] = CFrame.new(19526, 132.67, 5292),
    ["Northern Expedition"] = CFrame.new(20000, 133, 5300),
    ["obsidian pocket"] = CFrame.new(128.62, -6516.19, 66.84),
    ["Obsidian Trench"] = CFrame.new(-1681.06, -12328, -17.1),
    ["Ocean"] = CFrame.new(2092.97, 171.92, 962.88),
    ["Oil Rig"] = CFrame.new(-2450, 135, -1450),
    ["oilrig"] = CFrame.new(-1902.04, 234.99, -487.01),
    ["Olympian Fissure"] = CFrame.new(-8810.97, -4228.05, -361.6),
    ["olympianfissure"] = CFrame.new(-8819.01, -4239.01, -241.98),
    ["oscar's locker"] = CFrame.new(193, -389.23, 3556),
    ["Outer Deep"] = CFrame.new(1034, -2392.11, -12849),
    ["Overgrowth Cave"] = CFrame.new(20307, 287.55, 5519.7),
    ["overgrowth caves"] = CFrame.new(20307, 287.55, 5519.7),
    ["Passage of Oath"] = CFrame.new(4250.24, -2451.14, -4678.43),
    ["Personal Aquarium"] = CFrame.new(3699, 4252, 2999),
    ["Pine Shoals"] = CFrame.new(1165, 80, 480),
    ["Poseidon Pool"] = CFrame.new(-3984.79, -532.97, 935.67),
    ["Poseidon's Storm"] = CFrame.new(-8820, -3165.18, 738.61),
    ["Roslit"] = CFrame.new(-1493.45, 160.93, 593.55),
    ["Roslit Bay"] = CFrame.new(-1475, 133, 680),
    ["Roslit Clam"] = CFrame.new(-1999.2, 161.72, 440.52),
    ["Roslit Pond"] = CFrame.new(-1807.58, 177.31, 596.82),
    ["Roslit Volcano"] = CFrame.new(-1984.22, 183.21, 278.15),
    ["RoslitBayVolcano"] = CFrame.new(-1969.48, 182.43, 275.43),
    ["Scoria Reach"] = CFrame.new(-4781, 138, -1378),
    ["Scoria Reach mining"] = CFrame.new(-4564.49, -678.42, -2074.49),
    ["Scoria Reach Volcano"] = CFrame.new(-5472.91, 201.31, -1546.8),
    ["scoriamines"] = CFrame.new(-4721.51, -682.24, -2025.07),
    ["shady"] = CFrame.new(-3037, -1029.41, 6041),
    ["Shady Bazaar"] = CFrame.new(990, -710, 1240),
    ["shady Bazaar"] = CFrame.new(-2768, -1024.55, 6198),
    ["Skycrest"] = CFrame.new(3371.8, 1552.6, 964.5),
    ["Snowburrow"] = CFrame.new(2759.4, 122.07, 2612.16),
    ["snowburrow"] = CFrame.new(2759.4, 122.07, 2612.16),
    ["snowcap"] = CFrame.new(2648, 142.28, 2521),
    ["Snowcap"] = CFrame.new(2815.53, 164.78, 2808.99),
    ["Snowcap Cave"] = CFrame.new(2710, 140, 2480),
    ["snowcap cave"] = CFrame.new(2860, 141.28, 2612),
    ["Snowcap Island"] = CFrame.new(2625, 135, 2370),
    ["Snowcap ocean"] = CFrame.new(2216.19, 161.78, 2823.2),
    ["Snowcap Pond"] = CFrame.new(2796.6, 311.05, 2593.23),
    ["Statue of Sovereignty"] = CFrame.new(45, 133, -1010),
    ["statue of sovereignty"] = CFrame.new(72, 141.92, -1029),
    ["Sunken Depth"] = CFrame.new(-4958.22, -566.32, 1824.81),
    ["Sunken Reliquary"] = CFrame.new(2945.73, -1080.02, -189.23),
    ["sunkendepth"] = CFrame.new(-4958.22, -566.32, 1824.81),
    ["Sunstone"] = CFrame.new(-794.91, 151.05, -1334.59),
    ["Sunstone Island"] = CFrame.new(-935, 132, -1125),
    ["Sunstone Sundial"] = CFrame.new(-1143.6, 134.49, -1071.23),
    ["terappin"] = CFrame.new(-144, 145.08, 1909),
    ["terappinisland"] = CFrame.new(-144, 145.08, 1909),
    ["Terrapin"] = CFrame.new(152.29, 169.96, 2004.01),
    ["Terrapin Island"] = CFrame.new(-185, 134, 1940),
    ["Terrapin ocean"] = CFrame.new(464.07, 165.78, 2209.58),
    ["The Arch"] = CFrame.new(1000, 125, -1250),
    ["The arch"] = CFrame.new(1073.62, 161.72, -1203.49),
    ["the bunker"] = CFrame.new(1844.74, -327.78, -2386.04),
    ["The Cursed Shores"] = CFrame.new(-235, 85, 1930),
    ["The Deep"] = CFrame.new(523.56, -2210.04, -11901.5),
    ["The Depth"] = CFrame.new(958.15, -713.06, 1442.44),
    ["The Depths"] = CFrame.new(990, -710, 1240),
    ["the sanctum"] = CFrame.new(4368, -2710.14, -4674),
    ["The Sanctum"] = CFrame.new(4413.11, -2679.92, -4672.15),
    ["The Shady Bazaar"] = CFrame.new(-2921, -968.44, 6038),
    ["Tidefall"] = CFrame.new(3075.61, -1079.92, 833.18),
    ["Tidefall Castle"] = CFrame.new(4469.46, -1074.65, 924.73),
    ["Toxic Grove"] = CFrame.new(-2674.53, -287.92, -2206.12),
    ["Trade Plaza"] = CFrame.new(535, 82, 775),
    ["Treasure Island"] = CFrame.new(8274.78, 195, -17293),
    ["Underground Music Venue"] = CFrame.new(2015, -645, 2460),
    ["Veil of the Forsaken"] = CFrame.new(-2356.05, -11185.2, 7098),
    ["Veil Research Platform"] = CFrame.new(-1950.03, 131.5, -330.02),
    ["Vertigo"] = CFrame.new(-161.66, -705.02, 1205.99),
    ["vertigo dip"] = CFrame.new(-161.66, -705.02, 1205.99),
    ["volcanic vent"] = CFrame.new(-3358, -2029.91, 4077),
    ["Volcanic Vents"] = CFrame.new(-3136.28, -2010.89, 4056.85),
    ["Waveborne"] = CFrame.new(360, 90, 780),
    ["Wrath of Olympus"] = CFrame.new(-4265, -1117, 1825),
    ["Zeus Sanctuary"] = CFrame.new(-4298.74, -599.16, 2714.11),
    ["Zeus Thunder of Chaos"] = CFrame.new(-8671.82, -3507.06, 481.25),
    ["zeus trial"] = CFrame.new(-4297, -673.12, 2353),
}
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
    previousLocation = HumanoidRootPart.CFrame
    if KNOWN_ZONES[zoneName] then
        local targetCF = KNOWN_ZONES[zoneName]
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        HumanoidRootPart.CFrame = targetCF
        lastTargetCFrame = targetCF
        FreezeCharacter(false)
        autoEquipRod()
        return
    end
    for kName, kCF in pairs(KNOWN_ZONES) do
        if zoneName:lower():find(kName:lower(), 1, true) or kName:lower():find(zoneName:lower(), 1, true) then
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            HumanoidRootPart.CFrame = kCF
            lastTargetCFrame = kCF
            FreezeCharacter(false)
            autoEquipRod()
            return
        end
    end
    local _, zonesData = getFishingZones()
    local targetParts = zonesData[zoneName]
    if not targetParts or #targetParts == 0 then
        warn("[TeleportArea] Zone not found: " .. tostring(zoneName))
        return
    end
    local finalCFrame = nil
    local targetPart = targetParts[1]
    if targetPart then
        local centerPos = targetPart.Position
        local waterParts = getWaterParts()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = waterParts
        rayParams.IgnoreWater = false
        local rayResult = workspace:Raycast(Vector3.new(centerPos.X, centerPos.Y + 500, centerPos.Z), Vector3.new(0, -1000, 0), rayParams)
        if rayResult then
            finalCFrame = CFrame.new(centerPos.X, rayResult.Position.Y + 4, centerPos.Z)
        else
            finalCFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
        end
    end
    if finalCFrame then
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        HumanoidRootPart.CFrame = finalCFrame
        lastTargetCFrame = finalCFrame
        FreezeCharacter(false)
        autoEquipRod()
    end
end
local function GetZoneList()
    local list, _ = getFishingZones()
    for kName in pairs(KNOWN_ZONES) do
        if not table.find(list, kName) then
            table.insert(list, kName)
        end
    end
    table.sort(list)
    table.insert(list, 1, "None")
    return list
end
return {
    TeleportToZone = teleportToFishingZone,
    GetZoneList = GetZoneList,
    GetFishingZones = getFishingZones,
}