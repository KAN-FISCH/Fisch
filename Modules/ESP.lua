local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EspPlayers = false
local EspZone = false
local EspZoneAll = false
local EspNpc = false
local EspRoaming = false

local function AddEsp(target, name, color, offset)
    if not target then return end
    if target:FindFirstChild("BF_ESP") then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "BF_ESP"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.Adornee = target
    bill.StudsOffset = offset or Vector3.new(0, 3, 0)

    local text = Instance.new("TextLabel", bill)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = color
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.Text = name
    bill.Parent = target

    if target.Parent and target.Parent:IsA("Model") then
        local h = Instance.new("Highlight")
        h.Name = "BF_Highlight"
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.8
        h.Adornee = target.Parent
        h.Parent = target
    end
end

local function RemoveEsp(target)
    if target and target:FindFirstChild("BF_ESP") then
        target.BF_ESP:Destroy()
    end
    if target and target:FindFirstChild("BF_Highlight") then
        target.BF_Highlight:Destroy()
    end
end

-- Initialize Loop
task.spawn(function()
    while true do
        task.wait(1)
        if EspPlayers then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    AddEsp(hrp, p.Name, Color3.fromRGB(255, 0, 0))
                    if hrp:FindFirstChild("BF_ESP") then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local dist = (myRoot.Position - hrp.Position).Magnitude
                            hrp.BF_ESP.TextLabel.Text = p.Name .. " [" .. math.floor(dist) .. "m]"
                        end
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    RemoveEsp(p.Character.HumanoidRootPart)
                end
            end
        end

        local fishingFolder = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
        if EspZone then
            if fishingFolder then
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
                for _, zone in ipairs(fishingFolder:GetChildren()) do
                    if targetEvents[zone.Name] then
                        local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and zone.PrimaryPart)
                        if part then
                            AddEsp(part, zone.Name, Color3.fromRGB(0, 255, 255))
                        end
                    end
                end
            end
        elseif EspZoneAll then
            if fishingFolder then
                for _, zone in ipairs(fishingFolder:GetChildren()) do
                    local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and zone.PrimaryPart)
                    if part then
                        AddEsp(part, zone.Name, Color3.fromRGB(200, 200, 200))
                    end
                end
            end
        else
            if fishingFolder then
                for _, zone in ipairs(fishingFolder:GetChildren()) do
                    local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and zone.PrimaryPart)
                    if part then
                        RemoveEsp(part)
                    end
                end
            end
        end

        if EspNpc then
            local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            if npcsFolder then
                for _, npc in ipairs(npcsFolder:GetChildren()) do
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        AddEsp(hrp, npc.Name, Color3.fromRGB(0, 255, 0))
                        if hrp:FindFirstChild("BF_ESP") then
                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local dist = (myRoot.Position - hrp.Position).Magnitude
                                hrp.BF_ESP.TextLabel.Text = npc.Name .. " [" .. math.floor(dist) .. "m]"
                            end
                        end
                    end
                end
            end
        else
            local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            if npcsFolder then
                for _, npc in ipairs(npcsFolder:GetChildren()) do
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        RemoveEsp(hrp)
                    end
                end
            end
        end

        if EspRoaming then
            local active = workspace:FindFirstChild("active")
            local rFish = active and active:FindFirstChild("roamingFish")
            if rFish then
                for _, child in ipairs(rFish:GetChildren()) do
                    if child:IsA("Model") or child:IsA("Folder") then
                        for _, model in ipairs(child:GetChildren()) do
                            if model:IsA("Model") then
                                local hitbox = model:FindFirstChild("Hitbox")
                                if hitbox then
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
                                    AddEsp(hitbox, fishName, color, Vector3.new(0, 2, 0))
                                    if hitbox:FindFirstChild("BF_ESP") then
                                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                        if myRoot then
                                            local dist = (myRoot.Position - hitbox.Position).Magnitude
                                            hitbox.BF_ESP.TextLabel.Text = fishName .. " [" .. math.floor(dist) .. "m]"
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            local active = workspace:FindFirstChild("active")
            local rFish = active and active:FindFirstChild("roamingFish")
            if rFish then
                for _, child in ipairs(rFish:GetChildren()) do
                    if child:IsA("Folder") then
                        for _, model in ipairs(child:GetChildren()) do
                            if model:IsA("Model") then
                                local hitbox = model:FindFirstChild("Hitbox")
                                if hitbox then
                                    RemoveEsp(hitbox)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local ESP = {
    SetEspPlayers = function(state) EspPlayers = state end,
    SetEspZone = function(state) EspZone = state end,
    SetEspZoneAll = function(state) EspZoneAll = state end,
    SetEspNpc = function(state) EspNpc = state end,
    SetEspRoaming = function(state) EspRoaming = state end,
    AddEsp = AddEsp,
    RemoveEsp = RemoveEsp,
}

setmetatable(ESP, {
    __call = function(self, mode, value)
        if mode == "Players" then
            EspPlayers = value
        elseif mode == "Zone" or mode == "Zones" then
            EspZone = value
        elseif mode == "ZoneAll" or mode == "ZonesAll" then
            EspZoneAll = value
        elseif mode == "NPC" or mode == "NPCs" then
            EspNpc = value
        elseif mode == "Roaming" or mode == "RoamingFish" then
            EspRoaming = value
        end
    end
})

return ESP
