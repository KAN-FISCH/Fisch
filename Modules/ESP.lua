local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EspPlayers = false
local EspZone = false
local EspZoneAll = false
local EspNpc = false
local EspRoaming = false
local EspHunts = false

-- Tracking registry for all active ESP instances
local trackedEsps = {
    Players = {},
    Hunts = {},
    Zones = {},
    ZonesAll = {},
    NPCs = {},
    Roaming = {}
}

local function getObjPos(obj)
    if not obj or not obj.Parent then return nil end
    local ok, pos = pcall(function()
        if obj:IsA("BasePart") then
            return obj.Position
        elseif obj:IsA("Model") then
            return obj:GetPivot().Position
        end
        return nil
    end)
    return ok and pos or nil
end

local function ClearCategory(cat)
    if not trackedEsps[cat] then return end
    for target, data in pairs(trackedEsps[cat]) do
        pcall(function()
            if data.bill and data.bill.Parent then data.bill:Destroy() end
            if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        end)
        if target and target.Parent then
            pcall(function()
                for _, c in ipairs(target:GetChildren()) do
                    if c.Name == "BF_ESP" or c.Name == "BF_Highlight" then
                        c:Destroy()
                    end
                end
            end)
        end
    end
    trackedEsps[cat] = {}
end

local function PurgeAllEsp()
    for cat in pairs(trackedEsps) do
        ClearCategory(cat)
    end
    -- Deep sweep in workspace & CoreGui for any stray/orphaned ESP elements
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "BF_ESP" or obj.Name == "BF_Highlight" then
                pcall(function() obj:Destroy() end)
            end
        end
    end)
    pcall(function()
        local core = game:GetService("CoreGui")
        for _, obj in ipairs(core:GetChildren()) do
            if obj.Name == "BF_ESP" then
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

local function AddEsp(target, name, color, category, maxDist, offset)
    if not target or not target.Parent then return end

    -- Destroy existing ESP on target if any
    pcall(function()
        for _, c in ipairs(target:GetChildren()) do
            if c.Name == "BF_ESP" or c.Name == "BF_Highlight" then
                c:Destroy()
            end
        end
    end)

    local success, bill = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name = "BF_ESP"
        b.AlwaysOnTop = true
        b.Size = UDim2.new(0, 180, 0, 30)
        b.Adornee = target
        b.StudsOffset = offset or Vector3.new(0, 2.5, 0)
        b.MaxDistance = maxDist or 3500
        b.ResetOnSpawn = false

        local text = Instance.new("TextLabel")
        text.Name = "TextLabel"
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        text.TextStrokeTransparency = 0.1
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Text = name or "ESP"
        text.Parent = b

        b.Parent = target
        return b
    end)

    if not success or not bill then return end

    local h = nil
    if category == "Players" or category == "Hunts" then
        pcall(function()
            local highlightTarget = target:IsA("Model") and target or (target.Parent and target.Parent:IsA("Model") and target.Parent.Parent ~= workspace and not target.Parent:IsA("Folder") and target.Parent)
            if highlightTarget and not target:FindFirstChild("BF_Highlight") then
                h = Instance.new("Highlight")
                h.Name = "BF_Highlight"
                h.FillColor = color or Color3.fromRGB(255, 255, 255)
                h.OutlineColor = color or Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.85
                h.OutlineTransparency = 0.3
                h.Adornee = highlightTarget
                h.Parent = target
            end
        end)
    end

    local textLabel = bill:FindFirstChildWhichIsA("TextLabel")
    if category and trackedEsps[category] then
        trackedEsps[category][target] = { bill = bill, highlight = h, label = textLabel }
    end
end

local targetEvents = {
    ["Orca"] = true, ["Orcas Pool"] = true, ["Baby Bloop Fish"] = true, ["Bloop Fish"] = true, ["Moby"] = true, ["Whales Pool"] = true,
    ["Megalodon"] = true, ["Mossjaw"] = true, ["Megalodon Ancient"] = true,
    ["Megalodon Phantom"] = true, ["Great White Shark"] = true, ["Hammerhead Shark"] = true,
    ["Whale Shark"] = true, ["The Depths - Serpent"] = true, ["Isonade"] = true,
    ["Forsaken Veil - Scylla"] = true, ["Blarney McBreeze"] = true, ["Sea Leviathan Pool"] = true,
    ["Animal Pool"] = true, ["Octophant Pool Without Elephant"] = true, ["Kraken Pool"] = true,
    ["Blue Moon - Second Sea"] = true, ["Blue Moon - First Sea"] = true,
    ["LEGO"] = true, ["LEGO - Studolodon"] = true, ["Mosslurker"] = true, ["Narwhal"] = true,
    ["Megalodon Default"] = true, ["Kraken"] = true, ["Meteor Shower"] = true,
    ["Sunken Treasure"] = true, ["Coral Geyser"] = true, ["Atlantis"] = true, ["Cursed Storm"] = true,
    ["Strange Whirlpool"] = true, ["Grand Reef"] = true, ["Forsaken Veil"] = true, ["Sovereign Beam"] = true
}

-- Initial purge on load to clean up any past leftovers
pcall(PurgeAllEsp)

task.spawn(function()
    while true do
        local anyActive = EspPlayers or EspZone or EspZoneAll or EspNpc or EspRoaming or EspHunts
        if not anyActive then
            task.wait(1.5)
        else
            task.wait(0.8)
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myPos = myRoot and myRoot.Position

            -- 1. Players ESP
            if EspPlayers then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Parent then
                            local data = trackedEsps.Players[hrp]
                            local dist = myPos and math.floor((myPos - hrp.Position).Magnitude) or 0
                            if not data or not data.bill or not data.bill.Parent then
                                AddEsp(hrp, "👤 " .. p.Name .. " [" .. dist .. "m]", Color3.fromRGB(255, 80, 80), "Players", 5000)
                            elseif data.label then
                                data.label.Text = "👤 " .. p.Name .. " [" .. dist .. "m]"
                            end
                        end
                    end
                end
                -- Sweep despawned players
                for target, data in pairs(trackedEsps.Players) do
                    if not target or not target.Parent or not target.Parent.Parent then
                        pcall(function()
                            if data.bill then data.bill:Destroy() end
                            if data.highlight then data.highlight:Destroy() end
                        end)
                        trackedEsps.Players[target] = nil
                    end
                end
            end

            -- 2. Hunts & Live Events ESP
            if EspHunts then
                local activeFolder = workspace:FindFirstChild("active")
                local activeEvents = activeFolder and (activeFolder:FindFirstChild("events") or activeFolder:FindFirstChild("hunts"))
                local activeHuntsFolder = activeFolder and activeFolder:FindFirstChild("hunts")

                local eventContainers = {}
                if activeEvents then table.insert(eventContainers, activeEvents) end
                if activeHuntsFolder and activeHuntsFolder ~= activeEvents then table.insert(eventContainers, activeHuntsFolder) end

                -- Active live bosses / events (Megalodon, Kraken, etc.)
                for _, container in ipairs(eventContainers) do
                    for _, event in ipairs(container:GetChildren()) do
                        local part = event:IsA("BasePart") and event or (event:IsA("Model") and (event.PrimaryPart or event:FindFirstChildWhichIsA("BasePart")))
                        if part and part.Parent then
                            local data = trackedEsps.Hunts[part]
                            local pPos = getObjPos(part) or part.Position
                            local dist = myPos and math.floor((myPos - pPos).Magnitude) or 0
                            if not data or not data.bill or not data.bill.Parent then
                                AddEsp(part, "⚔️ " .. event.Name .. " [" .. dist .. "m]", Color3.fromRGB(255, 170, 0), "Hunts", 20000)
                            elseif data.label then
                                data.label.Text = "⚔️ " .. event.Name .. " [" .. dist .. "m]"
                            end
                        end
                    end
                end

                -- Special event fishing pools only (Orcas Pool, Whales Pool, Kraken Pool, etc.)
                local zones = workspace:FindFirstChild("zones")
                local fishingFolder = zones and zones:FindFirstChild("fishing")
                if fishingFolder then
                    local seenEventPools = {}
                    for _, zone in ipairs(fishingFolder:GetChildren()) do
                        if targetEvents[zone.Name] and not seenEventPools[zone.Name] then
                            seenEventPools[zone.Name] = true
                            local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and (zone.PrimaryPart or zone:FindFirstChildWhichIsA("BasePart")))
                            if part and part.Parent then
                                local data = trackedEsps.Hunts[part]
                                local pPos = getObjPos(part) or part.Position
                                local dist = myPos and math.floor((myPos - pPos).Magnitude) or 0
                                if not data or not data.bill or not data.bill.Parent then
                                    AddEsp(part, "🌊 " .. zone.Name .. " [" .. dist .. "m]", Color3.fromRGB(0, 230, 255), "Hunts", 15000)
                                elseif data.label then
                                    data.label.Text = "🌊 " .. zone.Name .. " [" .. dist .. "m]"
                                end
                            end
                        end
                    end
                end

                -- Sweep despawned events
                for target, data in pairs(trackedEsps.Hunts) do
                    if not target or not target.Parent then
                        pcall(function()
                            if data.bill then data.bill:Destroy() end
                            if data.highlight then data.highlight:Destroy() end
                        end)
                        trackedEsps.Hunts[target] = nil
                    end
                end
            end

            -- 3. Fishing Zones ESP (Deduplicated, 1 label per unique zone name)
            if EspZone or EspZoneAll then
                local catName = EspZone and "Zones" or "ZonesAll"
                local zones = workspace:FindFirstChild("zones")
                local fishingFolder = zones and zones:FindFirstChild("fishing")
                if fishingFolder then
                    local seenZones = {}
                    for _, zone in ipairs(fishingFolder:GetChildren()) do
                        if not seenZones[zone.Name] then
                            seenZones[zone.Name] = true
                            local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and (zone.PrimaryPart or zone:FindFirstChildWhichIsA("BasePart")))
                            if part and part.Parent then
                                local data = trackedEsps[catName][part]
                                local pPos = getObjPos(part) or part.Position
                                local dist = myPos and math.floor((myPos - pPos).Magnitude) or 0
                                if not data or not data.bill or not data.bill.Parent then
                                    AddEsp(part, "🎣 " .. zone.Name .. " [" .. dist .. "m]", Color3.fromRGB(80, 200, 255), catName, 3500)
                                elseif data.label then
                                    data.label.Text = "🎣 " .. zone.Name .. " [" .. dist .. "m]"
                                end
                            end
                        end
                    end
                end
                for target, data in pairs(trackedEsps[catName]) do
                    if not target or not target.Parent then
                        pcall(function()
                            if data.bill then data.bill:Destroy() end
                        end)
                        trackedEsps[catName][target] = nil
                    end
                end
            end

            -- 4. NPCs ESP
            if EspNpc then
                local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                        if hrp and hrp.Parent then
                            local data = trackedEsps.NPCs[hrp]
                            local dist = myPos and math.floor((myPos - hrp.Position).Magnitude) or 0
                            if not data or not data.bill or not data.bill.Parent then
                                AddEsp(hrp, "💬 " .. npc.Name .. " [" .. dist .. "m]", Color3.fromRGB(100, 255, 100), "NPCs", 3000)
                            elseif data.label then
                                data.label.Text = "💬 " .. npc.Name .. " [" .. dist .. "m]"
                            end
                        end
                    end
                end
                for target, data in pairs(trackedEsps.NPCs) do
                    if not target or not target.Parent then
                        pcall(function()
                            if data.bill then data.bill:Destroy() end
                        end)
                        trackedEsps.NPCs[target] = nil
                    end
                end
            end

            -- 5. Roaming Fish ESP
            if EspRoaming then
                local active = workspace:FindFirstChild("active")
                local rFish = active and active:FindFirstChild("roamingFish")
                if rFish then
                    for _, child in ipairs(rFish:GetChildren()) do
                        if child:IsA("Model") or child:IsA("Folder") then
                            for _, model in ipairs(child:GetChildren()) do
                                if model:IsA("Model") then
                                    local hitbox = model:FindFirstChild("Hitbox") or model.PrimaryPart
                                    if hitbox and hitbox.Parent then
                                        local fishName = model:GetAttribute("FishName") or (model.Name:find("_") and model.Name:match("^([^_]+)") or model.Name)
                                        local rarity = child.Name
                                        local color = Color3.fromRGB(255, 255, 255)
                                        if rarity == "Common" then color = Color3.fromRGB(200, 200, 200)
                                        elseif rarity == "Uncommon" then color = Color3.fromRGB(100, 255, 100)
                                        elseif rarity == "Rare" then color = Color3.fromRGB(50, 150, 255)
                                        elseif rarity == "Legendary" then color = Color3.fromRGB(255, 200, 50)
                                        elseif rarity == "Exotic" then color = Color3.fromRGB(255, 50, 255)
                                        elseif rarity == "Mythical" then color = Color3.fromRGB(255, 0, 100)
                                        end
                                        local data = trackedEsps.Roaming[hitbox]
                                        local dist = myPos and math.floor((myPos - hitbox.Position).Magnitude) or 0
                                        if not data or not data.bill or not data.bill.Parent then
                                            AddEsp(hitbox, "🐟 " .. fishName .. " [" .. dist .. "m]", color, "Roaming", 2500, Vector3.new(0, 2, 0))
                                        elseif data.label then
                                            data.label.Text = "🐟 " .. fishName .. " [" .. dist .. "m]"
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                for target, data in pairs(trackedEsps.Roaming) do
                    if not target or not target.Parent then
                        pcall(function()
                            if data.bill then data.bill:Destroy() end
                        end)
                        trackedEsps.Roaming[target] = nil
                    end
                end
            end
        end
    end
end)

local ESP = {
    SetEspPlayers = function(state)
        EspPlayers = state
        if not state then ClearCategory("Players") end
    end,
    SetEspZone = function(state)
        EspZone = state
        if not state then ClearCategory("Zones") end
    end,
    SetEspZoneAll = function(state)
        EspZoneAll = state
        if not state then ClearCategory("ZonesAll") end
    end,
    SetEspNpc = function(state)
        EspNpc = state
        if not state then ClearCategory("NPCs") end
    end,
    SetEspRoaming = function(state)
        EspRoaming = state
        if not state then ClearCategory("Roaming") end
    end,
    SetEspHunts = function(state)
        EspHunts = state
        if not state then ClearCategory("Hunts") end
    end,
    PurgeAll = PurgeAllEsp,
    ClearAll = PurgeAllEsp,
    AddEsp = AddEsp,
    RemoveEsp = function(target)
        for _, cat in pairs(trackedEsps) do
            if cat[target] then
                pcall(function()
                    if cat[target].bill then cat[target].bill:Destroy() end
                    if cat[target].highlight then cat[target].highlight:Destroy() end
                end)
                cat[target] = nil
            end
        end
        if target and target.Parent then
            pcall(function()
                for _, c in ipairs(target:GetChildren()) do
                    if c.Name == "BF_ESP" or c.Name == "BF_Highlight" then
                        c:Destroy()
                    end
                end
            end)
        end
    end,
}

setmetatable(ESP, {
    __call = function(self, mode, value)
        if mode == "Players" then
            self.SetEspPlayers(value)
        elseif mode == "Zone" or mode == "Zones" then
            self.SetEspZone(value)
        elseif mode == "ZoneAll" or mode == "ZonesAll" then
            self.SetEspZoneAll(value)
        elseif mode == "NPC" or mode == "NPCs" then
            self.SetEspNpc(value)
        elseif mode == "Roaming" or mode == "RoamingFish" then
            self.SetEspRoaming(value)
        elseif mode == "Hunts" or mode == "Events" then
            self.SetEspHunts(value)
        elseif mode == "Clear" or mode == "Purge" then
            self.PurgeAll()
        end
    end
})

return ESP