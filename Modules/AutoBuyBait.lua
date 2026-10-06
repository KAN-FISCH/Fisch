local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CRATE_LIST = {
    "Bait Crate",
    "Quality Bait Crate",
    "Tropical Bait Crate",
    "Festive Bait Crate",
    "Common Crate",
    "Carbon Crate",
    "Coral Geode",
    "Volcanic Geode",
}

local BAIT_LIST = {
    -- Crates (Official Fisch Shop item name)
    "Bait Crate",
    "Quality Bait Crate",
    "Tropical Bait Crate",
    "Festive Bait Crate",
    "Common Crate",
    "Carbon Crate",
    "Coral Geode",
    "Volcanic Geode",
    -- Individual Baits
    "Worm", "Cricket", "Leech", "Minnow", "Firefly",
    "Shrimp", "Squid", "Sand Dollar", "Pearl",
    "Phantom Worm", "Enchanted Bait", "Seaside Sardine",
    "Truffle Worm", "Instant Catch Bait", "Deep Coral",
    "Magnet Bait", "Rapid Catch", "Night Shrimp", "Fish Head",
    "Super Flakes", "Golden Hook", "Maggot", "Shark Bait",
}

local function autoOpenCrates()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        local promptAmount = events and events:FindFirstChild("PromptAmount")
        if promptAmount then
            promptAmount.OnClientInvoke = function(crateName, defaultAmount)
                local totalToOpen = defaultAmount or 1
                pcall(function()
                    local dc = require(ReplicatedStorage.client.legacyControllers.DataController)
                    if dc and dc.InventoryReplicator then
                        local count = 0
                        for _, v in dc.InventoryReplicator:TryIndex({ "Inventory" }) do
                            if v.name == crateName and not (v.sub and v.sub.Favourited) then
                                count = count + (v.sub and v.sub.Stack or 1)
                            end
                        end
                        if count > 0 then
                            totalToOpen = count
                        end
                    end
                end)
                return math.clamp(totalToOpen, 1, 1000), true
            end
        end

        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not (char and backpack) then return end

        local curTool = char:FindFirstChildOfClass("Tool")
        if curTool and not (curTool.Name:find("Crate") or curTool.Name:find("Geode") or curTool.Name:find("Bait")) then
            curTool.Parent = backpack
            task.wait(0.2)
        end

        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Crate") or tool.Name:find("Geode") or tool.Name:find("Bait")) then
                tool.Parent = char
                task.wait(0.25)
                tool.Enabled = true
                tool:Activate()
                task.wait(0.65)
                if tool.Parent == char then
                    tool.Parent = backpack
                end
            end
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

local KNOWN_ITEM_LOCATIONS = {
    ["Bait Crate"]              = Vector3.new(384.5, 135.5, 337.5),
    ["Quality Bait Crate"]      = Vector3.new(384.5, 135.5, 337.5),
    ["Common Crate"]            = Vector3.new(384.5, 135.5, 337.5),
    ["Carbon Crate"]            = Vector3.new(384.5, 135.5, 337.5),
    ["Tropical Bait Crate"]     = Vector3.new(-1480.0, 132.0, 715.0),
    ["Coral Geode"]             = Vector3.new(-185.0, 134.0, 1940.0),
    ["Volcanic Geode"]          = Vector3.new(-1930.0, 165.0, 310.0),
    ["Festive Bait Crate"]      = Vector3.new(2625.0, 135.0, 2370.0),
}

local function getItemLocation(itemName)
    if not itemName then return nil end
    if KNOWN_ITEM_LOCATIONS[itemName] then return KNOWN_ITEM_LOCATIONS[itemName] end
    local lower = itemName:lower()
    for name, pos in pairs(KNOWN_ITEM_LOCATIONS) do
        if name:lower() == lower or name:lower():find(lower, 1, true) or lower:find(name:lower(), 1, true) then
            return pos
        end
    end
    return Vector3.new(384.5, 135.5, 337.5)
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

local function buyBaitMethod(baitName, amount)
    amount = amount or 1
    baitName = baitName or "Bait Crate"

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local origCF = hrp.CFrame
    local targetPart, prompt = findItemPrompt(baitName)
    local targetPos = nil

    if targetPart then
        targetPos = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
    else
        targetPos = getItemLocation(baitName)
    end

    local didTeleport = false
    if targetPos then
        local dist = (hrp.Position - targetPos).Magnitude

        if dist > 15 then
            didTeleport = true

            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(targetPos)
            end)

            safeTeleport(char, CFrame.new(targetPos + Vector3.new(0, 2.5, 0)))
            hrp.Anchored = true

            local waited = 0
            while waited < 2.0 and not prompt do
                task.wait(0.1)
                waited = waited + 0.1
                targetPart, prompt = findItemPrompt(baitName)
                if prompt then break end
            end

            if targetPart then
                local realPos = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
                safeTeleport(char, CFrame.new(realPos + Vector3.new(0, 2.5, 0)))
            end
        end

        -- Dismiss any open shop prompt GUI so it doesn't block the screen
        dismissPromptGui()
    end

    -- 1. Primary: events.purchase with category "Fish" (verified by Cobalt spy)
    local events = ReplicatedStorage:FindFirstChild("events")
    local purchase = events and events:FindFirstChild("purchase")
    if purchase then
        local rem = amount
        while rem > 0 do
            if not (_G.Config and _G.Config.AutoBuyBait) then break end
            local buyBatch = rem > 50 and 50 or rem
            pcall(function()
                purchase:FireServer(baitName, "Fish", nil, buyBatch)
            end)
            rem = rem - buyBatch
            if rem > 0 then task.wait(0.25) end
        end

        dismissPromptGui()

        if didTeleport and origCF and char and char:FindFirstChild("HumanoidRootPart") then
            task.wait(0.2)
            local curHrp = char:FindFirstChild("HumanoidRootPart")
            if curHrp then
                curHrp.Anchored = false
                safeTeleport(char, origCF)
            end
        else
            if hrp then hrp.Anchored = false end
        end

        return true
    end

    -- 2. Fallback: packages.Net RF/PurchaseBait
    local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
    local purchaseBaitRF = net and (net:FindFirstChild("RF/PurchaseBait") or net:FindFirstChild("RF/Bait/Purchase"))
    if purchaseBaitRF then
        local ok = pcall(function()
            for i = 1, amount do
                if not (_G.Config and _G.Config.AutoBuyBait) then break end
                purchaseBaitRF:InvokeServer(baitName)
                if amount > 1 then task.wait(0.1) end
            end
        end)
        if ok then return true end
    end

    return false
end

local function equipBaitMethod(baitName)
    local net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
    local equipBaitRF = net and (net:FindFirstChild("RF/EquipBait") or net:FindFirstChild("RF/Bait/Equip"))
    if equipBaitRF then
        pcall(function()
            equipBaitRF:InvokeServer(baitName)
        end)
    end
end

local function AutoBuyBaitLoop()
    task.spawn(function()
        while task.wait(1.5) do
            if _G.Config and _G.Config.AutoBuyBait then
                pcall(function()
                    local baitName = _G.Config.SelectedBait or "Bait Crate"
                    local amount = _G.Config.BuyBaitAmount or 1
                    buyBaitMethod(baitName, amount)

                    if _G.Config.AutoOpenBaitCrate or (baitName:find("Crate") or baitName:find("Geode")) then
                        task.wait(0.3)
                        autoOpenCrates()
                    end

                    if _G.Config.AutoEquipBait then
                        task.wait(0.3)
                        equipBaitMethod(baitName)
                    end
                end)
            end
        end
    end)
end

AutoBuyBaitLoop()

return {
    Init = function() end,
    GetBaitList = function() return BAIT_LIST end,
    GetCrateList = function() return CRATE_LIST end,
    BuyBait = buyBaitMethod,
    EquipBait = equipBaitMethod,
    OpenCrates = autoOpenCrates,
    BaitList = BAIT_LIST,
    CrateList = CRATE_LIST,
}