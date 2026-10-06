local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local POTIONS = {
    {name = "All Season Potion", status = "All Season", pattern = "season", cooldown = 1},
    {name = "Luck Potion", status = "Lucky", pattern = "luck", cooldown = 1},
    {name = "Lure Speed Potion", status = "Lure Speed", pattern = "lure", cooldown = 1},
    {name = "Glitched Potion", status = "Glitched", pattern = "glitch", cooldown = 1},
    {name = "Anomalous Potion", status = "Anomalous", pattern = "anomalous", cooldown = 1},
    {name = "Resilience Potion", status = "Resilience", pattern = "resilience", cooldown = 1},
    {name = "Haste Potion", status = "Haste", pattern = "haste", cooldown = 1},
    {name = "Mutation Potion", status = "Mutation", pattern = "mutation", cooldown = 1},
    {name = "Treasure Potion", status = "Treasure", pattern = "treasure", cooldown = 1},
}

local function getPotionItem(potionName)
    if not potionName then return nil end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local potion = backpack:FindFirstChild(potionName)
        if potion then return potion end
    end
    local character = LocalPlayer.Character
    if character then
        local potion = character:FindFirstChild(potionName)
        if potion then return potion end
    end
    return nil
end

local function purchasePotion(potionName)
    if not (_G.Config and _G.Config.AutoPurchasePotion) then
        return false
    end
    if not potionName then return false end
    local success, err = pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        local purchase = events and events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer(potionName, "Item", nil, 1)
        end
    end)
    if success then
        task.wait(0.4)
        return true
    else
        return false
    end
end

local function usePotion(potionName)
    if not potionName then return false end
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local potion = getPotionItem(potionName)
    if not potion and _G.Config and _G.Config.AutoPurchasePotion then
        purchasePotion(potionName)
        task.wait(0.5)
        potion = getPotionItem(potionName)
    end
    if not potion then
        return false
    end

    -- Remember previously equipped tool (e.g. rod) to restore after using potion
    local prevTool = nil
    for _, t in ipairs(character:GetChildren()) do
        if t:IsA("Tool") and t ~= potion then
            prevTool = t
            break
        end
    end

    local equippedOk = pcall(function()
        if potion.Parent ~= character then
            humanoid:EquipTool(potion)
        end
    end)
    if not equippedOk then return false end
    task.wait(0.4)

    pcall(function()
        local activePotion = character:FindFirstChild(potionName)
        if activePotion and activePotion:IsA("Tool") then
            activePotion:Activate()
        end
    end)
    task.wait(0.3)

    pcall(function()
        local activePotion = character:FindFirstChild(potionName)
        if activePotion then
            activePotion.Parent = LocalPlayer:FindFirstChild("Backpack")
        end
    end)

    -- Restore previous rod/tool
    if prevTool and prevTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
        task.wait(0.1)
        pcall(function()
            humanoid:EquipTool(prevTool)
        end)
    end

    return true
end

local function isPotionActive(statusName)
    if not statusName then return false end
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        local hud = playerGui:FindFirstChild("hud")
        local safezone = hud and hud:FindFirstChild("safezone")
        local statuses = safezone and safezone:FindFirstChild("statuses")
        if not statuses then return false end

        local targetPattern = statusName:lower()
        for _, p in ipairs(POTIONS) do
            if p.status:lower() == targetPattern or p.name:lower():find(targetPattern, 1, true) then
                targetPattern = p.pattern
                break
            end
        end

        for _, child in ipairs(statuses:GetChildren()) do
            if child:IsA("Frame") and string.find(string.lower(child.Name), targetPattern) then
                if child.Visible then
                    local timer = child:FindFirstChild("timer") or child:FindFirstChild("length")
                    if timer and timer:IsA("TextLabel") then
                        local text = timer.Text
                        if text ~= "" and text ~= "00:00:00" and text ~= "00:00" and text ~= "0" then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
        return false
    end)
    if not success then return false end
    return result
end

local function StartAutoPotionLoop()
    if _G.Config and _G.Config.AutoPotionRunning then return end
    if _G.Config then _G.Config.AutoPotionRunning = true end
    task.spawn(function()
        while _G.Config and _G.Config.AutoPotionEnabled do
            local selectedList = _G.Config.SelectedPotions
            if type(selectedList) ~= "table" then
                if type(selectedList) == "string" then
                    selectedList = {selectedList}
                else
                    selectedList = {}
                end
            end
            for _, selectedPotionName in pairs(selectedList) do
                if not (_G.Config and _G.Config.AutoPotionEnabled) then break end
                if type(selectedPotionName) == "string" then
                    pcall(function()
                        local potionData = nil
                        for _, data in pairs(POTIONS) do
                            if data.name == selectedPotionName then
                                potionData = data
                                break
                            end
                        end
                        if potionData then
                            if not isPotionActive(potionData.status) then
                                _G.Config.PotionCooldowns = _G.Config.PotionCooldowns or {}
                                local lastUsed = _G.Config.PotionCooldowns[potionData.name] or 0
                                if tick() - lastUsed >= potionData.cooldown then
                                    local amountToUse = _G.Config.AutoPotionCount or 1
                                    local usedAny = false
                                    for i = 1, amountToUse do
                                        if not (_G.Config and _G.Config.AutoPotionEnabled) then break end
                                        if usePotion(potionData.name) then
                                            usedAny = true
                                            task.wait(0.6)
                                        else
                                            break
                                        end
                                    end
                                    if usedAny then
                                        _G.Config.PotionCooldowns[potionData.name] = tick()
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end
            task.wait(2)
        end
        if _G.Config then _G.Config.AutoPotionRunning = false end
    end)
end

local function StopAutoPotionLoop()
    if _G.Config then
        _G.Config.AutoPotionEnabled = false
        _G.Config.AutoPotionRunning = false
    end
end

local function GetPotionList()
    local options = {}
    for _, potion in pairs(POTIONS) do
        table.insert(options, potion.name)
    end
    return options
end

return {
    StartLoop = StartAutoPotionLoop,
    StopLoop = StopAutoPotionLoop,
    UsePotion = usePotion,
    IsPotionActive = isPotionActive,
    GetPotionList = GetPotionList,
    Potions = POTIONS,
}