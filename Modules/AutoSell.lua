local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local autoSellRunning = false
local autoSellStorageRunning = false
local _shadyFailCount = 0

local _clonedMarcNpc = nil
local _clonedMarcIdle = nil
local _clonedShadyNpc = nil
local _clonedShadyIdle = nil

local SHADY_MUTATIONS = {
    "Shady",
    "Sludge"
}

local _cachedDataController = nil
local function getCachedDataController()
    if _cachedDataController then return _cachedDataController end
    pcall(function()
        _cachedDataController = require(ReplicatedStorage:WaitForChild("client"):WaitForChild("legacyControllers"):WaitForChild("DataController"))
    end)
    return _cachedDataController
end

local function getInventory()
    local dc = getCachedDataController()
    if not dc then return nil end
    local inv = nil
    pcall(function()
        if dc.InventoryReplicator then
            inv = dc.InventoryReplicator:Index({"Inventory"})
        else
            inv = dc.fetch("Inventory")
        end
    end)
    return inv
end

local function isSellable(itemName)
    if not itemName then return false end
    local lowerName = itemName:lower()

    local nonSellableKeywords = {
        "geode", "relic", "key", "crate", "totem", "potion", "bait", "rod", 
        "coin", "wood", "stone", "fragment", "essence", "gps", "glider", 
        "whistle", "compass", "anchor", "bag", "chest", "barrel", "conch",
        "amulet", "flipper", "glove", "plushie", "waders", "suit", "gear",
        "matrix", "nuke", "nuklir", "tool", "card", "present", "gift", "ticket",
        "bucket", "flashlight", "hat", "mask"
    }

    if string.find(lowerName, "wood", 1, true) and not string.find(lowerName, "driftwood", 1, true) then
        return false
    end

    for _, keyword in ipairs(nonSellableKeywords) do
        if string.find(lowerName, keyword, 1, true) then
            return false
        end
    end

    return true
end

local function isShadyOrSludge(itemName, mutation)
    local itemLower = tostring(itemName or ""):lower()
    local mutLower = tostring(mutation or ""):lower()
    for _, m in ipairs(SHADY_MUTATIONS) do
        local check = m:lower()
        if itemLower:find(check) or mutLower:find(check) then
            return true
        end
    end
    return false
end

local function scanForShady()
    local hasShady = false
    local inventory = getInventory()
    if inventory then
        for itemId, itemData in pairs(inventory) do
            if itemData.sub and not itemData.sub.Favourited and itemData.sub.Weight and isSellable(itemData.name) then
                local mut = itemData.sub.Mutation
                if isShadyOrSludge(itemData.name, mut) then
                    hasShady = true
                    break
                end
            end
        end
    end
    return hasShady
end

local function isShadyLocked()
    if _G.ShadyInInventory then
        return true
    end
    if _G.LastShadyStartReelTime and tick() - _G.LastShadyStartReelTime < 15 then
        return true
    end
    if scanForShady() then
        _G.ShadyInInventory = true
        return true
    end
    return false
end

local function PrepareForTeleport()
    local prevAutoCast = _G.Config and _G.Config.AutoCast
    if _G.Config then _G.Config.AutoCast = false end
    return prevAutoCast
end

local function RestoreAfterTeleport(prevAutoCast)
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool.Parent = lp.Backpack
        end
    end
    if prevAutoCast ~= nil then
        _G.Config.AutoCast = prevAutoCast
    end
end

local function findMarcNpcInWorkspace()
    local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
    local marc = npcs and npcs:FindFirstChild("Marc Merchant")
    if not marc then marc = workspace:FindFirstChild("Marc Merchant") end
    if not marc then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Marc Merchant" then
                marc = v
                break
            end
        end
    end
    if marc then
        local desc = marc:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then return marc, idle end
    end
    return nil, nil
end

local function cloneMarcNpc(marc)
    if not marc then return nil, nil end
    local clone = nil
    pcall(function()
        marc.Archivable = true
        clone = marc:Clone()
        if clone then
            clone.Name = "Marc Merchant"
            local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            clone.Parent = npcsFolder or workspace
        end
    end)
    if clone then
        local desc = clone:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then
            _clonedMarcNpc = clone
            _clonedMarcIdle = idle
            return clone, idle
        end
    end
    return nil, nil
end

local function getOrFetchMarcNpc()
    if _clonedMarcNpc and _clonedMarcNpc.Parent then
        local desc = _clonedMarcNpc:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then return _clonedMarcNpc, idle end
    end

    local marc, idle = findMarcNpcInWorkspace()
    if marc and idle then
        local cNpc, cIdle = cloneMarcNpc(marc)
        if cNpc and cIdle then return cNpc, cIdle end
    end

    -- Teleport to Marc Merchant location at Moosewood to load & clone NPC
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local prevAutoCast = PrepareForTeleport()
            local savedCF = hrp.CFrame
            hrp.CFrame = CFrame.new(466, 151, 229)
            task.wait(2)
            marc, idle = findMarcNpcInWorkspace()
            if marc then
                cloneMarcNpc(marc)
            end
            hrp.CFrame = savedCF
            task.wait(0.5)
            RestoreAfterTeleport(prevAutoCast)
        end
    end)

    if _clonedMarcNpc and _clonedMarcIdle then
        return _clonedMarcNpc, _clonedMarcIdle
    end

    return marc, idle
end

local function findShadyNpcInWorkspace()
    local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
    local shady = npcs and npcs:FindFirstChild("Shady Merchant")
    if not shady then shady = workspace:FindFirstChild("Shady Merchant") end
    if not shady then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Shady Merchant" then
                shady = v
                break
            end
        end
    end
    if shady then
        local desc = shady:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then return shady, idle end
    end
    return nil, nil
end

local function cloneShadyNpc(shady)
    if not shady then return nil, nil end
    local clone = nil
    pcall(function()
        shady.Archivable = true
        clone = shady:Clone()
        if clone then
            clone.Name = "Shady Merchant"
            clone.Parent = shady.Parent or workspace
        end
    end)
    if clone then
        local desc = clone:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then
            _clonedShadyNpc = clone
            _clonedShadyIdle = idle
            return clone, idle
        end
    end
    return nil, nil
end

local function getOrFetchShadyNpc()
    if _clonedShadyNpc and _clonedShadyNpc.Parent then
        local desc = _clonedShadyNpc:FindFirstChild("description")
        local idle = desc and desc:FindFirstChild("idle")
        if idle then return _clonedShadyNpc, idle end
    end

    local shady, idle = findShadyNpcInWorkspace()
    if shady and idle then
        local cNpc, cIdle = cloneShadyNpc(shady)
        if cNpc and cIdle then return cNpc, cIdle end
    end

    -- Teleport to Shady Merchant location to load & clone NPC
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local prevAutoCast = PrepareForTeleport()
            local savedCF = hrp.CFrame
            hrp.CFrame = CFrame.new(-2997, -1023, 6067)
            task.wait(2)
            shady, idle = findShadyNpcInWorkspace()
            if shady then
                cloneShadyNpc(shady)
            end
            hrp.CFrame = savedCF
            task.wait(0.5)
            RestoreAfterTeleport(prevAutoCast)
        end
    end)

    if _clonedShadyNpc and _clonedShadyIdle then
        return _clonedShadyNpc, _clonedShadyIdle
    end

    return shady, idle
end

local _cachedSellEvents = nil
local function getCachedSellEvents()
    if not _cachedSellEvents then
        pcall(function()
            _cachedSellEvents = ReplicatedStorage:WaitForChild("events", 5)
        end)
    end
    return _cachedSellEvents
end

local function clickYesPopup()
    pcall(function()
        local gui = LocalPlayer.PlayerGui
        for _, screen in ipairs(gui:GetChildren()) do
            if screen:IsA("ScreenGui") and screen.Enabled then
                for _, frame in ipairs(screen:GetDescendants()) do
                    if (frame:IsA("TextButton") or frame:IsA("ImageButton")) and frame.Visible then
                        local t = tostring(frame.Text or ""):lower()
                        local name = tostring(frame.Name):lower()
                        if t:find("yes") or t:find("ya") or t:find("confirm") or t:find("sell") or name:find("yes") or name:find("confirm") then
                            pcall(function()
                                local mockInput = { UserInputType = Enum.UserInputType.MouseButton1 }
                                if firesignal then
                                    pcall(function() firesignal(frame.Activated, mockInput) end)
                                    pcall(function() firesignal(frame.MouseButton1Click) end)
                                end
                                if getconnections then
                                    for _, conn in pairs(getconnections(frame.Activated)) do
                                        pcall(function() conn:Fire(mockInput) end)
                                    end
                                    for _, conn in pairs(getconnections(frame.MouseButton1Click)) do
                                        pcall(function() conn:Fire() end)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

local function sellShadyInventory()
    if isShadyLocked() then
        print("[AutoSell] Shady fish detected/locked, attempting to sell to Shady Merchant...")
        local success = false
        pcall(function()
            local shadyNpc, idle = getOrFetchShadyNpc()
            local events = getCachedSellEvents()
            if events and shadyNpc and idle then
                local args = {
                    {
                        voice = 12,
                        uid = "Shady Merchant",
                        npc = shadyNpc,
                        idle = idle
                    }
                }
                if events:FindFirstChild("ShadySellAll") then
                    events.ShadySellAll:InvokeServer(unpack(args))
                    success = true
                end
            end
        end)

        if success then
            local start = tick()
            while tick() - start < 2 do
                task.wait(0.3)
                if not scanForShady() then
                    _G.ShadyInInventory = false
                    _shadyFailCount = 0
                    break
                end
            end
        end

        if scanForShady() then
            _shadyFailCount = _shadyFailCount + 1
            if _shadyFailCount >= 3 then
                print("[AutoSell] Shady sell failed 3 times, unlocking normal sell")
                _G.ShadyInInventory = false
                _shadyFailCount = 0
            end
        end
    end
end

local function performSellAll()
    pcall(function()
        local marc, idle = getOrFetchMarcNpc()
        local events = getCachedSellEvents()
        if events and marc and idle then
            local args = {
                {
                    voice = 12,
                    uid = "merchant_moosewood",
                    npc = marc,
                    idle = idle
                }
            }
            if events:FindFirstChild("SellAll") then
                events.SellAll:InvokeServer(unpack(args))
            end
            pcall(function()
                local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
                if net and net:FindFirstChild("RF/SellAllItems") then
                    net["RF/SellAllItems"]:InvokeServer()
                end
            end)
            task.wait(0.3)
            clickYesPopup()
        end
    end)
end

local function AutoSell()
    if autoSellRunning then return end
    autoSellRunning = true

    task.spawn(function()
        while _G.Config and _G.Config.AutoSell do
            local hasShady = false
            local normalSellCount = 0

            local inventory = getInventory()
            if inventory then
                for itemId, itemData in pairs(inventory) do
                    if itemData.sub and not itemData.sub.Favourited then
                        if itemData.sub.Weight and isSellable(itemData.name) then
                            local mut = itemData.sub.Mutation
                            if isShadyOrSludge(itemData.name, mut) then
                                hasShady = true
                            else
                                normalSellCount = normalSellCount + 1
                            end
                        end
                    end
                end
            end

            if hasShady then
                _G.ShadyInInventory = true
                sellShadyInventory()
                task.wait(1)
            else
                if not isShadyLocked() then
                    performSellAll()
                else
                    sellShadyInventory()
                    print("[AutoSell] Shady fish pending sale, attempting shady sell")
                end
                task.wait(1.5)
            end
        end
        autoSellRunning = false
    end)
end

local function AutoSellStorage()
    if autoSellStorageRunning then return end
    autoSellStorageRunning = true

    task.spawn(function()
        local useNpc, idle = getOrFetchMarcNpc()
        if not (useNpc and idle) then
            autoSellStorageRunning = false
            return
        end

        local args = {{voice = 12, uid = "merchant_moosewood", npc = useNpc, idle = idle}}

        while _G.Config and _G.Config.AutoSellStorage do
            pcall(function()
                local events = game:GetService("ReplicatedStorage"):WaitForChild("events")
                local sellAllStorage = events:FindFirstChild("SellAllStorage")
                if sellAllStorage then
                    task.spawn(function()
                        pcall(function() sellAllStorage:InvokeServer(unpack(args)) end)
                    end)
                    task.wait(1)
                    clickYesPopup()
                end
            end)
            task.wait(1)
        end
        autoSellStorageRunning = false
    end)
end

local M = {
    AutoSell = AutoSell,
    AutoSellStorage = AutoSellStorage,
    sellShadyInventory = sellShadyInventory,
}

setmetatable(M, {
    __call = function(self, value)
        _G.Config.AutoSell = value
        if value then
            AutoSell()
        end
    end
})

return M
