local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
                ExclusiveSection:AddSeperator({
                    Title = 'Notifications'
                })

                ExclusiveSection:AddToggle({
                    Title = "Enable Fish Notification UI",
                    Description = "Show on-screen notification when catching a fish",
                    Default = _G.Config.FishNotificationEnabled,
                    Callback = function(Value)
                        _G.Config.FishNotificationEnabled = Value
                    end
                })

            ExclusiveSection:AddSeperator({
                Title = 'Anti AFK',
            })
            local antiAfkConnection
            ExclusiveSection:AddToggle({
                Title = "Anti AFK",
                Description = "Prevents being kicked for idleness (Memory Safe for 24h+)",
                Default = true,
                Callback = function(state)
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    if state then
                        pcall(function()
                            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                                if conn.Disable then conn:Disable() 
                                elseif conn.Disconnect then conn:Disconnect() end
                            end
                        end)
                    else
                        if antiAfkConnection then
                            antiAfkConnection:Disconnect()
                            antiAfkConnection = nil
                        end
                    end
                end
            })

            ExclusiveSection:AddSeperator({
                Title = 'Delete Animation',
            })
            ExclusiveSection:AddToggle({
                Title = "Delete Animation (Fishing)",
                Description = "Removes character animation to reduce lag",
                Default = _G.Config.DeleteAnimation or false,
                Callback = function(state)
                    _G.Config.DeleteAnimation = state
                    task.spawn(function()
                        FreazeChar(state)
                    end)
                end
            })

            if isfolder and not isfolder(configFolder) then
                if makefolder then
                    makefolder(configFolder)
                end
            end

            function getTimeSinceLastSave()
                local diff = os.time() - lastSaveTime
                if diff < 60 then
                    return diff .. "s ago"
                elseif diff < 3600 then
                    return math.floor(diff / 60) .. "m ago"
                else
                    return math.floor(diff / 3600) .. "h ago"
                end
            end

            function getPlayerPosition()
                local player = game.Players.LocalPlayer
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if root then
                    local pos = root.Position
                    local savedPos = {
                        X = math.floor(pos.X),
                        Y = math.floor(pos.Y),
                        Z = math.floor(pos.Z)
                    }
                    print("[Config] Position: " .. savedPos.X .. ", " .. savedPos.Y .. ", " .. savedPos.Z)
                    return savedPos
                end
                return nil
            end

            function getSavedConfigsList()
                savedConfigsList = {}

                if listfiles and isfolder and isfolder(configFolder) then
                    local files = listfiles(configFolder)

                    for _, file in pairs(files) do
                        if type(file) == "string" and file:match("%.json$") then
                            local fileName = file:match("([^/\\]+)%.json$")
                            if fileName then
                                table.insert(savedConfigsList, fileName)
                            end
                        end
                    end

                    table.sort(savedConfigsList)
                end
                return savedConfigsList
            end
            function updateStatusDisplay()
                if ConfigStatusParagraph then
                    local newContent = getConfigStatusText()
                    pcall(function()
                        if ConfigStatusParagraph.SetDesc then
                            ConfigStatusParagraph:SetDesc(newContent)
                        elseif ConfigStatusParagraph.Set then
                            ConfigStatusParagraph:Set({Content = newContent})
                        end
                    end)
                end
            end

            function saveConfig(configName)
                configName = configName or currentConfigFile
                local HttpService = game:GetService("HttpService")

                local currentPos = getPlayerPosition()
                if currentPos then
                    _G.Config.SavedPosition = deepCopy(currentPos)
                end

                local savePacket = {
                    Config = _G.Config,
                    Var = {}
                }

                for k, v in pairs(__var) do
                    if type(v) ~= "userdata" and type(v) ~= "function" then
                        savePacket.Var[k] = deepCopy(v)
                    end
                end

                local configString = HttpService:JSONEncode(savePacket)
                local filePath = configFolder .. configName .. ".json"

                if writefile then
                    writefile(filePath, configString)
                    lastSaveTime = os.time()
                    totalSaves = totalSaves + 1
                    currentConfigFile = configName

                    getSavedConfigsList()
                    updateStatusDisplay()
                    return true
                end
                return false
            end
            function loadConfig(configName, autoTeleport)
                configName = configName or currentConfigFile
                if autoTeleport == nil then 
                    autoTeleport = _G.Config.AutoTeleportOnLoad 
                end

                local filePath = configFolder .. configName .. ".json"
                if readfile and isfile and isfile(filePath) then
                    local HttpService = game:GetService("HttpService")
                    local success, result = pcall(function()
                        return HttpService:JSONDecode(readfile(filePath))
                    end)

                    if success and result then
                        local loadedConfig = result.Config or result
                        local loadedVar = result.Var or {}

                        for key, value in pairs(loadedConfig) do
                            if type(value) == "table" then
                                _G.Config[key] = deepCopy(value)
                            else
                                _G.Config[key] = value
                            end
                        end

                        for key, value in pairs(loadedVar) do
                            if key ~= "reelConnection" and key ~= "isReeling" then
                                if type(value) == "table" then
                                    __var[key] = deepCopy(value)
                                else
                                    __var[key] = value
                                end
                            end
                        end

                        currentConfigFile = configName
                        lastSaveTime = os.time()
                        updateStatusDisplay()
                        if autoTeleport and _G.Config.SavedPosition then
                            task.wait(0.5)
                            teleportToSavedPosition(_G.Config.SavedPosition)
                        end

                        return true
                    end
                end
                return false
            end

            function deleteConfig(configName)
                local filePath = configFolder .. configName .. ".json"
                if delfile and isfile and isfile(filePath) then
                    delfile(filePath)

                    getSavedConfigsList()

                    if #savedConfigsList > 0 then
                        currentConfigFile = savedConfigsList[1]
                        loadConfig(currentConfigFile, false)
                    else
                        currentConfigFile = "Default"
                        _G.Config.SavedPosition = nil
                    end

                    updateStatusDisplay()
                    return true
                end
                return false
            end

            function getConfigStatusText()
                local status = "File: " .. currentConfigFile .. ".json\n"
                local filePath = configFolder .. currentConfigFile .. ".json"

                status = status .. "Total Configs: " .. #savedConfigsList .. "\n"

                if isfile and isfile(filePath) then
                    status = status .. "Status: FOUND\n"
                    status = status .. "Last Save: " .. getTimeSinceLastSave() .. "\n"

                    if _G.Config.SavedPosition and _G.Config.SavedPosition.X then
                        local pos = _G.Config.SavedPosition
                        status = status .. "Position: " .. pos.X .. ", " .. pos.Y .. ", " .. pos.Z .. "\n"
                    else
                        local HttpService = game:GetService("HttpService")
                        local success, fileData = pcall(function()
                            return HttpService:JSONDecode(readfile(filePath))
                        end)

                        if success and fileData and fileData.SavedPosition then
                            local pos = fileData.SavedPosition
                            status = status .. "Position: " .. pos.X .. ", " .. pos.Y .. ", " .. pos.Z .. "\n"
                        else
                            status = status .. "Position: Not Saved\n"
                        end
                    end

                    status = status .. "Auto TP: " .. (_G.Config.AutoTeleportOnLoad and "ON" or "OFF")
                else
                    status = status .. "Status: NOT FOUND\nSave to create file"
                end

                return status
            end

            getSavedConfigsList()

            if #savedConfigsList == 0 then
                savedConfigsList = {"No Configs"}
            end

            ConfigStatusParagraph = AutoSaveSection:AddParagraph({
                Title = 'CONFIG INFO',
                Content = getConfigStatusText()
            })
        selectedNpcToTp = nil
        NpcDropdown = NPCSection:AddDropdown({
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
                targetCFrame = cachedNpcLocations[selectedNpcToTp]

                if selectedNpcToTp and workspace.world.npcs:FindFirstChild(selectedNpcToTp) then
                    npc = workspace.world.npcs[selectedNpcToTp]
                    root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                    if root then
                        targetCFrame = root.CFrame
                    end
                end

                if targetCFrame and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
                else
                    print("NPC location unknown or character not ready.")
                end
            end
        })

        NPCSection:AddButton({
            Title = "Refresh NPC List",
            Callback = function()
                updateNpcList()
                if NpcDropdown.SetValues then
                    NpcDropdown:SetValues(npcNames)
                elseif NpcDropdown.SetOptions then
                    NpcDropdown:SetOptions(npcNames)
                end
            end
        })
        local function teleportTo(pos)
            local p = game.Players.LocalPlayer
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end
        local teleportSpots = { 'None' }
        local teleportData = {}

        local function teleportTo22(areaName)
            local Character = LocalPlayer.Character
            if not Character then
                return
            end

            local HumanoidRootPart = Character:FindFirstChild('HumanoidRootPart')
            if not HumanoidRootPart then
                return
            end
            if areaName == 'None' and previousLocation then
                HumanoidRootPart.CFrame = previousLocation
                return
            end
            local targetCFrame = teleportData[areaName]
            if targetCFrame then
                previousLocation = HumanoidRootPart.CFrame
                HumanoidRootPart.CFrame = targetCFrame
            else
            end
        end

    local function getTpSpots()
        local world = Workspace:WaitForChild('world', 5)
        local spawns = world and world:WaitForChild('spawns', 5)
        local TpSpotsFolder = spawns and spawns:WaitForChild('TpSpots', 5)

        if not TpSpotsFolder then
            return { 'None' }
        end

        local spots = {}
        local children = TpSpotsFolder:GetChildren()
        for _, spot in pairs(children) do
            if spot:IsA('Part') or spot:IsA('CFrameValue') then
                table.insert(spots, spot.Name)
                if spot:IsA('Part') then
                    teleportData[spot.Name] = spot.CFrame
                elseif spot:IsA('CFrameValue') then
                    teleportData[spot.Name] = spot.Value
                end
            end
        end
        table.sort(spots)
        table.insert(spots, 1, 'None')
        return spots
    end
        teleportSpots = getTpSpots() 
        Dropdown(Main, "TP Area", "None", teleportSpots, false, function(selected)
            teleportTo22(selected)
        end)

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
                        print("Koordinat siap:", tpCoord)
                    else
                        warn("Format salah! Masukkan setidaknya x, y, z")
                    end
                end
            end
        })

        Main:AddButton({
            Title = "Teleport",
            Callback = function()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and tpCoord then
                    char.HumanoidRootPart.CFrame = CFrame.new(tpCoord)
                    print("Teleported ke:", tpCoord)
                else
                    warn("Belum ada koordinat valid!")
                end
            end
        })
        local function getFishingZones()
            local zones = Workspace:WaitForChild('zones', 5)
            local FishingZonesFolder = zones and zones:FindFirstChild('fishing', 5)
            if not FishingZonesFolder then
                return { 'None' }
            end
            local spots = {}
            local zonesData = {}
            local children = FishingZonesFolder:GetChildren()
            for _, spot in pairs(children) do
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
            local sortedZonesData = {}
            for _, name in ipairs(spots) do
                if zonesData[name] then
                    sortedZonesData[name] = zonesData[name]
                end
            end

            return spots, sortedZonesData
        end

        local fishingSpots, _ = getFishingZones()
        local function AddZone(name)
            for _, spot in ipairs(fishingSpots) do
                if spot == name then
                    return 
                end
            end
            table.insert(fishingSpots, name)
        end
        AddZone("Crystal Cove")
        Dropdown(Main, "Teleport Zone", _G.Config.selectedZone, fishingSpots, false, function(selected)
            _G.Config.selectedZone = selected
        end)

        Main:AddButton({
            Title = "Teleport Zone",
            Content = "Teleport to selected zone",
            Callback = function()
                task.spawn(function()
                    TeleportFishingZoneNoFrezeandNoBoat(_G.Config.selectedZone)
                end)
            end
        })

        selectedPlayer = "None"
        local teleportPlayerDropdown

        function getPlayerNames()
            names = {"None"}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= speaker then
                    table.insert(names, player.Name)
                end
            end
            return names
        end
        teleportPlayerDropdown = Dropdown(Main, "Teleport Player", "None", getPlayerNames(), false, function(selected)
            selectedPlayer = selected
        end)
        function teleportToPlayer(playerName)
        root = getRoot(LocalPlayer.Character)
        targetPlayer = Players:FindFirstChild(playerName)

        if not root or not targetPlayer or not targetPlayer.Character then return end
        targetRoot = getRoot(targetPlayer.Character)
        if not targetRoot then return end

        targetCFrame = targetRoot.CFrame + Vector3.new(3, 1, 0)

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
        local teleportPlayerButton = Button(Main, "Teleport ke Pemain", function()
            if selectedPlayer ~= "None" then
                teleportToPlayer(selectedPlayer)
            end
        end)
        BallonSection:AddSeperator({
            Title = 'Ballon Teleport',
        })
        Button(BallonSection, "Teleport ke Balon 1", function()
            teleportTo(Vector3.new(201.9, 162, -33.7))
        end)
        Button(BallonSection, "Teleport ke Balon 2", function()
            teleportTo(Vector3.new(1005, 131, -1234))
        end)
        Button(BallonSection, "Teleport ke Balon 3", function()
            teleportTo(Vector3.new(-2800, 260, 1550))
        end)
        Button(BallonSection, "Teleport ke Balon 4", function()
            teleportTo(Vector3.new(-1244, 131, 1594))
        end)
        Button(BallonSection, "Teleport ke Balon 5", function()
            teleportTo(Vector3.new(-2001, 190, 389))
        end)
        Button(BallonSection, "Teleport ke Balon 6", function()
            teleportTo(Vector3.new(-1129, 228, -1158))
        end)
        Button(BallonSection, "Teleport ke Balon 7", function()
            teleportTo(Vector3.new(1237, 140, 551))
        end)
        Button(BallonSection, "Teleport ke Balon 8", function()
            teleportTo(Vector3.new(2747, 142, -785))
        end)
        Button(BallonSection, "Teleport ke Balon 9", function()
            teleportTo(Vector3.new(-3881, 131, 326))
        end)
        Button(BallonSection, "Teleport ke Balon 10", function()
            teleportTo(Vector3.new(-1804, 188, 256))
        end)
        Button(BallonSection, "Teleport ke Balon 11", function()
            teleportTo(Vector3.new(-9.5, 157, -1079))
        end)
        Button(BallonSection, "Teleport ke Balon 12", function()
            teleportTo(Vector3.new(545, 295, -1887))
        end)
        Button(BallonSection, "Teleport ke Balon 13", function()
            teleportTo(Vector3.new(-2015, 224, -496))
        end)
        Button(BallonSection, "Teleport ke Balon 14", function()
            teleportTo(Vector3.new(506, 172, 220))
        end)
        Button(BallonSection, "Teleport ke Balon 15", function()
            teleportTo(Vector3.new(1742, 141, -2481))
        end)
        Button(BallonSection, "Teleport ke Balon 16", function()
            teleportTo(Vector3.new(1742, 141, -2481))
        end)
        Button(BallonSection, "Teleport ke Balon 17", function()
            teleportTo(Vector3.new(106, 184, 2074))
        end)
        Button(BallonSection, "Teleport ke Balon 18", function()
            teleportTo(Vector3.new(3019, -130, 2451))
        end)
        Button(BallonSection, "Teleport ke Balon 19", function()
            teleportTo(Vector3.new(5934, 259, 216))
        end)
        Button(BallonSection, "Teleport ke Balon 20", function()
            teleportTo(Vector3.new(-1520, 130, 2194))
        end)

        _spPlayer = game:GetService("Players").LocalPlayer
        _spHttpService = game:GetService("HttpService")

        savedPositions = {}
        savedPositionName = "SHIELD"
        selectedPosition = "None"
        saveFileName = "saved_positions_shieldteam.json"

        function loadSavedPositions()
            local success, result = pcall(function()
                if isfile and isfile(saveFileName) then
                    jsonData = readfile(saveFileName)
                    return _spHttpService:JSONDecode(jsonData)
                end
                return {}
            end)

            if success and type(result) == "table" then
                return result
            else
                warn("Gagal memuat posisi tersimpan:", result)
                return {}
            end
        end

        function savePositionsToFile()
            local success, errorMsg = pcall(function()
                if writefile then
                    jsonData = _spHttpService:JSONEncode(savedPositions)
                    writefile(saveFileName, jsonData)
                end
            end)

            if not success then
                warn("Gagal menyimpan posisi:", errorMsg)
            end
        end

        savedPositions = loadSavedPositions()

        function getPositionNames()
            names = {"None"}
            for name, _ in pairs(savedPositions) do
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

        teleportPositionDropdown = SAVEPOSTION:AddDropdown({
            Title = "Saved Positions",
            Content = "Select a saved position to teleport",
            Multi = false,
            Options = getPositionNames(),
            Default = "None",
            Callback = function(val)
                selectedPosition = val
                print("Position selected:", val)
            end
        })

        function refreshDropdown()
            names = getPositionNames()
            local success, err = pcall(function()
                if teleportPositionDropdown.SetValues then
                    teleportPositionDropdown:SetValues(names)
                elseif teleportPositionDropdown.SetOptions then
                    teleportPositionDropdown:SetOptions(names)
                elseif teleportPositionDropdown.Refresh then
                    teleportPositionDropdown:Refresh(names)
                else
                    warn("Dropdown refresh method not found!")
                end
            end)
            if not success then
                warn("Gagal refresh dropdown:", err)
            end
        end

        SAVEPOSTION:AddButton({
            Title = "Save Position",
            Callback = function()
                if savedPositionName and savedPositionName ~= "" then
                    character = _spPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        pos = character.HumanoidRootPart.Position
                        savedPositions[savedPositionName] = {
                            X = pos.X,
                            Y = pos.Y,
                            Z = pos.Z
                        }
                        savePositionsToFile()
                        refreshDropdown()
                        print("Posisi disimpan:", savedPositionName)
                    else
                        warn("Character atau HumanoidRootPart tidak ditemukan!")
                    end
                else
                    warn("Nama posisi kosong!")
                end
            end
        })
        SAVEPOSTION:AddButton({
            Title = "Teleport ke Posisi",
            Callback = function()
                if selectedPosition ~= "None" and savedPositions[selectedPosition] then
                    character = _spPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        posData = savedPositions[selectedPosition]
                        targetPosition = Vector3.new(posData.X, posData.Y, posData.Z)

                        character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                        print("Teleport ke:", selectedPosition)
                    end
                else
                    warn("Tidak ada posisi yang dipilih atau posisi tidak valid!")
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
                    print("Posisi dihapus!")
                end
            end
        })
        SettingFish = FishingTab:AddSection("Fishing Setting", true, "Right")
        FishingZone = FishingTab:AddSection("Fishing Zone", true, "Right")
        FishingEventZone = FishingTab:AddSection("Fishing Event Zone", true, "Left")

        ShopBait = ShopTab:AddSection("Bait", true, "Left")
        ShopItem = ShopTab:AddSection("Shop Item", true, "Right")

    ShopItem:AddToggle({
        Title = "Auto Buy Carrot",
        Default = false,
        Callback = function(state)
            _G.Config.AutoBuyCarrot = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCarrot do
                        pcall(function()
                            local player = game:GetService("Players").LocalPlayer
                            local char = player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(266, 147, -146)
                            end
                            task.wait(0.2)
                            local args = { buffer.fromstring("h\\000\\006Carrot") }
                            game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

        ShopRod = ShopTab:AddSection("Rod", true, "Left")
        Merlin = ShopTab:AddSection("Merlin", true, "Right")

        AutosCollect = AutosTab:AddSection("Auto Collect Chest", true, "Left")

        AutosQuest = AutosTab:AddSection("Auto Quest", true, "Left")
        AutosJack = AutosTab:AddSection("Auto Treasure", true, "Right")
        AutosFavorit = AutosTab:AddSection("Auto Fav Item/Fish", true, "Left")
        AutosAppraise = AutosTab:AddSection("Appraise Treasure", true, "Right")
        AutoAppraise = AutosTab:AddSection("Appraise", true, "Left")
        AutoEnchant = AutosTab:AddSection("Enchant", true, "Right")
        Collect = AutosTab:AddSection("Collect", true, "Left")
        AutosSection = AutosTab:AddSection("Auto Sell", true, "Right")

        AuraSection = AutosTab:AddSection("Totem", true, "Left")

        EspPlayers = false
        EspZone = false
        EspNpc = false

        function AddEsp(target, name, color, offset)
            if not target then return end
            if target:FindFirstChild("BF_ESP") then return end

            bill = Instance.new("BillboardGui")
            bill.Name = "BF_ESP"
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 200, 0, 50)
            bill.Adornee = target
            bill.StudsOffset = offset or Vector3.new(0, 3, 0)

            text = Instance.new("TextLabel", bill)
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.TextColor3 = color
            text.TextStrokeTransparency = 0
            text.TextStrokeColor3 = Color3.new(0,0,0)
            text.Font = Enum.Font.GothamBold
            text.TextSize = 13
            text.Text = name

            bill.Parent = target

            if target.Parent and target.Parent:IsA("Model") then
                h = Instance.new("Highlight")
                h.Name = "BF_Highlight"
                h.FillColor = color
                h.OutlineColor = color
                h.FillTransparency = 0.8
                h.Adornee = target.Parent
                h.Parent = target
            end
        end

        function RemoveEsp(target)
            if target and target:FindFirstChild("BF_ESP") then
                target.BF_ESP:Destroy()
            end
            if target and target:FindFirstChild("BF_Highlight") then
                target.BF_Highlight:Destroy()
            end
        end

        task.spawn(function()
            while true do
                if EspPlayers then
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            hrp = p.Character.HumanoidRootPart
                            AddEsp(hrp, p.Name, Color3.fromRGB(255, 0, 0))
                            if hrp:FindFirstChild("BF_ESP") then
                                myRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot then
                                    dist = (myRoot.Position - hrp.Position).Magnitude
                                    hrp.BF_ESP.TextLabel.Text = p.Name .. " ["..math.floor(dist).."m]"
                                end
                            end
                        end
                    end
                else
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            RemoveEsp(p.Character.HumanoidRootPart)
                        end
                    end
                end

                if EspZone then
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        local targetEvents = {
                            ["Orca"] = true, ["Baby Bloop Fish"] = true, ["Bloop Fish"] = true, ["Moby"] = true, 
                            ["Megalodon"] = true, ["Mossjaw"] = true, ["Megalodon Ancient"] = true, 
                            ["Megalodon Phantom"] = true, ["Great White Shark"] = true, ["Hammerhead Shark"] = true, 
                            ["Whale Shark"] = true, ["The Depths - Serpent"] = true, ["Isonade"] = true, 
                            ["Forsaken Veil - Scylla"] = true, ["Blarney McBreeze"] = true, ["Sea Leviathan Pool"] = true, 
                            ["Animal Pool"] = true, ["Octophant Pool Without Elephant"] = true, ["Kraken Pool"] = true, 
                            ["Blue Moon - Second Sea"] = true, ["Blue Moon - First Sea"] = true, 
                            ["LEGO"] = true, ["LEGO - Studolodon"] = true, ["Mosslurker"] = true, ["Narwhal"] = true,
                            ["Megalodon Default"] = true
                        }
                        for _, z in pairs(zones:GetChildren()) do
                            if targetEvents[z.Name] then
                                if z:IsA("BasePart") then 
                                    AddEsp(z, z.Name, Color3.fromRGB(0, 255, 255))
                                elseif z:IsA("Model") and z.PrimaryPart then
                                    AddEsp(z.PrimaryPart, z.Name, Color3.fromRGB(0, 255, 255))
                                end
                            end
                        end
                    end
                elseif EspZoneAll then
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        for _, z in pairs(zones:GetChildren()) do
                            if z:IsA("BasePart") then 
                                AddEsp(z, z.Name, Color3.fromRGB(200, 200, 200))
                            elseif z:IsA("Model") and z.PrimaryPart then
                                AddEsp(z.PrimaryPart, z.Name, Color3.fromRGB(200, 200, 200))
                            end
                        end
                    end
                else
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        for _, z in pairs(zones:GetChildren()) do
                            if z:IsA("BasePart") then RemoveEsp(z) 
                            elseif z:IsA("Model") and z.PrimaryPart then RemoveEsp(z.PrimaryPart) end
                        end
                    end
                end

                if EspNpc then
                    npcFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                    if npcFolder then
                        for _, n in pairs(npcFolder:GetChildren()) do
                            if n:FindFirstChild("HumanoidRootPart") then
                                AddEsp(n.HumanoidRootPart, n.Name, Color3.fromRGB(0, 255, 0))
                                if n.HumanoidRootPart:FindFirstChild("BF_ESP") then
                                    myRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if myRoot then
                                        dist = (myRoot.Position - n.HumanoidRootPart.Position).Magnitude
                                        n.HumanoidRootPart.BF_ESP.TextLabel.Text = n.Name .. " ["..math.floor(dist).."m]"
                                    end
                                end
                            end
                        end
                    end
                else
                    npcFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                    if npcFolder then
                        for _, n in pairs(npcFolder:GetChildren()) do
                            if n:FindFirstChild("HumanoidRootPart") then
                                RemoveEsp(n.HumanoidRootPart)
                            end
                        end
                    end
                end

                task.wait(1)
            end
        end)

        EspCharacterSection = EspTab:AddSection("ESP Character", true, "Left")
        EspCharacterSection:AddToggle({
            Title = "Enable ESP Character",
            Default = false,
            Callback = function(v)
                EspPlayers = v
            end
        })

        EspEventSection = EspTab:AddSection("ESP Zone", true, "Right")
        EspEventSection:AddToggle({
            Title = "Enable ESP Zone Event",
            Default = false,
            Callback = function(v)
                EspZone = v
            end
        })
        EspEventSection:AddToggle({
            Title = "Enable ESP Zone",
            Default = false,
            Callback = function(v)
                EspZoneAll = v
            end
        })

        EspNpcSection = EspTab:AddSection("ESP NPC", true, "Right")
        EspNpcSection:AddToggle({
            Title = "Enable ESP NPC",
            Default = false,
            Callback = function(v)
                EspNpc = v
            end
        })


end
return Init
