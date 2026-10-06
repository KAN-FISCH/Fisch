local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
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
    local previousLocation = nil
    local teleportData = {}
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
    local function SafeTP(char, targetCFrame)
        if not char or not targetCFrame then return end
        pcall(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
                char:PivotTo(targetCFrame)
                task.wait(0.02)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
    local function getTpSpots()
        local spots = {}
        local added = {}
        local function addSpot(name, cf)
            if not added[name] then
                added[name] = true
                table.insert(spots, name)
                teleportData[name] = cf
            end
        end
        for name, cf in pairs(KNOWN_ZONES) do
            addSpot(name, cf)
        end
        local zones = workspace:FindFirstChild("zones")
        local playerFolder = zones and zones:FindFirstChild("player")
        if playerFolder then
            for _, spot in pairs(playerFolder:GetChildren()) do
                local cf = spot:IsA("BasePart") and spot.CFrame or (spot:IsA("Model") and (spot.PrimaryPart and spot.PrimaryPart.CFrame or spot:GetPivot()))
                if cf then
                    addSpot(spot.Name, cf)
                end
            end
        end
        local world = workspace:FindFirstChild("world")
        local spawns = world and world:FindFirstChild("spawns")
        local TpSpotsFolder = spawns and spawns:FindFirstChild("TpSpots")
        if TpSpotsFolder then
            for _, spot in pairs(TpSpotsFolder:GetChildren()) do
                if spot:IsA("Part") then
                    addSpot(spot.Name, spot.CFrame)
                elseif spot:IsA("CFrameValue") then
                    addSpot(spot.Name, spot.Value)
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
            if selected == "None" and previousLocation then
                SafeTP(char, previousLocation)
                return
            end
            local targetCFrame = teleportData[selected] or KNOWN_ZONES[selected]
            if not targetCFrame then
                for kName, kCF in pairs(KNOWN_ZONES) do
                    if selected:lower():find(kName:lower(), 1, true) or kName:lower():find(selected:lower(), 1, true) then
                        targetCFrame = kCF
                        break
                    end
                end
            end
            if targetCFrame then
                previousLocation = char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.CFrame
                SafeTP(char, targetCFrame)
                pcall(function()
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if not char:FindFirstChildOfClass("Tool") and bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("rod") or t:GetAttribute("ToolType") == "Rod") then
                                t.Parent = char
                                break
                            end
                        end
                    end
                end)
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
            if char and tpCoord then
                SafeTP(char, CFrame.new(tpCoord))
            end
        end
    })
    local function getFishingZones()
        local zones = workspace:FindFirstChild("zones")
        if not zones then return { 'None' }, {} end
        local spots = {}
        local zonesData = {}
        local function addZoneItem(spot)
            if not spot then return end
            local name = spot.Name
            if not zonesData[name] then
                zonesData[name] = {}
                table.insert(spots, name)
            end
            if spot:IsA("BasePart") then
                table.insert(zonesData[name], spot)
            elseif spot:IsA("Model") or spot:IsA("Folder") then
                if spot:IsA("Model") and spot.PrimaryPart then
                    table.insert(zonesData[name], spot.PrimaryPart)
                end
                for _, p in ipairs(spot:GetChildren()) do
                    if p:IsA("BasePart") then
                        table.insert(zonesData[name], p)
                    end
                end
            end
        end
        local playerFolder = zones:FindFirstChild("player")
        if playerFolder then
            for _, spot in ipairs(playerFolder:GetChildren()) do
                addZoneItem(spot)
            end
        end
        local fishingFolder = zones:FindFirstChild("fishing")
        if fishingFolder then
            for _, spot in ipairs(fishingFolder:GetChildren()) do
                addZoneItem(spot)
            end
        end
        for _, child in ipairs(zones:GetChildren()) do
            if child.Name ~= "player" and child.Name ~= "fishing" then
                if child:IsA("Folder") or child:IsA("Model") then
                    for _, spot in ipairs(child:GetChildren()) do
                        addZoneItem(spot)
                    end
                elseif child:IsA("BasePart") then
                    addZoneItem(child)
                end
            end
        end
        table.sort(spots)
        table.insert(spots, 1, 'None')
        return spots, zonesData
    end
    local fishingSpots, zonesData = getFishingZones()
    for kName in pairs(KNOWN_ZONES) do
        if not table.find(fishingSpots, kName) then
            table.insert(fishingSpots, kName)
        end
    end
    table.sort(fishingSpots)
    if not table.find(fishingSpots, "None") then
        table.insert(fishingSpots, 1, "None")
    end
    local function TeleportFishingZoneNoFrezeandNoBoat(zoneName)
        local Character = LocalPlayer.Character
        if not Character then return end
        if zoneName == "None" and previousLocation then
            SafeTP(Character, previousLocation)
            return
        end
        previousLocation = Character:FindFirstChild("HumanoidRootPart") and Character.HumanoidRootPart.CFrame
        if KNOWN_ZONES[zoneName] then
            SafeTP(Character, KNOWN_ZONES[zoneName])
            return
        end
        for kName, kCF in pairs(KNOWN_ZONES) do
            if zoneName:lower():find(kName:lower(), 1, true) or kName:lower():find(zoneName:lower(), 1, true) then
                SafeTP(Character, kCF)
                return
            end
        end
        local _, currentZones = getFishingZones()
        local targetParts = currentZones[zoneName]
        if targetParts and #targetParts > 0 then
            local finalCFrame = nil
            local targetPart = targetParts[1]
            if targetPart then
                local centerPos = targetPart.Position
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { Character }
                rayParams.IgnoreWater = false
                local rayResult = workspace:Raycast(Vector3.new(centerPos.X, centerPos.Y + 500, centerPos.Z), Vector3.new(0, -1000, 0), rayParams)
                if rayResult then
                    finalCFrame = CFrame.new(centerPos.X, rayResult.Position.Y + 4, centerPos.Z)
                else
                    finalCFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
                end
            end
            if finalCFrame then
                SafeTP(Character, finalCFrame)
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