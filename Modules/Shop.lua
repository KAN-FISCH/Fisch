local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
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
local function Init(ShopBait, ShopItem, ShopRod, Merlin)
    local purchase = ReplicatedStorage:WaitForChild("events"):WaitForChild("purchase")
    local fire = purchase.FireServer
    local selectedBait = nil
    local baitBuyAmount = 1

    local KNOWN_ITEM_LOCATIONS = {
        -- Bait Crates & Crates
        ["Bait Crate"]              = Vector3.new(315.0, 135.0, 335.0),
        ["Quality Bait Crate"]      = Vector3.new(-185.0, 134.0, 1940.0), -- Terrapin Island stairs
        ["Common Crate"]            = Vector3.new(384.5, 135.5, 337.5),
        ["Carbon Crate"]            = Vector3.new(384.5, 135.5, 337.5),
        ["Tropical Bait Crate"]     = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Island docks
        ["Coral Geode"]             = Vector3.new(-185.0, 134.0, 1940.0), -- Terrapin Island
        ["Volcanic Geode"]          = Vector3.new(-1930.0, 165.0, 310.0), -- Roslit Volcano
        ["Festive Bait Crate"]      = Vector3.new(2625.0, 135.0, 2370.0), -- Snowcap Island
        ["Bloop Cosmetic Crate"]    = Vector3.new(384.5, 135.5, 337.5),

        -- Crab Cages
        ["Crab Cage"]               = Vector3.new(465.0, 150.0, 235.0), -- Moosewood Merchant Shop
        ["Reinforced Crab Cage"]    = Vector3.new(-1480.0, 132.0, 715.0), -- Roslit Bay

        -- Shop Items & Gear (Moosewood Pierre / Merchant)
        ["GPS"]                     = Vector3.new(446.0, 150.0, 230.0), -- Moosewood chair near pond
        ["Fish Radar"]              = Vector3.new(387.0, 133.0, 258.0), -- Moosewood Pierre
        ["Basic Diving Gear"]       = Vector3.new(387.0, 133.0, 258.0), -- Moosewood Pierre
        ["Flippers"]                = Vector3.new(387.0, 133.0, 258.0), -- Moosewood Pierre
        ["Glider"]                  = Vector3.new(387.0, 133.0, 258.0), -- Moosewood Pierre
        ["Firework"]                = Vector3.new(387.0, 133.0, 258.0), -- Moosewood Pierre
        ["Fish Barrel"]             = Vector3.new(465.0, 150.0, 235.0), -- Moosewood
        ["Carrot"]                  = Vector3.new(266.0, 147.0, -146.0), -- Carrot Garden

        -- Advanced Gear & Deep Items
        ["Advanced Glider"]         = Vector3.new(19939.0, 1142.0, 5544.0), -- Northern Expedition (Glacial Grotto)
        ["Advanced Diving Gear"]    = Vector3.new(-790.2, 130.0, -3103.0), -- Buoy behind Statue of Sovereignty
        ["Super Flippers"]          = Vector3.new(-1650.0, -215.0, -2850.0), -- The Desolate Deep
        ["Tidebreaker"]             = Vector3.new(-1650.0, -215.0, -2850.0), -- The Desolate Deep
        ["Conception Conch"]        = Vector3.new(-105.0, -515.0, 1070.0), -- Vertigo
        ["The Depths Key"]          = Vector3.new(-105.0, -515.0, 1070.0), -- Vertigo
        ["Enchant Relic"]           = Vector3.new(-929.0, 224.0, -996.0), -- Merlin
        ["Exalted Relic"]           = Vector3.new(1310.5, -799.4, -82.7), -- Keepers Altar
        ["Cosmic Relic"]            = Vector3.new(1310.5, -799.4, -82.7), -- Keepers Altar

        -- Totems (Weather & Events)
        ["Sundial Totem"]           = Vector3.new(-1215.0, 195.3, -1041.0), -- Sunstone Island cave
        ["Clearcast Totem"]         = Vector3.new(701.0, 250.0, 305.0), -- Moosewood
        ["Tempest Totem"]           = Vector3.new(20.0, 130.0, 1860.0), -- Terrapin Island underwater cave
        ["Windset Totem"]           = Vector3.new(2850.0, 180.0, 2700.0), -- Snowcap Cave
        ["Smokescreen Totem"]       = Vector3.new(2791.0, 140.0, -623.0), -- Mushgrove Swamp
        ["Meteor Totem"]            = Vector3.new(-1944.0, 275.0, 230.0), -- Roslit Volcano
        ["Aurora Totem"]            = Vector3.new(-1810.0, -135.0, -3280.0), -- Brine Pool / Desolate Deep
        ["Eclipse Totem"]           = Vector3.new(5967.0, 274.0, 839.0), -- Ancient Isle hidden cave
        ["Blizzard Totem"]          = Vector3.new(20147.0, 743.0, 5805.0), -- Northern Expedition Camp 4
        ["Avalanche Totem"]         = Vector3.new(2710.0, 140.0, 2480.0), -- Snowcap Cave
        ["Starfall Totem"]          = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver
        ["Shiny Totem"]             = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver
        ["Sparkling Totem"]         = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver
        ["Kraken Hunt Totem"]       = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver
        ["Megalodon Hunt Totem"]    = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver
        ["Scylla Hunt Totem"]       = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Totem Carver

        -- Rods (All Fisch Locations)
        ["Flimsy Rod"]              = Vector3.new(464.1, 150.5, 230.5), -- Moosewood (Marc / Dock)
        ["Training Rod"]            = Vector3.new(465.0, 150.0, 235.0), -- Moosewood Merchant
        ["Plastic Rod"]             = Vector3.new(454.2, 150.5, 207.1), -- Moosewood
        ["Carbon Rod"]              = Vector3.new(450.5, 150.5, 214.6), -- Moosewood
        ["Fast Rod"]                = Vector3.new(458.0, 150.5, 218.0), -- Moosewood
        ["Lucky Rod"]               = Vector3.new(446.8, 150.5, 222.0), -- Moosewood
        ["Long Rod"]                = Vector3.new(480.0, 150.0, 250.0), -- Moosewood hill tent
        ["Mythical Rod"]            = Vector3.new(389.5, 134.2, 305.8), -- Moosewood Merchant
        ["Midas Rod"]               = Vector3.new(389.5, 134.2, 305.8), -- Moosewood Merchant
        ["Steady Rod"]              = Vector3.new(-1480.0, 132.0, 715.0), -- Roslit Bay (Alfie)
        ["Fortune Rod"]             = Vector3.new(-1508.0, 141.0, 750.0), -- Roslit Bay (Alfie)
        ["Rapid Rod"]               = Vector3.new(-1475.0, 132.0, 720.0), -- Roslit Bay (Alfie)
        ["Magma Rod"]               = Vector3.new(-1930.0, 165.0, 310.0), -- Roslit Volcano
        ["Phoenix Rod"]             = Vector3.new(-1930.0, 165.0, 310.0), -- Roslit Volcano
        ["Shady Rod"]               = Vector3.new(-1067.4, 130.8, -1163.3), -- Roslit Hamlet
        ["Magnet Rod"]              = Vector3.new(-185.0, 134.0, 1940.0), -- Terrapin Island
        ["Wildflower Rod"]          = Vector3.new(-185.0, 134.0, 1940.0), -- Terrapin Island
        ["The Lost Rod"]            = Vector3.new(-935.0, 132.0, -1125.0), -- Sunstone Island
        ["Great Rod of Oscar"]      = Vector3.new(2625.0, 135.0, 2370.0), -- Snowcap Island Spike
        ["Scurvy Rod"]              = Vector3.new(-2830.0, 214.0, 1510.0), -- Forsaken Shores
        ["Reinforced Rod"]          = Vector3.new(-1650.0, -215.0, -2850.0), -- The Desolate Deep
        ["Trident Rod"]             = Vector3.new(-1485.0, -225.0, -2200.0), -- Desolate Deep
        ["Brick Rod"]               = Vector3.new(-1650.0, -215.0, -2850.0), -- The Desolate Deep / Elevator
        ["Nocturnal Rod"]           = Vector3.new(-115.0, -515.0, 1070.0), -- Vertigo
        ["Aurora Rod"]              = Vector3.new(-115.0, -515.0, 1070.0), -- Vertigo
        ["Haunted Rod"]             = Vector3.new(-115.0, -515.0, 1070.0), -- Vertigo
        ["Destiny Rod"]             = Vector3.new(985.2, 142.5, -1220.0), -- The Arch (Cery)
        ["Kings Rod"]               = Vector3.new(1296.06, -802.01, -299.01), -- Keepers Altar
        ["Depthseeker Rod"]         = Vector3.new(-4319.76, -603.71, 1716.2), -- Atlantis
        ["Champions Rod"]           = Vector3.new(-4350.0, -603.71, 1730.0), -- Atlantis
        ["Stone Rod"]               = Vector3.new(5965.37, 258.97, 223.25), -- Ancient Isle
        ["Relic Rod"]               = Vector3.new(5740.0, 135.0, 420.0), -- Archaeological Site
        ["Precision Rod"]           = Vector3.new(-3163.59, -753.32, 1860.06), -- Ancient Archives
        ["Wisdom Rod"]              = Vector3.new(-3163.59, -753.32, 1860.06), -- Ancient Archives
        ["Voyager Rod"]             = Vector3.new(-3163.59, -753.32, 1860.06), -- Ancient Archives
        ["Fungal Rod"]              = Vector3.new(2791.0, 140.0, -623.0), -- Mushgrove Swamp
        ["Heaven's Rod"]            = Vector3.new(19980.0, 916.0, 5384.0), -- Northern Summit Vault
        ["Avalanche Rod"]           = Vector3.new(20147.0, 743.0, 5805.0), -- Northern Expedition
        ["Rod of the Zenith"]       = Vector3.new(-13810.0, -11541.0, 106.92), -- Abyssal Zenith
        ["Ruinous Oath"]            = Vector3.new(-998.65, -335.17, -4886.02), -- Crimson Cavern
        ["Sunken Rod"]              = Vector3.new(-2500.0, -280.0, 1500.0), -- Sunken Ship
        ["Rod of the Depths"]       = Vector3.new(732.13, -3363.06, -1628.91), -- Challenger's Deep
        ["Challenger's Rod"]        = Vector3.new(732.13, -3363.06, -1628.91), -- Challenger's Deep
        ["Firefly Rod"]             = Vector3.new(690.0, 135.0, -1693.0), -- Castaway Cliffs
        ["Daybreaker Rod"]          = Vector3.new(-5160.0, 137.99, -1452.02), -- Ashbrook Town
        ["Volcanic Rod"]            = Vector3.new(-3136.28, -2010.89, 4056.85), -- Volcanic Vents
        ["Poseidon Rod"]            = Vector3.new(-4319.76, -603.71, 1716.2), -- Atlantis
        ["Zeus Rod"]                = Vector3.new(-4319.76, -603.71, 1716.2), -- Atlantis
        ["Lucid Rod"]               = Vector3.new(-3163.59, -753.32, 1860.06), -- Ancient Archives
        ["Frog Rod"]                = Vector3.new(2791.0, 140.0, -623.0), -- Mushgrove Swamp
    }

    local function getItemLocation(itemName)
        if not itemName then return nil end
        if KNOWN_ITEM_LOCATIONS[itemName] then
            return KNOWN_ITEM_LOCATIONS[itemName]
        end
        local lower = itemName:lower()
        for name, pos in pairs(KNOWN_ITEM_LOCATIONS) do
            if name:lower() == lower or name:lower():find(lower, 1, true) or lower:find(name:lower(), 1, true) then
                return pos
            end
        end
        if lower:find("crate") or lower:find("bait") then
            return Vector3.new(384.5, 135.5, 337.5)
        end
        return Vector3.new(387.0, 133.0, 258.0)
    end

    local function safeTeleport(char, targetCF)
        if not char or not targetCF then return end
        pcall(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
                char:PivotTo(targetCF)
                task.wait(0.05)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end

    local function findItemPrompt(itemName)
        if not itemName then return nil, nil end
        local world = workspace:FindFirstChild("world")
        local interactables = world and world:FindFirstChild("interactables")
        if interactables then
            local direct = interactables:FindFirstChild(itemName)
            if direct then
                local p = direct:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = direct:IsA("BasePart") and direct or direct:FindFirstChildWhichIsA("BasePart", true) or (p and p.Parent)
                if p and part then return part, p end
            end
            for _, obj in ipairs(interactables:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local pName = obj.Parent and obj.Parent.Name:lower() or ""
                    local oText = obj.ObjectText and obj.ObjectText:lower() or ""
                    local targetLower = itemName:lower()
                    if pName:find(targetLower) or oText:find(targetLower) then
                        local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                        return part, obj
                    end
                end
            end
        end
        if world then
            for _, obj in ipairs(world:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local pName = obj.Parent and obj.Parent.Name:lower() or ""
                    local oText = obj.ObjectText and obj.ObjectText:lower() or ""
                    local targetLower = itemName:lower()
                    if pName:find(targetLower) or oText:find(targetLower) then
                        local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                        return part, obj
                    end
                end
            end
        end
        return nil, nil
    end

    local function triggerPromptSafe(prompt)
        if not prompt then return end
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif prompt.InputHoldBegin then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end

    local function isPromptGuiOpen()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end

        -- 1. Cek di PlayerGui.hud.safezone (tempat umum UI prompt Fisch)
        local hud = playerGui:FindFirstChild("hud")
        if hud and hud:FindFirstChild("safezone") then
            local sz = hud.safezone
            for _, name in ipairs({"prompt", "Prompt", "dialogue", "Dialogue", "merchant", "Merchant", "confirm", "Confirm", "purchase", "Purchase", "buying"}) do
                local el = sz:FindFirstChild(name)
                if el and (el:IsA("GuiObject") and el.Visible) then
                    return true
                end
            end
        end

        -- 2. Cek ScreenGui atau frame langsung di PlayerGui
        for _, name in ipairs({"prompt", "Prompt", "PurchasePrompt", "purchase", "dialogue", "Dialogue", "Merchant", "ItemPrompt", "Confirm"}) do
            local g = playerGui:FindFirstChild(name)
            if g then
                if g:IsA("ScreenGui") and g.Enabled then
                    return true
                elseif g:IsA("GuiObject") and g.Visible then
                    return true
                end
            end
        end

        -- 3. Cek frame prompt/dialogue yang sedang visible di ScreenGui manapun
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "ShielD_UI" and not gui.Name:find("Notification") then
                local found = gui:FindFirstChild("prompt", true) or gui:FindFirstChild("Prompt", true) or gui:FindFirstChild("dialogue", true) or gui:FindFirstChild("Dialogue", true)
                if found and found:IsA("GuiObject") and found.Visible then
                    return true
                end
            end
        end

        return false
    end

    local function openItemPrompt(itemName, category, defaultPrice)
        category = category or "Item"
        defaultPrice = defaultPrice or 100
        local promptEvent = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("prompt")
        if not promptEvent then return end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetPart, prompt = findItemPrompt(itemName)

        if not targetPart then
            local targetPos = getItemLocation(itemName)
            if targetPos and char and hrp then
                pcall(function() LocalPlayer:RequestStreamAroundAsync(targetPos) end)
                safeTeleport(char, CFrame.new(targetPos + Vector3.new(0, 2.5, 0)))
                task.wait(0.5)
                targetPart, prompt = findItemPrompt(itemName)
            end
        end

        local price = defaultPrice
        if itemName == "Bait Crate" then price = 75 end

        if prompt then
            triggerPromptSafe(prompt)
        elseif firesignal and promptEvent then
            firesignal(promptEvent.OnClientEvent,
                itemName,
                price,
                category,
                nil,
                targetPart
            )
        end
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

            local TweenService = game:GetService("TweenService")
            local Lighting = game:GetService("Lighting")
            local cam = workspace.CurrentCamera
            local uiblur = Lighting:FindFirstChild("uiblur")
            local uicc = Lighting:FindFirstChild("uicc")

            if playerGui and playerGui:FindFirstChild("hud") then playerGui.hud.Enabled = true end
            if playerGui and playerGui:FindFirstChild("backpack") then playerGui.backpack.Enabled = true end

            if cam then
                TweenService:Create(cam, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { FieldOfView = 70 }):Play()
            end
            if uiblur then
                TweenService:Create(uiblur, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { Size = 0 }):Play()
                uiblur.Size = 0
            end
            if uicc then
                TweenService:Create(uicc, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Brightness = 0,
                    Saturation = 0,
                    TintColor = Color3.fromRGB(255, 255, 255)
                }):Play()
                uicc.Brightness = 0
                uicc.Saturation = 0
                uicc.TintColor = Color3.fromRGB(255, 255, 255)
            end
        end)

        task.delay(0.25, function()
            pcall(function()
                local Lighting = game:GetService("Lighting")
                local uiblur = Lighting:FindFirstChild("uiblur")
                if uiblur and uiblur.Size > 0 then
                    uiblur.Size = 0
                end
                local uicc = Lighting:FindFirstChild("uicc")
                if uicc then
                    uicc.Brightness = 0
                    uicc.Saturation = 0
                    uicc.TintColor = Color3.fromRGB(255, 255, 255)
                end
                if workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView < 70 then
                    workspace.CurrentCamera.FieldOfView = 70
                end
            end)
        end)
    end

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

    local function smartPurchaseItem(itemName, category, amount)
        category = category or "Item"
        amount = tonumber(amount) or 1
        if amount <= 0 then amount = 1 end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local over = playerGui and playerGui:FindFirstChild("over")
        local existingPrompt = over and (over:FindFirstChild("prompt") or over:FindFirstChild("rodprompt"))

        -- 1. JIKA PROMPT SUDAH TERBUKA: LANGSUNG BUY -> BUY -> BUY
        if existingPrompt then
            local rem = amount
            local failCount = 0

            while rem > 0 do
                local buyBatch = math.min(rem, 50)
                local m0 = getPlayerMoney()

                pcall(function()
                    purchase:FireServer(itemName, category, nil, buyBatch)
                end)
                task.wait(0.25)

                local m1 = getPlayerMoney()
                if m0 ~= -1 and m1 ~= -1 then
                    if m1 < m0 then
                        rem = rem - buyBatch
                        failCount = 0
                    else
                        failCount = failCount + 1
                        if failCount >= 2 then break end
                    end
                else
                    rem = rem - buyBatch
                end
            end

            task.wait(0.1)
            dismissPromptGui()
            return
        end

        -- 2. COBA DIRECT PURCHASE DULU TANPA TP & TANPA PROMPT
        local mBefore = getPlayerMoney()
        local testBatch = math.min(amount, 50)
        pcall(function()
            purchase:FireServer(itemName, category, nil, testBatch)
        end)
        task.wait(0.3)

        local mAfter = getPlayerMoney()
        -- Jika uang berkurang, berarti direct purchase berhasil!
        if mBefore ~= -1 and mAfter ~= -1 and mAfter < mBefore then
            local rem = amount - testBatch
            local failCount = 0

            while rem > 0 do
                local buyBatch = math.min(rem, 50)
                local m0 = getPlayerMoney()

                pcall(function()
                    purchase:FireServer(itemName, category, nil, buyBatch)
                end)
                task.wait(0.25)

                local m1 = getPlayerMoney()
                if m0 ~= -1 and m1 ~= -1 then
                    if m1 < m0 then
                        rem = rem - buyBatch
                        failCount = 0
                    else
                        failCount = failCount + 1
                        if failCount >= 2 then break end
                    end
                else
                    rem = rem - buyBatch
                end
            end

            dismissPromptGui()
            return
        end

        -- 3. JIKA GAGAL BELI LANGSUNG:
        -- ALUR: gagal beli -> tp -> open prompt (sekali aja) -> buy -> buy -> buy kecuali gabisa beli lagi
        local targetPart, prompt = findItemPrompt(itemName)
        local targetPos = nil

        if targetPart then
            targetPos = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
        else
            targetPos = getItemLocation(itemName)
        end

        if targetPos then
            local dist = (hrp.Position - targetPos).Magnitude

            if dist > 15 then
                pcall(function()
                    LocalPlayer:RequestStreamAroundAsync(targetPos)
                end)

                safeTeleport(char, CFrame.new(targetPos + Vector3.new(0, 2.5, 0)))
                hrp.Anchored = true

                local loadedTime = 0
                while loadedTime < 4.0 do
                    task.wait(0.15)
                    loadedTime = loadedTime + 0.15
                    targetPart, prompt = findItemPrompt(itemName)
                    if prompt and targetPart then break end
                end

                if targetPart then
                    local realPos = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
                    safeTeleport(char, CFrame.new(realPos + Vector3.new(0, 2.5, 0)))
                    task.wait(0.2)
                end
            end
        end

        -- BUKA PROMPT SEKALI AJA (Official Prompt Dialog Fisch)
        openItemPrompt(itemName, category, 75)

        -- Tunggu prompt muncul di over (maks 2.5 detik)
        local waitPrompt = 0
        while waitPrompt < 2.5 do
            task.wait(0.1)
            waitPrompt = waitPrompt + 0.1
            local overNow = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("over")
            if overNow and (overNow:FindFirstChild("prompt") or overNow:FindFirstChild("rodprompt")) then
                break
            end
        end
        task.wait(0.2)

        -- EKSEKUSI PEMBELIAN BERULANG (buy -> buy -> buy) KECUALI GABISA BELI LAGI
        local rem = amount
        local failCount = 0

        while rem > 0 do
            local buyBatch = math.min(rem, 50)
            local m0 = getPlayerMoney()

            pcall(function()
                purchase:FireServer(itemName, category, nil, buyBatch)
            end)
            task.wait(0.25)

            local m1 = getPlayerMoney()
            if m0 ~= -1 and m1 ~= -1 then
                if m1 < m0 then
                    rem = rem - buyBatch
                    failCount = 0
                else
                    failCount = failCount + 1
                    if failCount >= 2 then
                        -- Gak bisa beli lagi (uang habis / limit)
                        break
                    end
                end
            else
                rem = rem - buyBatch
            end
        end

        -- TUTUP PROMPT & BERSIHKAN BLUR SECARA TUNTAS
        dismissPromptGui()

        task.wait(0.2)
        local curHrp = char and char:FindFirstChild("HumanoidRootPart")
        if curHrp then
            curHrp.Anchored = false
        elseif hrp then
            hrp.Anchored = false
        end
    end

    ShopBait:AddParagraph({
        Title = "Purchase System",
        Content = "• Max 50 per transaction\n• Auto-loops for larger amounts\n• Auto ProximityPrompt activation\n• 0.25s delay between purchases"
    })
    ShopBait:AddDropdown({
        Title = "Select Bait",
        Content = "Choose a Bait to Purchase",
        Multi = false,
        Options = {
            "Common Crate",
            "Tropical Bait Crate",
            "Carbon Crate",
            "Bait Crate",
            "Quality Bait Crate",
            "Coral Geode",
            "Volcanic Geode",
            "Festive Bait Crate",
            "Ancient Crate",
            "Fish Head Crate"
        },
        Callback = function(v)
            selectedBait = v
        end
    })
    ShopBait:AddInput({
        Title = "Buy Amount",
        Content = "Amount To Buy Bait",
        Value = "1",
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                baitBuyAmount = amount
            end
        end
    })
    ShopBait:AddButton({
        Title = "Buy Bait Crate",
        Content = "Purchase selected crate",
        Callback = function()
            if not selectedBait then return end
            task.spawn(function()
                smartPurchaseItem(selectedBait, "Fish", baitBuyAmount)
            end)
        end
    })
    ShopBait:AddButton({
        Title = "Open Prompt (Dialog)",
        Content = "Membuka dialog prompt resmi game (jangan diilangin)",
        Callback = function()
            if not selectedBait then return end
            openItemPrompt(selectedBait, "Fish", 75)
        end
    })
    ShopBait:AddSeperator({
        Title = "Auto Buy Bait (NPC)"
    })
    ShopBait:AddToggle({
        Title = "Enable Auto Buy Bait",
        Default = _G.Config.AutoBuyBait or false,
        Callback = function(state)
            _G.Config.AutoBuyBait = state
        end
    })
    ShopBait:AddToggle({
        Title = "Auto Open Bait Crate",
        Default = _G.Config.AutoOpenBaitCrate ~= false,
        Callback = function(state)
            _G.Config.AutoOpenBaitCrate = state
        end
    })
    ShopBait:AddToggle({
        Title = "Auto Equip Purchased Bait",
        Default = _G.Config.AutoEquipBait or false,
        Callback = function(state)
            _G.Config.AutoEquipBait = state
        end
    })
    local BAIT_LIST = {
        "Bait Crate", "Quality Bait Crate", "Tropical Bait Crate", "Festive Bait Crate",
        "Common Crate", "Carbon Crate", "Coral Geode", "Volcanic Geode",
        "Worm", "Cricket", "Leech", "Minnow", "Firefly",
        "Shrimp", "Squid", "Sand Dollar", "Pearl",
        "Phantom Worm", "Enchanted Bait", "Seaside Sardine",
        "Truffle Worm", "Instant Catch Bait", "Deep Coral",
        "Magnet Bait", "Rapid Catch", "Night Shrimp", "Fish Head",
        "Super Flakes", "Golden Hook", "Maggot", "Shark Bait"
    }
    ShopBait:AddDropdown({
        Title = "Auto Buy Bait Type",
        Content = "Select crate or individual bait to buy automatically",
        Options = BAIT_LIST,
        Default = _G.Config.SelectedBait or "Bait Crate",
        Callback = function(v)
            _G.Config.SelectedBait = v
        end
    })
    ShopBait:AddInput({
        Title = "Auto Buy Quantity",
        Content = "Quantity of bait to purchase automatically",
        Value = tostring(_G.Config.BuyBaitAmount or 1),
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                _G.Config.BuyBaitAmount = amount
            end
        end
    })
    local function getCategoryForItem(itemName)
        if not itemName then return "Item" end
        if itemName:find("Crate") or itemName:find("Geode") then
            return "Fish"
        elseif itemName:find("Rod") then
            return "Rod"
        end
        return "Item"
    end

    local itemNames = {}
    local successItems, itemsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("items"))
    end)
    if successItems and typeof(itemsModule) == "table" then
        local raw = itemsModule.Items or itemsModule.items or itemsModule
        if typeof(raw) == "table" then
            for itemName, data in pairs(raw) do
                if typeof(itemName) == "string" and not itemName:find("Template") and not itemName:find("__") then
                    table.insert(itemNames, itemName)
                elseif typeof(data) == "table" and data.Name then
                    table.insert(itemNames, data.Name)
                end
            end
        end
    end

    local defaultItems = {
        "Crab Cage",
        "Reinforced Crab Cage",
        "GPS",
        "Fish Radar",
        "Glider",
        "Advanced Glider",
        "Flippers",
        "Super Flippers",
        "Tidebreaker",
        "Basic Diving Gear",
        "Advanced Diving Gear",
        "Conception Conch",
        "The Depths Key",
        "Enchant Relic",
        "Exalted Relic",
        "Cosmic Relic",
        "Clearcast Totem",
        "Sundial Totem",
        "Aurora Totem",
        "Windset Totem",
        "Smokescreen Totem",
        "Tempest Totem",
        "Eclipse Totem",
        "Meteor Totem",
        "Avalanche Totem",
        "Blizzard Totem",
        "Starfall Totem",
        "Shiny Totem",
        "Sparkling Totem",
        "Kraken Hunt Totem",
        "Megalodon Hunt Totem",
        "Scylla Hunt Totem",
        "Firework",
        "Fish Barrel",
        "Carrot",
        "Common Crate",
        "Carbon Crate",
        "Bait Crate",
        "Quality Bait Crate",
        "Tropical Bait Crate",
        "Coral Geode",
        "Volcanic Geode",
        "Festive Bait Crate",
        "Bloop Cosmetic Crate",
    }
    for _, name in ipairs(defaultItems) do
        if not table.find(itemNames, name) then
            table.insert(itemNames, name)
        end
    end
    table.sort(itemNames)

    local PurchaseQuantity = 1
    local ItemDropdown = "Crab Cage"
    ShopItem:AddInput({
        Title = "Purchase Quantity",
        Content = "Amount To Buy Item",
        Value = "1",
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                PurchaseQuantity = num
            end
        end
    })
    ShopItem:AddDropdown({
        Title = "Select an Item",
        Content = "Choose an item from the shop to purchase.",
        Options = itemNames,
        Multi = false,
        Default = "Crab Cage",
        Callback = function(value)
            ItemDropdown = value
        end
    })
    ShopItem:AddButton({
        Title = "Buy Selected Item",
        Content = "Purchase selected items with prompt bypass",
        Callback = function()
            if not ItemDropdown then return end
            task.spawn(function()
                local item = ItemDropdown
                local category = getCategoryForItem(item)
                smartPurchaseItem(item, category, PurchaseQuantity)
            end)
        end
    })
    ShopItem:AddButton({
        Title = "Open Prompt (Selected Item)",
        Content = "Membuka dialog prompt resmi game (jangan diilangin)",
        Callback = function()
            if not ItemDropdown then return end
            local category = getCategoryForItem(ItemDropdown)
            openItemPrompt(ItemDropdown, category, 100)
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Selected Item",
        Content = "Automatically purchase selected item repeatedly",
        Default = _G.Config.AutoBuySelectedItem or false,
        Callback = function(state)
            _G.Config.AutoBuySelectedItem = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuySelectedItem do
                        if ItemDropdown then
                            local item = ItemDropdown
                            local category = getCategoryForItem(item)
                            smartPurchaseItem(item, category, PurchaseQuantity)
                        end
                        task.wait(2)
                    end
                end)
            end
        end
    })
    ShopItem:AddSeperator({
        Title = "Crab Cage (Smart Purchase)"
    })
    local crabCageBuyAmount = 1
    ShopItem:AddInput({
        Title = "Crab Cage Amount",
        Content = "Amount of Crab Cages to buy",
        Value = "1",
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                crabCageBuyAmount = num
            end
        end
    })
    ShopItem:AddButton({
        Title = "Buy Crab Cage",
        Content = "Purchase Crab Cage with proximity prompt bypass",
        Callback = function()
            task.spawn(function()
                smartPurchaseItem("Crab Cage", "Item", crabCageBuyAmount)
            end)
        end
    })
    ShopItem:AddButton({
        Title = "Open Prompt (Crab Cage)",
        Content = "Membuka dialog prompt resmi Crab Cage",
        Callback = function()
            openItemPrompt("Crab Cage", "Item", 45)
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Crab Cage",
        Content = "Automatically buy Crab Cages when toggled",
        Default = _G.Config.AutoBuyCrabCage or false,
        Callback = function(state)
            _G.Config.AutoBuyCrabCage = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCrabCage do
                        smartPurchaseItem("Crab Cage", "Item", crabCageBuyAmount)
                        task.wait(2)
                    end
                end)
            end
        end
    })
    ShopItem:AddSeperator({
        Title = 'Black Market',
    })
    local hud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("hud")
    local safezone = hud:WaitForChild("safezone")
    local BlackMarketGui = safezone:WaitForChild("BlackMarket")
    local ListFrame = BlackMarketGui:WaitForChild("List")
    local PurchaseRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/BlackMarket/Purchase")
    local AutoBM = {
        Enabled = false,
        TargetItem = nil,
        Items = {},
        ItemIDs = {},
        DropdownUI = nil
    }
    local function RefreshItemList()
        AutoBM.Items = {}
        AutoBM.ItemIDs = {}
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("ItemPreview") then
                local titleLabel = child.ItemPreview:FindFirstChild("ItemHeader")
                    and child.ItemPreview.ItemHeader:FindFirstChild("ItemTitle")
                if titleLabel then
                    local displayName = titleLabel.Text
                    table.insert(AutoBM.Items, displayName)
                    AutoBM.ItemIDs[displayName] = child.Name
                end
            end
        end
        if #AutoBM.Items == 0 then
            table.insert(AutoBM.Items, "No items found")
        end
        if AutoBM.DropdownUI then
            pcall(function()
                if AutoBM.DropdownUI.SetValues then
                    AutoBM.DropdownUI:SetValues(AutoBM.Items)
                elseif AutoBM.DropdownUI.SetOptions then
                    AutoBM.DropdownUI:SetOptions(AutoBM.Items)
                elseif AutoBM.DropdownUI.Refresh then
                    AutoBM.DropdownUI:Refresh(AutoBM.Items)
                end
            end)
        end
    end
    AutoBM.DropdownUI = ShopItem:AddDropdown({
        Title = "Select Item Black Market",
        Options = AutoBM.Items,
        Multi = false,
        Value = nil,
        Callback = function(value)
            if value and AutoBM.ItemIDs[value] then
                AutoBM.TargetItem = value
            end
        end
    })
    ShopItem:AddButton({
        Title = "Refresh Item List Black Market",
        Callback = function()
            RefreshItemList()
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Selected Item Black Market",
        Content = "Automatically buy selected item repeatedly",
        Default = false,
        Callback = function(state)
            AutoBM.Enabled = state
            if state then
                task.spawn(function()
                    while AutoBM.Enabled do
                        if AutoBM.TargetItem and AutoBM.ItemIDs[AutoBM.TargetItem] then
                            local uuid = AutoBM.ItemIDs[AutoBM.TargetItem]
                            pcall(function()
                                PurchaseRemote:FireServer(uuid)
                            end)
                            task.wait(1)
                        else
                            task.wait(0.5)
                        end
                    end
                end)
            end
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Carrot",
        Default = _G.Config.AutoBuyCarrot or false,
        Callback = function(state)
            _G.Config.AutoBuyCarrot = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCarrot do
                        pcall(function()
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(266, 147, -146)
                            end
                            task.wait(0.2)
                            local args = { buffer.fromstring("h\000\006Carrot") }
                            ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })
    local rodNames = {}
    local successRods, rodsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("rods"))
    end)
    if successRods and rodsModule then
        local rodsTable = rodsModule.Rods or rodsModule
        if typeof(rodsTable) == "table" then
            for rodName in pairs(rodsTable) do
                table.insert(rodNames, rodName)
            end
        end
    end

    local function getAutoMod()
        return (_G.__Modules and _G.__Modules["AutoBuyRod"]) or getMod("AutoBuyRod")
    end

    local autoMod = getAutoMod()
    if autoMod and autoMod.ROD_DATA then
        for rName in pairs(autoMod.ROD_DATA) do
            if not table.find(rodNames, rName) then
                table.insert(rodNames, rName)
            end
        end
    end

    local ALL_ROD_DEFAULTS = {
        "Flimsy Rod", "Training Rod", "Plastic Rod", "Carbon Rod", "Fast Rod", "Lucky Rod", "Long Rod",
        "Mythical Rod", "Midas Rod", "Steady Rod", "Fortune Rod", "Rapid Rod", "Magma Rod", "Phoenix Rod",
        "Shady Rod", "Magnet Rod", "Wildflower Rod", "The Lost Rod", "Great Rod of Oscar", "Scurvy Rod",
        "Reinforced Rod", "Trident Rod", "Brick Rod", "Nocturnal Rod", "Aurora Rod", "Haunted Rod",
        "Destiny Rod", "Kings Rod", "Depthseeker Rod", "Champions Rod", "Stone Rod", "Relic Rod",
        "Precision Rod", "Wisdom Rod", "Voyager Rod", "Fungal Rod", "Frog Rod", "Heaven's Rod",
        "Avalanche Rod", "Rod of the Zenith", "Ruinous Oath", "Firefly Rod", "Daybreaker Rod",
        "Volcanic Rod", "Poseidon Rod", "Zeus Rod", "Lucid Rod", "Sunken Rod", "Rod of the Depths",
        "Challenger's Rod"
    }
    for _, rName in ipairs(ALL_ROD_DEFAULTS) do
        if not table.find(rodNames, rName) then
            table.insert(rodNames, rName)
        end
    end
    table.sort(rodNames)

    local selectedTPRod = rodNames[1] or "Carbon Rod"

    local rodInfoPara = ShopRod:AddParagraph({
        Title = "Rod Info: " .. tostring(selectedTPRod),
        Content = "Loading rod location..."
    })

    local function updateRodInfo(rName)
        if not rodInfoPara then return end
        local mod = getAutoMod()
        local rData = mod and mod.ROD_DATA and mod.ROD_DATA[rName]
        local infoText = ""
        if rData then
            infoText = string.format("📍 Lokasi: %s\n👤 Penjual / Stand: %s\n💰 Harga: %s C$", rData.island or "Unknown", rData.npc or "Display Stand", (rData.price and rData.price > 0) and tostring(rData.price) or "0 / Quest")
        elseif KNOWN_ITEM_LOCATIONS[rName] then
            local pos = KNOWN_ITEM_LOCATIONS[rName]
            infoText = string.format("📍 Lokasi: X: %d, Y: %d, Z: %d\n💰 Harga: Fisch Merchant", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
        else
            infoText = "📍 Lokasi: Scan World / ProximityPrompt\n💰 Harga: Library Fisch"
        end
        pcall(function()
            rodInfoPara:Set({ Title = "Rod Info: " .. tostring(rName), Content = infoText })
        end)
    end

    task.spawn(function()
        task.wait(0.5)
        updateRodInfo(selectedTPRod)
    end)

    ShopRod:AddDropdown({
        Title = "Select Rod (TP Method)",
        Options = rodNames,
        Multi = false,
        Default = selectedTPRod,
        Callback = function(v)
            selectedTPRod = v
            updateRodInfo(v)
        end
    })

    ShopRod:AddButton({
        Title = "Buy Selected Rod (TP Method)",
        Content = "Smart TP ke lokasi rod, bypass prompt, beli, lalu kembali otomatis",
        Callback = function()
            if not selectedTPRod then return end
            task.spawn(function()
                local mod = getAutoMod()
                if mod and mod.BuyRodTP then
                    local ok, msg = mod.BuyRodTP(selectedTPRod)
                    if Speed_Library and Speed_Library.SetNotification then
                        Speed_Library:SetNotification({
                            Title = "Buy Rod",
                            Content = msg or (ok and "Berhasil membeli " .. selectedTPRod or "Gagal membeli " .. selectedTPRod),
                            Time = 0.5,
                            Delay = 3
                        })
                    end
                else
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local targetPos = KNOWN_ITEM_LOCATIONS[selectedTPRod]
                    if hrp and targetPos then
                        local oldCF = hrp.CFrame
                        pcall(function() LocalPlayer:RequestStreamAroundAsync(targetPos) end)
                        char:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                        task.wait(1.5)
                        pcall(function() purchase:FireServer(selectedTPRod, "Rod", nil, 1) end)
                        task.wait(0.5)
                        char:PivotTo(oldCF)
                    end
                end
            end)
        end
    })

    ShopRod:AddButton({
        Title = "Open Prompt (Selected Rod)",
        Content = "Membuka dialog prompt resmi rod game (tanpa beli otomatis)",
        Callback = function()
            if not selectedTPRod then return end
            local mod = getAutoMod()
            if mod and mod.OpenPrompt then
                mod.OpenPrompt(selectedTPRod)
            else
                openItemPrompt(selectedTPRod, "Rod", 1000)
            end
        end
    })

    ShopRod:AddButton({
        Title = "Buy Selected Rod (Direct)",
        Content = "Directly purchase rod via purchase:FireServer without teleport",
        Callback = function()
            if not selectedTPRod then return end
            task.spawn(function()
                local mod = getAutoMod()
                if mod and mod.BuyRod then
                    mod.BuyRod(selectedTPRod)
                else
                    pcall(function()
                        purchase:FireServer(selectedTPRod, "Rod", nil, 1)
                    end)
                end
            end)
        end
    })

    ShopRod:AddToggle({
        Title = "Auto Buy All Rods (TP Method)",
        Content = "Automatically teleports to buy all available rods",
        Default = _G.Config.AutoBuyAllRods or false,
        Callback = function(state)
            _G.Config.AutoBuyAllRods = state
            if state then
                task.spawn(function()
                    local mod = getAutoMod()
                    if mod and mod.StartLoop then
                        mod.StartLoop()
                    end
                end)
            end
        end
    })

    ShopRod:AddToggle({
        Title = "Auto Buy All Rods (Direct Remote)",
        Content = "Buys all rods directly via purchase:FireServer without teleporting",
        Default = _G.Config.AutoBuyAllRodsDirect or false,
        Callback = function(state)
            _G.Config.AutoBuyAllRodsDirect = state
            if state then
                task.spawn(function()
                    local mod = getAutoMod()
                    for _, rodName in ipairs(rodNames) do
                        if not _G.Config.AutoBuyAllRodsDirect then break end
                        if mod and mod.BuyRod then
                            mod.BuyRod(rodName)
                        else
                            pcall(function()
                                purchase:FireServer(rodName, "Rod", nil, 1)
                            end)
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end
    })
    local function FireProximity(proximity)
        if proximity:IsA("ProximityPrompt") and proximity.Enabled then
            pcall(function()
                local camera = workspace.CurrentCamera
                if camera then
                    local targetPos = nil
                    if proximity.Parent:IsA("Attachment") then
                        targetPos = proximity.Parent.WorldPosition
                    elseif proximity.Parent:IsA("BasePart") then
                        targetPos = proximity.Parent.Position
                    end
                    if targetPos then
                        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
                        task.wait(0.1)
                    end
                end
            end)
            proximity:InputHoldBegin()
            proximity.HoldDuration = 0
            proximity:InputHoldEnd()
        end
    end
    Merlin:AddButton({
        Title = "🔍 Open Dialog & Node Tracker",
        Description = "Track Node ID & Choice when talking to Merlin/NPC",
        Callback = function()
            pcall(function()
                if readfile and isfile and isfile("ShielDTeam/NewFish5_Source/TrackDialog.lua") then
                    loadstring(readfile("ShielDTeam/NewFish5_Source/TrackDialog.lua"))()
                elseif game and game.HttpGet then
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/NewFish5_Source/TrackDialog.lua"))()
                end
            end)
        end
    })
    local dynamicMerlin = {
        relic   = { startNode = 2, startChoice = 1, buyNode = 5,  buyChoice = 1 },
        luck    = { startNode = 2, startChoice = 2, buyNode = 25, buyChoice = 1 },
        lure    = { startNode = 2, startChoice = 2, buyNode = 26, buyChoice = 1 },
        xp      = { startNode = 2, startChoice = 2, buyNode = 27, buyChoice = 1 },
        twisted = { startNode = 2, startChoice = 2, buyNode = 29, buyChoice = 1 },
        chasm   = { startNode = 2, startChoice = 3, buyNode = 3,  buyChoice = 1 },
    }
    local function parseMerlinDialogTree(npc, u18, u19)
        if not npc or not string.find(tostring(npc):lower(), "merlin") then return end
        if not u19 or type(u19.dialog) ~= "table" then return end
        local dialog = u19.dialog
        local menuNodeIdx = 2
        for nIdx, nData in ipairs(dialog) do
            if nData.choices and #nData.choices >= 2 then
                for cIdx, cData in ipairs(nData.choices) do
                    local tLower = tostring(cData.text):lower()
                    if string.find(tLower, "power") or string.find(tLower, "relic") then
                        dynamicMerlin.relic.startNode = nIdx
                        dynamicMerlin.relic.startChoice = cIdx
                        menuNodeIdx = nIdx
                    elseif string.find(tLower, "shop") then
                        dynamicMerlin.luck.startNode = nIdx
                        dynamicMerlin.luck.startChoice = cIdx
                        dynamicMerlin.lure.startNode = nIdx
                        dynamicMerlin.lure.startChoice = cIdx
                        dynamicMerlin.xp.startNode = nIdx
                        dynamicMerlin.xp.startChoice = cIdx
                    elseif string.find(tLower, "chasm") then
                        dynamicMerlin.chasm.startNode = nIdx
                        dynamicMerlin.chasm.startChoice = cIdx
                    end
                end
            end
        end
        for nIdx, nData in ipairs(dialog) do
            local textLower = tostring(nData.text or ""):lower()
            if nData.choices then
                for cIdx, cData in ipairs(nData.choices) do
                    local choiceTextLower = tostring(cData.text or ""):lower()
                    local combined = textLower .. " " .. choiceTextLower
                    if string.find(combined, "luck") then
                        dynamicMerlin.luck.buyNode = nIdx
                        dynamicMerlin.luck.buyChoice = cIdx
                    elseif string.find(combined, "lure") then
                        dynamicMerlin.lure.buyNode = nIdx
                        dynamicMerlin.lure.buyChoice = cIdx
                    elseif string.find(combined, "xp") or string.find(combined, "exp") or string.find(combined, "experience") then
                        dynamicMerlin.xp.buyNode = nIdx
                        dynamicMerlin.xp.buyChoice = cIdx
                    elseif string.find(combined, "relic") or string.find(combined, "power") or string.find(combined, "twisted") then
                        if nIdx ~= menuNodeIdx then
                            dynamicMerlin.relic.buyNode = nIdx
                            dynamicMerlin.relic.buyChoice = cIdx
                        end
                    end
                end
            end
        end
        print("[Shop/Merlin] Dynamic nodes resolved | Relic:", dynamicMerlin.relic.buyNode, "| Luck:", dynamicMerlin.luck.buyNode, "| Lure:", dynamicMerlin.lure.buyNode, "| XP:", dynamicMerlin.xp.buyNode)
    end
    pcall(function()
        local events = ReplicatedStorage:WaitForChild("events", 5)
        if events then
            if events:FindFirstChild("dialogstart") then
                events.dialogstart.OnClientEvent:Connect(parseMerlinDialogTree)
            end
            if events:FindFirstChild("clientdialog") then
                events.clientdialog.Event:Connect(parseMerlinDialogTree)
            end
        end
    end)
    local clonedMerlin = nil
    local function setupMerlinClone()
        local originalCFrame = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer.Character.HumanoidRootPart.CFrame
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-952, 223, -987)
        end
        task.wait(0.5)
        local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
        local npcMerlin = npcs and npcs:FindFirstChild("Merlin")
        local prompt = npcMerlin and npcMerlin:FindFirstChild("ProximityPrompt")
        if prompt then
            FireProximity(prompt)
        end
        task.wait(2)
        if npcMerlin then
            clonedMerlin = npcMerlin:Clone()
            clonedMerlin.Parent = npcs
            clonedMerlin.Name = "MerlinClone"
        end
        task.wait(0.3)
        if originalCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
        end
        task.wait(0.5)
    end
    local function invokeDynamicMerlinBuy(itemKey, amountOpt)
        local target = dynamicMerlin[itemKey]
        if not target then return end
        local DialogInteract = nil
        pcall(function()
            local Net = require(ReplicatedStorage.packages.Net)
            DialogInteract = Net:RemoteFunction("DialogInteract")
        end)
        if not DialogInteract then
            DialogInteract = ReplicatedStorage:FindFirstChild("packages")
                and ReplicatedStorage.packages:FindFirstChild("Net")
                and ReplicatedStorage.packages.Net:FindFirstChild("RF/DialogInteract")
        end
        if not DialogInteract then return end
        pcall(function()
            if target.startNode and target.startChoice then
                DialogInteract:InvokeServer(target.startNode, target.startChoice)
                task.wait(0.08)
            end
            local choiceToSend = amountOpt or target.buyChoice or 1
            DialogInteract:InvokeServer(target.buyNode, choiceToSend)
        end)
    end
    local merlinOptions = {"1", "2", "5", "10", "25", "50"}
    local selectedMerlinOpt = 1
    Merlin:AddDropdown({
        Title = "Relic Buy Amount",
        Options = merlinOptions,
        Default = "1",
        Callback = function(v)
            for i, option in ipairs(merlinOptions) do
                if option == v then
                    selectedMerlinOpt = i
                    break
                end
            end
        end
    })
    Merlin:AddToggle({
        Title = "Auto Buy Relic (Spam)",
        Default = _G.Config.AutoBuyMerlin or false,
        Callback = function(state)
            _G.Config.AutoBuyMerlin = state
            if state then
                task.spawn(function()
                    if not clonedMerlin or not clonedMerlin.Parent then
                        setupMerlinClone()
                    end
                    while _G.Config.AutoBuyMerlin do
                        invokeDynamicMerlinBuy("relic", selectedMerlinOpt)
                        task.wait(0.5)
                    end
                    if clonedMerlin and clonedMerlin.Parent then
                        clonedMerlin:Destroy()
                        clonedMerlin = nil
                    end
                end)
            end
        end
    })
    local MerlinBuffs = {
        {Title = "Auto Buy - Temporary Luck Boost", Key = "luck"},
        {Title = "Auto Buy - Temporary Lure Boost", Key = "lure"},
        {Title = "Auto Buy - Temporary XP Boost",   Key = "xp"},
        {Title = "Auto Buy - Twisted Relic",       Key = "twisted"},
    }
    for _, item in ipairs(MerlinBuffs) do
        local configKey = "AutoBuyMerlin_" .. item.Key
        Merlin:AddToggle({
            Title = item.Title,
            Default = _G.Config[configKey] or false,
            Callback = function(state)
                _G.Config[configKey] = state
                if state then
                    task.spawn(function()
                        if not clonedMerlin or not clonedMerlin.Parent then
                            setupMerlinClone()
                        end
                        invokeDynamicMerlinBuy(item.Key, 1)
                        while _G.Config[configKey] do
                            task.wait(30 * 60)
                            if not _G.Config[configKey] then break end
                            invokeDynamicMerlinBuy(item.Key, 1)
                        end
                    end)
                else
                    local anyActive = false
                    for _, b in ipairs(MerlinBuffs) do
                        if _G.Config["AutoBuyMerlin_" .. b.Key] then
                            anyActive = true
                            break
                        end
                    end
                    if not anyActive and not _G.Config.AutoBuyMerlin and clonedMerlin and clonedMerlin.Parent then
                        clonedMerlin:Destroy()
                        clonedMerlin = nil
                    end
                end
            end
        })
    end
end
return Init