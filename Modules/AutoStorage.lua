local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local autoStorageRunning = false
local storageFreezeActive = false
local storageClonedCrate = nil
local autoSellStorageRunning = false
local lastAdminEvent = nil

local EXCLUDED_ITEMS = {
    ["totem"] = true,
    ["gps"] = true,
    ["suit"] = true,
    ["diving gear"] = true,
    ["cage"] = true,
    ["bag"] = true,
    ["cloak"] = true,
    ["glider"] = true,
    ["keystone"] = true,
    ["thread"] = true,
    ["potion"] = true,
    ["map"] = true,
    ["tank"] = true,
    ["fragment"] = true,
    ["essence"] = true,
    ["amulet"] = true,
    ["conch"] = true,
    ["egg"] = true,
    ["shard"] = true,
    ["firework"] = true,
    ["flipper"] = true,
    ["bait"] = true,
    ["rod"] = true,
    ["translator"] = true,
    ["spearhead"] = true,
    ["glove"] = true,
    ["plushie"] = true,
    ["coil"] = true,
    ["seal"] = true,
    ["waders"] = true,
    ["whistle"] = true,
    ["matrix"] = true,
}

local function PrepareForTeleport()
    local prevAutoCast = _G.Config and _G.Config.AutoCast
    local prevEquipRod = _G.Config and _G.Config.equipRod
    if _G.Config then
        _G.Config.equipRod = false
        _G.Config.AutoCast = false
    end
    return prevAutoCast, prevEquipRod
end

local function RestoreAfterTeleport(prevAutoCast, prevEquipRod)
    if _G.Config then
        if prevEquipRod ~= nil then _G.Config.equipRod = prevEquipRod end
        if prevAutoCast ~= nil then _G.Config.AutoCast = prevAutoCast end
    end
end

local function getAdminEventStatus()
    local success, eventText = pcall(function()
        return Players.LocalPlayer.PlayerGui.hud.safezone.worldstatuses["1_adminevent"].label.Text
    end)
    if not success or not eventText then return "None" end

    local s = tostring(eventText):lower()
    s = s:gsub("[%s]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("[:%-]", "")
    if s:find("weather%s*status") or s:find("weatherstatus") or s == "none" then
        return "None"
    end

    return eventText
end

local function executeAutoStorage()
    if autoStorageRunning then return end
    autoStorageRunning = true
    local prevAutoCast, prevEquipRod

    task.spawn(function()
        local overallOk, overallErr = pcall(function()
            local needsTeleport = not storageClonedCrate or not storageClonedCrate.Parent
            if needsTeleport then
                prevAutoCast, prevEquipRod = PrepareForTeleport()
                pcall(function()
                    local char = Players.LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        task.wait(0.2)
                        if hum then hum:UnequipTools() end
                        task.wait(1.5)
                    end
                end)
            end

            local success, err = pcall(function()
                local Net = require(ReplicatedStorage.packages.Net)
                local DataController = require(ReplicatedStorage.client.legacyControllers.DataController)
                local itemDisplayInfo = require(ReplicatedStorage.client.modules.ui.Backpack.itemDisplayInfo)

                local LocalPlayer = Players.LocalPlayer
                local Character = LocalPlayer.Character
                if not Character then return end

                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                if not HumanoidRootPart then return end

                local BulkMoveRemote = Net:RemoteFunction("Storage/RequestBulkMove")
                local JoinAquarium = ReplicatedStorage.packages.Net["RE/PersonalAquarium/Join"]

                local rarityMap = {}
                local selectedRarities = _G.Config.AutoStorageRarities or {}
                for _, rarity in ipairs(selectedRarities) do
                    rarityMap[rarity] = true
                end

                if next(rarityMap) == nil then return end

                local function waitForChild(parent, childName, timeout)
                    local startTime = tick()
                    timeout = timeout or 10
                    while tick() - startTime < timeout do
                        local child = parent:FindFirstChild(childName)
                        if child then return child end
                        task.wait(0.1)
                    end
                    return nil
                end

                local function isExcludedItem(itemName)
                    if not itemName then return true end
                    local lowerName = string.lower(itemName)
                    if string.find(lowerName, "cindercoil eel") or 
                       string.find(lowerName, "molten serpent") or
                       string.find(lowerName, "obsidian ray") or
                       string.find(lowerName, "infernal isonade") then
                        return false
                    end
                    for keyword, _ in pairs(EXCLUDED_ITEMS) do
                        if string.find(lowerName, keyword) then
                            return true
                        end
                    end
                    return false
                end

                if not storageClonedCrate or not storageClonedCrate.Parent then
                    local frozenPosition = HumanoidRootPart.CFrame
                    storageFreezeActive = true

                    task.spawn(function()
                        while storageFreezeActive do
                            local char = LocalPlayer.Character
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hrp and frozenPosition then
                                    hrp.CFrame = frozenPosition
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                    hrp.AssemblyAngularVelocity = Vector3.zero
                                    if hum then
                                        hum:ChangeState(Enum.HumanoidStateType.Seated)
                                    end
                                end
                            end
                            task.wait()
                        end
                    end)

                    task.wait(4)
                    pcall(function()
                        JoinAquarium:FireServer(LocalPlayer.UserId)
                    end)

                    task.wait(2)
                    local userFolder = waitForChild(Workspace, tostring(LocalPlayer.UserId), 5)
                    if userFolder then
                        local storageCrate = waitForChild(userFolder, "StorageCrate", 3)
                        if storageCrate then
                            pcall(function()
                                storageClonedCrate = storageCrate:Clone()
                                storageClonedCrate.Name = "ClonedStorageCrate_" .. LocalPlayer.UserId
                                storageClonedCrate.Parent = ReplicatedStorage
                            end)
                        end
                    end
                    task.wait(0.5)
                end

                local inventory = nil
                pcall(function()
                    if DataController.InventoryReplicator then
                        inventory = DataController.InventoryReplicator:Index({"Inventory"})
                    else
                        inventory = DataController.fetch("Inventory")
                    end
                end)

                if not inventory then return end

                local itemsToDeposit = {}
                for itemId, itemData in pairs(inventory) do
                    local displayInfo = itemDisplayInfo[itemData.name]
                    local hasValidRarity = false
                    if displayInfo and displayInfo.rarity then
                        if rarityMap[displayInfo.rarity] then
                            hasValidRarity = true
                        end
                    end

                    local isGeode = string.find(string.lower(itemData.name), "geode") ~= nil
                    if hasValidRarity or isGeode then
                        local isFavorited = itemData.sub and itemData.sub.Favourited
                        if not isFavorited then
                            if not isExcludedItem(itemData.name) then
                                table.insert(itemsToDeposit, itemId)
                            end
                        end
                    end
                end

                if #itemsToDeposit > 0 then
                    pcall(function()
                        BulkMoveRemote:InvokeServer(itemsToDeposit, false)
                    end)
                    task.wait(0.5)
                end

                storageFreezeActive = false
            end)

            storageFreezeActive = false

            if not success then
                warn("[AutoStorage] Inner error: " .. tostring(err))
            end

            if needsTeleport then
                task.spawn(function()
                    RestoreAfterTeleport(prevAutoCast, prevEquipRod)
                    local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local rod = backpack:FindFirstChild("Rod") or backpack:FindFirstChildOfClass("Tool")
                        if rod then
                            local char = Players.LocalPlayer.Character
                            if char then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum then hum:EquipTool(rod) end
                            end
                        end
                    end
                end)
            end
        end)

        if not overallOk then
            warn("[AutoStorage] Error: " .. tostring(overallErr))
        end
        storageFreezeActive = false
        autoStorageRunning = false
    end)
end

local function startAutoStorageLoop()
    task.spawn(function()
        while _G.Config and _G.Config.AutoStorageEnabled do
            if not autoStorageRunning then
                executeAutoStorage()
                while autoStorageRunning and _G.Config.AutoStorageEnabled do
                    task.wait(0.5)
                end
                if _G.Config and _G.Config.AutoStorageEnabled then
                    local interval = _G.Config.AutoStorageInterval or 60
                    task.wait(interval)
                end
            else
                task.wait(1)
            end
        end
    end)
end

local function AutoSellStorage()
    if autoSellStorageRunning then return end
    autoSellStorageRunning = true

    task.spawn(function()
        local useNpc = nil
        local idle = nil

        pcall(function()
            local char = Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local prevAutoCast, prevEquipRod = PrepareForTeleport()
                local oldCFrame = hrp.CFrame
                print("[AutoSell] Menyimpan posisi awal dan teleport ke Moosewood...")
                hrp.CFrame = CFrame.new(481, 151, 299)
                task.wait(1.5)

                local npcsFolder = Workspace:WaitForChild("world"):WaitForChild("npcs")
                local originalNpc = npcsFolder:WaitForChild("Marc Merchant", 10)

                if originalNpc then
                    print("[AutoSell] NPC ditemukan, menyimpan data referensi...")
                    useNpc = originalNpc
                    idle = useNpc:WaitForChild("description"):WaitForChild("idle", 5)
                else
                    print("[AutoSell] Marc Merchant tidak ditemukan setelah teleport!")
                end

                print("[AutoSell] Kembali ke posisi awal...")
                hrp.CFrame = oldCFrame
                RestoreAfterTeleport(prevAutoCast, prevEquipRod)
            end
        end)

        local args = nil
        if useNpc and idle then
            args = {
                {
                    voice = 12,
                    uid = "merchant_moosewood",
                    npc = useNpc,
                    idle = idle
                }
            }
        else
            print("[AutoSell] AutoSell dibatalkan karena NPC gagal dimuat.")
            autoSellStorageRunning = false
            return
        end

        print("[AutoSell] Memulai loop pemantauan event...")
        while _G.Config and _G.Config.AutoSellStorage do
            local currentEvent = getAdminEventStatus()
            local allowedEvents = _G.Config.AutoSellEvents or {}
            local isEventAllowed = false
            if currentEvent ~= "None" then
                local checkName = currentEvent:lower()
                for _, evt in pairs(allowedEvents) do
                    if checkName:find(evt) then
                        isEventAllowed = true
                        break
                    end
                end
            end

            if isEventAllowed and currentEvent ~= lastAdminEvent then
                lastAdminEvent = currentEvent

                print("[AutoSell] Event terdeteksi ("..currentEvent.."), Mengeksekusi SellAllStorage:InvokeServer() di background...")
                local events = ReplicatedStorage:WaitForChild("events")
                task.spawn(function()
                    local successInvoke, err = pcall(function()
                        events:WaitForChild("SellAllStorage"):InvokeServer(unpack(args))
                    end)
                    if not successInvoke then
                        print("[AutoSell] Gagal eksekusi SellAllStorage:", err)
                    end
                end)
            end
            task.wait(5)
        end
        autoSellStorageRunning = false
    end)
end

return {
    Execute = executeAutoStorage,
    StartLoop = startAutoStorageLoop,
    StartSellStorage = AutoSellStorage,
}
