local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Comprehensive database of all fishing rods in Fisch (scraped & verified from Fisch Wiki)
local ROD_DATA = {
    -- Starter / Moosewood
    ["Flimsy Rod"]           = { pos = Vector3.new(464.1, 150.5, 230.5),      price = 0,         island = "Moosewood",            npc = "Marc" },
    ["Training Rod"]         = { pos = Vector3.new(465.0, 150.0, 235.0),      price = 300,       island = "Moosewood",            npc = "Marc" },
    ["Plastic Rod"]          = { pos = Vector3.new(454.2, 150.5, 207.1),      price = 900,       island = "Moosewood",            npc = "Marc" },
    ["Carbon Rod"]           = { pos = Vector3.new(450.5, 150.5, 214.6),      price = 2000,      island = "Moosewood",            npc = "Marc" },
    ["Fast Rod"]             = { pos = Vector3.new(458.0, 150.5, 218.0),      price = 4500,      island = "Moosewood",            npc = "Marc" },
    ["Lucky Rod"]            = { pos = Vector3.new(446.8, 150.5, 222.0),      price = 5250,      island = "Moosewood",            npc = "Marc" },
    ["Long Rod"]             = { pos = Vector3.new(480.0, 150.0, 250.0),      price = 4500,      island = "Moosewood (Hill)",     npc = "Pierre" },
    ["Mythical Rod"]         = { pos = Vector3.new(389.5, 134.2, 305.8),      price = 55000,     island = "Moosewood",            npc = "Travelling Merchant" },
    ["Midas Rod"]            = { pos = Vector3.new(389.5, 134.2, 305.8),      price = 190000,    island = "Moosewood",            npc = "Travelling Merchant" },

    -- Roslit Bay & Roslit Volcano
    ["Steady Rod"]           = { pos = Vector3.new(-1480.0, 132.0, 715.0),    price = 7000,      island = "Roslit Bay",           npc = "Alfie" },
    ["Fortune Rod"]          = { pos = Vector3.new(-1508.0, 141.0, 750.0),    price = 11000,     island = "Roslit Bay",           npc = "Alfie" },
    ["Rapid Rod"]            = { pos = Vector3.new(-1475.0, 132.0, 720.0),    price = 12000,     island = "Roslit Bay",           npc = "Alfie" },
    ["Magma Rod"]            = { pos = Vector3.new(-1930.0, 165.0, 310.0),    price = 0,         island = "Roslit Volcano",       npc = "Orc Quest" },
    ["Phoenix Rod"]          = { pos = Vector3.new(-1930.0, 165.0, 310.0),    price = 45000,     island = "Roslit Volcano",       npc = "Volcano Altar" },
    ["Shady Rod"]            = { pos = Vector3.new(-1067.4, 130.8, -1163.3),  price = 0,         island = "Roslit Hamlet",        npc = "Shady Guy" },

    -- Terrapin Island
    ["Magnet Rod"]           = { pos = Vector3.new(-185.0, 134.0, 1940.0),    price = 15000,     island = "Terrapin Island",      npc = "Shop Stand" },
    ["Wildflower Rod"]       = { pos = Vector3.new(-185.0, 134.0, 1940.0),    price = 25000,     island = "Terrapin Island",      npc = "Flower Stand" },

    -- Sunstone Island
    ["The Lost Rod"]         = { pos = Vector3.new(-935.0, 132.0, -1125.0),   price = 50000,     island = "Sunstone Island",      npc = "Lost Explorer" },

    -- Snowcap Island
    ["Great Rod of Oscar"]   = { pos = Vector3.new(2625.0, 135.0, 2370.0),    price = 2500000,   island = "Snowcap Island",       npc = "Spike Vault" },

    -- Forsaken Shores
    ["Scurvy Rod"]           = { pos = Vector3.new(-2830.0, 214.0, 1510.0),   price = 50000,     island = "Forsaken Shores",      npc = "Skull Cave" },

    -- The Desolate Deep
    ["Reinforced Rod"]       = { pos = Vector3.new(-1650.0, -215.0, -2850.0), price = 20000,     island = "The Desolate Deep",    npc = "Deep Merchant" },
    ["Trident Rod"]          = { pos = Vector3.new(-1485.0, -225.0, -2200.0), price = 150000,    island = "The Desolate Deep",    npc = "Trident Temple" },
    ["Brick Rod"]            = { pos = Vector3.new(-1650.0, -215.0, -2850.0), price = 13337,     island = "The Desolate Deep",    npc = "Secret Elevator" },

    -- Vertigo & Caves
    ["Nocturnal Rod"]        = { pos = Vector3.new(-115.0, -515.0, 1070.0),   price = 11000,     island = "Vertigo",              npc = "Synth" },
    ["Aurora Rod"]           = { pos = Vector3.new(-115.0, -515.0, 1070.0),   price = 90000,     island = "Vertigo",              npc = "Synth (Aurora Event)" },
    ["Haunted Rod"]          = { pos = Vector3.new(-115.0, -515.0, 1070.0),   price = 30000,     island = "Vertigo",              npc = "Ghost Stand" },

    -- The Arch
    ["Destiny Rod"]          = { pos = Vector3.new(985.2, 142.5, -1220.0),    price = 190000,    island = "The Arch",             npc = "Cery (70% Bestiary)" },

    -- Keepers Altar
    ["Kings Rod"]            = { pos = Vector3.new(1296.06, -802.01, -299.01), price = 120000,   island = "Keepers Altar",        npc = "Keeper Altar" },

    -- Atlantis
    ["Depthseeker Rod"]      = { pos = Vector3.new(-4319.76, -603.71, 1716.2), price = 40000,    island = "Atlantis",             npc = "Atlantis Merchant" },
    ["Champions Rod"]        = { pos = Vector3.new(-4350.0, -603.71, 1730.0), price = 90000,    island = "Atlantis",             npc = "Inn Keeper" },

    -- Ancient Isle & Ancient Archives
    ["Stone Rod"]            = { pos = Vector3.new(5965.37, 258.97, 223.25),  price = 3000,      island = "Ancient Isle",         npc = "Pirate NPC" },
    ["Relic Rod"]            = { pos = Vector3.new(5740.0, 135.0, 420.0),     price = 8000,      island = "Archaeological Site",   npc = "Relic Stand" },
    ["Precision Rod"]        = { pos = Vector3.new(-3163.59, -753.32, 1860.06), price = 0,      island = "Ancient Archives",     npc = "Crafting Altar" },
    ["Wisdom Rod"]           = { pos = Vector3.new(-3163.59, -753.32, 1860.06), price = 0,      island = "Ancient Archives",     npc = "Crafting Altar" },
    ["Voyager Rod"]          = { pos = Vector3.new(-3163.59, -753.32, 1860.06), price = 0,      island = "Ancient Archives",     npc = "Crafting Altar" },

    -- Mushgrove Swamp
    ["Fungal Rod"]           = { pos = Vector3.new(2791.0, 140.0, -623.0),    price = 0,         island = "Mushgrove Swamp",      npc = "Agaric NPC" },
    ["Frog Rod"]             = { pos = Vector3.new(2791.0, 140.0, -623.0),    price = 12000,     island = "Mushgrove Swamp",      npc = "Mushgrove Stand" },

    -- Northern Expedition & Northern Summit
    ["Heaven's Rod"]         = { pos = Vector3.new(19980.0, 916.0, 5384.0),   price = 1750000,   island = "Northern Summit",      npc = "Glacial Vault" },
    ["Avalanche Rod"]        = { pos = Vector3.new(20147.0, 743.0, 5805.0),   price = 35000,     island = "Northern Expedition",  npc = "Overgrowth Cave" },

    -- Abyssal Zenith
    ["Rod of the Zenith"]    = { pos = Vector3.new(-13810.0, -11541.0, 106.92), price = 250000,  island = "Abyssal Zenith",       npc = "Zenith Altar" },

    -- Crimson Cavern
    ["Ruinous Oath"]         = { pos = Vector3.new(-998.65, -335.17, -4886.02), price = 5000000, island = "Crimson Cavern",      npc = "Crimson Vault" },

    -- Castaway Cliffs
    ["Firefly Rod"]          = { pos = Vector3.new(690.0, 135.0, -1693.0),    price = 9500,      island = "Castaway Cliffs",      npc = "Castaway Stand" },

    -- Scoria Reach / Ashbrook Town
    ["Daybreaker Rod"]       = { pos = Vector3.new(-5160.0, 137.99, -1452.02), price = 750000,   island = "Ashbrook Town",        npc = "Ashbrook Merchant" },

    -- Volcanic Vents
    ["Volcanic Rod"]         = { pos = Vector3.new(-3136.28, -2010.89, 4056.85), price = 150000, island = "Volcanic Vents",      npc = "Vents Center" },

    -- Atlantis Extra
    ["Poseidon Rod"]         = { pos = Vector3.new(-4319.76, -603.71, 1716.2), price = 450000,   island = "Atlantis",             npc = "Poseidon Temple" },
    ["Zeus Rod"]             = { pos = Vector3.new(-4319.76, -603.71, 1716.2), price = 500000,   island = "Atlantis",             npc = "Zeus Trial Room" },

    -- Ancient Archives Extra
    ["Lucid Rod"]            = { pos = Vector3.new(-3163.59, -753.32, 1860.06), price = 80000,   island = "Ancient Archives",     npc = "Crafting Altar" },

    -- Sunken & Deep
    ["Sunken Rod"]           = { pos = Vector3.new(-2500.0, -280.0, 1500.0),  price = 0,         island = "Sunken Ship",          npc = "Treasure Chest" },
    ["Rod of the Depths"]    = { pos = Vector3.new(732.13, -3363.06, -1628.91), price = 750000,  island = "Challenger's Deep",    npc = "Depths Serpent" },
    ["Challenger's Rod"]     = { pos = Vector3.new(732.13, -3363.06, -1628.91), price = 2500000, island = "Challenger's Deep",   npc = "Depths Merchant" },
}

-- Simple backwards-compatibility mapping of positions
local ROD_LOCATIONS = {}
for rName, data in pairs(ROD_DATA) do
    ROD_LOCATIONS[rName] = data.pos
end

local rodNames = {}
local success, rodsModule = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("rods"))
end)
if success and rodsModule then
    local rodsTable = rodsModule.Rods or rodsModule
    if typeof(rodsTable) == "table" then
        for rName in pairs(rodsTable) do
            table.insert(rodNames, rName)
        end
    end
end
-- Merge all rods from our database to ensure none are missing
for rName in pairs(ROD_DATA) do
    if not table.find(rodNames, rName) then
        table.insert(rodNames, rName)
    end
end
table.sort(rodNames)

local function getPlayerMoney()
    local ok, val = pcall(function()
        local cc = require(ReplicatedStorage.client.legacyControllers.CurrencyController)
        return cc:Get()
    end)
    if ok and typeof(val) == "number" then return val end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            if child:IsA("ValueBase") and (child.Name == "C$" or child.Name:lower():find("coin") or child.Name:lower():find("money")) then
                return tonumber(child.Value) or 0
            end
        end
    end
    return -1
end

local function playerOwnsRod(rodName)
    if not rodName then return false end
    local cleanName = rodName:gsub("%s*Rod%s*$", ""):lower()
    local rodLower = rodName:lower()

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            local iLower = item.Name:lower()
            if iLower == rodLower or iLower:find(cleanName, 1, true) then
                return true
            end
        end
    end
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                local iLower = item.Name:lower()
                if iLower == rodLower or iLower:find(cleanName, 1, true) then
                    return true
                end
            end
        end
    end

    local ok, dc = pcall(function()
        return require(ReplicatedStorage.client.legacyControllers.DataController)
    end)
    if ok and dc and dc.InventoryReplicator then
        pcall(function()
            local inv = dc.InventoryReplicator:TryIndex({ "Inventory" })
            if typeof(inv) == "table" then
                for _, v in pairs(inv) do
                    if v and v.name and (v.name:lower() == rodLower or v.name:lower():find(cleanName, 1, true)) then
                        return true
                    end
                end
            end
        end)
    end

    return false
end

local function findRodPromptInWorkspace(rodName)
    if not rodName then return nil, nil end
    local lower = rodName:lower()
    local clean = rodName:gsub("%s*Rod%s*$", ""):lower()

    local searchRoots = {
        workspace:FindFirstChild("world") and workspace.world:FindFirstChild("interactables"),
        workspace:FindFirstChild("world"),
        workspace
    }

    for _, root in ipairs(searchRoots) do
        if root then
            local direct = root:FindFirstChild(rodName) or root:FindFirstChild(clean)
            if direct then
                local p = direct:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = direct:IsA("BasePart") and direct or direct:FindFirstChildWhichIsA("BasePart", true) or (p and p.Parent)
                if part then return part, p end
            end

            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local pText = (obj.Parent and obj.Parent.Name:lower()) or ""
                    local oText = (obj.ObjectText and obj.ObjectText:lower()) or ""
                    if pText:find(lower, 1, true) or oText:find(lower, 1, true) or pText:find(clean, 1, true) or oText:find(clean, 1, true) then
                        local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                        return part, obj
                    end
                end
            end
        end
    end
    return nil, nil
end

local function dismissPromptGui()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local over = playerGui and playerGui:FindFirstChild("over")
        if over then
            local pGui = over:FindFirstChild("prompt") or over:FindFirstChild("rodprompt")
            if pGui then
                local deny = pGui:FindFirstChild("deny")
                if firesignal and deny and deny:FindFirstChild("Activated") then
                    pcall(function() firesignal(deny.Activated) end)
                end
                pGui:Destroy()
            end
        end

        local Lighting = game:GetService("Lighting")
        local uiblur = Lighting:FindFirstChild("uiblur")
        local uicc = Lighting:FindFirstChild("uicc")
        if uiblur then uiblur.Size = 0 end
        if uicc then
            uicc.Brightness = 0
            uicc.Saturation = 0
            uicc.TintColor = Color3.fromRGB(255, 255, 255)
        end
        if workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView < 70 then
            workspace.CurrentCamera.FieldOfView = 70
        end
    end)
end

local function openRodPrompt(rodName)
    if not rodName then return end
    local promptEvent = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("prompt")
    local rData = ROD_DATA[rodName]
    local defaultPrice = rData and rData.price or 1000

    local targetPart, prompt = findRodPromptInWorkspace(rodName)
    if prompt then
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif prompt.InputHoldBegin then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    elseif firesignal and promptEvent then
        firesignal(promptEvent.OnClientEvent, rodName, defaultPrice, "Rod", nil, targetPart)
    end
end

local function buyRod(rodName)
    local events = ReplicatedStorage:FindFirstChild("events")
    local purchase = events and events:FindFirstChild("purchase")
    if purchase then
        pcall(function()
            local targetPart, _ = findRodPromptInWorkspace(rodName)
            purchase:FireServer(rodName, "Rod", targetPart, 1)
        end)
    end
end

local function buyRodTP(rodName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "Character not found" end
    local originalCF = hrp.CFrame

    if playerOwnsRod(rodName) then
        return false, "You already own " .. tostring(rodName)
    end

    local rData = ROD_DATA[rodName]
    local targetPos = rData and rData.pos or ROD_LOCATIONS[rodName]

    if not targetPos then
        local foundPart, _ = findRodPromptInWorkspace(rodName)
        if foundPart then
            targetPos = foundPart:IsA("BasePart") and foundPart.Position or foundPart:GetPivot().Position
        end
    end

    if not targetPos then
        -- Fallback: coba direct purchase jika lokasi belum diketahui
        buyRod(rodName)
        return false, "No location found for " .. tostring(rodName)
    end

    -- 1. Stream & Teleport ke lokasi stand
    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(targetPos)
    end)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    char:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
    task.wait(0.2)
    hrp.Anchored = true

    -- 2. Tunggu chunk dan interactable termuat
    local targetPart, prompt = nil, nil
    local waitTime = 0
    while waitTime < 3.5 do
        task.wait(0.15)
        waitTime = waitTime + 0.15
        targetPart, prompt = findRodPromptInWorkspace(rodName)
        if targetPart or prompt then break end
    end

    -- Jika part spesifik ditemukan, teleport tepat di depannya
    if targetPart then
        local realPos = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
        char:PivotTo(CFrame.lookAt(realPos + Vector3.new(0, 1.5, 3), realPos))
        task.wait(0.2)
    end

    -- 3. Trigger ProximityPrompt & Dialog Konfirmasi
    local mBefore = getPlayerMoney()
    if prompt then
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif prompt.InputHoldBegin then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end

        -- Tunggu rodprompt GUI muncul
        local pWait = 0
        while pWait < 2.0 do
            task.wait(0.1)
            pWait = pWait + 0.1
            local over = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("over")
            local rodGui = over and (over:FindFirstChild("rodprompt") or over:FindFirstChild("prompt"))
            if rodGui then
                local confirm = rodGui:FindFirstChild("confirm")
                if firesignal and confirm and confirm:FindFirstChild("Activated") then
                    pcall(function() firesignal(confirm.Activated) end)
                elseif firesignal and confirm and confirm:FindFirstChild("MouseButton1Click") then
                    pcall(function() firesignal(confirm.MouseButton1Click) end)
                end
                break
            end
        end
    end

    -- 4. Fire server remote pembelian dengan targetPart
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        local purchase = events and events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer(rodName, "Rod", targetPart, 1)
        end
    end)
    task.wait(0.5)

    local mAfter = getPlayerMoney()
    local successBuy = false
    if mBefore ~= -1 and mAfter ~= -1 and mAfter < mBefore then
        successBuy = true
    elseif playerOwnsRod(rodName) then
        successBuy = true
    end

    -- 5. Bersihkan dialog prompt & teleport kembali
    dismissPromptGui()
    hrp.Anchored = false
    task.wait(0.1)
    char:PivotTo(originalCF)

    return successBuy, successBuy and "Successfully bought " .. rodName or "Purchase attempted for " .. rodName
end

local function startAutoBuyAllLoop()
    task.spawn(function()
        while _G.Config and _G.Config.AutoBuyAllRods do
            pcall(function()
                for _, rName in ipairs(rodNames) do
                    if not (_G.Config and _G.Config.AutoBuyAllRods) then break end
                    if not playerOwnsRod(rName) then
                        buyRodTP(rName)
                        task.wait(1.5)
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

return {
    BuyRod = buyRod,
    BuyRodTP = buyRodTP,
    OpenPrompt = openRodPrompt,
    StartLoop = startAutoBuyAllLoop,
    GetRodList = function() return rodNames end,
    GetRodData = function(name) return ROD_DATA[name] end,
    PlayerOwnsRod = playerOwnsRod,
    ROD_DATA = ROD_DATA,
    ROD_LOCATIONS = ROD_LOCATIONS,
}