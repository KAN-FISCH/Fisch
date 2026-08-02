local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local POTIONS = {
    {name = "All Season Potion", status = "All Season", cooldown = 1},
    {name = "Luck Potion", status = "Lucky", cooldown = 1},
    {name = "Lure Speed Potion", status = "Lure Speed", cooldown = 1},
    {name = "Glitched Potion", status = "Glitched", cooldown = 1},
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
    if not _G.Config.AutoPurchasePotion then
        return false
    end

    if not potionName then return false end

    local success, err = pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        if not events then return end

        local purchase = events:FindFirstChild("purchase")
        if not purchase then return end

        purchase:FireServer(potionName, "Item", nil, 1)
    end)

    if success then
        print("✓ Purchased:", potionName)
        task.wait(0.3)
        return true
    else
        warn("✗ Failed to purchase:", potionName, "-", err)
        return false
    end
end

local function usePotion(potionName)
    if not potionName then return false end

    local character = LocalPlayer.Character
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local potion = getPotionItem(potionName)

    if not potion and _G.Config.AutoPurchasePotion then
        purchasePotion(potionName)
        task.wait(0.5)
        potion = getPotionItem(potionName)
    end

    if not potion then
        warn("⚠ Potion not found:", potionName)
        return false
    end

    local success, err = pcall(function()
        if potion.Parent ~= character then
            potion.Parent = character
        end
    end)

    if not success then return false end
    task.wait(0.5)

    success, err = pcall(function()
        local equippedPotion = character:FindFirstChild(potionName)
        if equippedPotion and equippedPotion:IsA("Tool") then
            equippedPotion:Activate()
        end
    end)

    if not success then return false end
    print("✓ Used potion:", potionName)
    task.wait(0.2)

    pcall(function()
        local equippedPotion = character:FindFirstChild(potionName)
        if equippedPotion then
            equippedPotion.Parent = LocalPlayer.Backpack
        end
    end)

    return true
end

local function isPotionActive(statusName)
    if not statusName then return false end

    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end

        local hud = playerGui:FindFirstChild("hud")
        if not hud then return false end

        local safezone = hud:FindFirstChild("safezone")
        if not safezone then return false end

        local statuses = safezone:FindFirstChild("statuses")
        if not statuses then return false end

        local pattern = ""
        if statusName == "Lure Speed" then pattern = "Lure"
        elseif statusName == "Lucky" then pattern = "Luck"
        elseif statusName == "All Season" then pattern = "Season"
        elseif statusName == "Glitched" then pattern = "Glitch"
        else pattern = statusName end
        pattern = string.lower(pattern)

        for _, child in ipairs(statuses:GetChildren()) do
            if child:IsA("Frame") and string.find(string.lower(child.Name), pattern) then
                if child.Visible then
                    local timer = child:FindFirstChild("timer") or child:FindFirstChild("length")
                    if timer then 
                        if timer:IsA("TextLabel") then
                            local text = timer.Text
                            if not (text == "" or text == "00:00:00" or text == "00:00" or text == "0") then
                                return true
                            end
                        else
                            return true
                        end
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
                if not _G.Config.AutoPotionEnabled then break end
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
                                    print("→ Attempting to use potion:", potionData.name)
                                    local amountToUse = _G.Config.AutoPotionCount or 1
                                    local usedAny = false

                                    for i = 1, amountToUse do
                                        if not _G.Config.AutoPotionEnabled then break end
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
}
