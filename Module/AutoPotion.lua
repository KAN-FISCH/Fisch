local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local POTIONS = {
    {name = "All Season Potion", status = "All Season", cooldown = 1},
    {name = "Luck Potion",       status = "Lucky",      cooldown = 1},
    {name = "Lure Speed Potion", status = "Lure Speed", cooldown = 1},
    {name = "Glitched Potion",   status = "Glitched",   cooldown = 1},
}

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
        if statusName == "Lure Speed" then pattern = "lure"
        elseif statusName == "Lucky" then pattern = "luck"
        elseif statusName == "All Season" then pattern = "season"
        elseif statusName == "Glitched" then pattern = "glitch"
        else pattern = statusName:lower() end

        for _, child in ipairs(statuses:GetChildren()) do
            if child:IsA("Frame") and child.Name:lower():find(pattern) then
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
    return success and result or false
end

local function getPotionItem(potionName)
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
    if not _G.Config or not _G.Config.AutoPurchasePotion then return false end
    local success, err = pcall(function()
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
        local purchase = events and events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer(potionName, "Item", nil, 1)
        end
    end)
    if success then
        print("✓ Purchased:", potionName)
        task.wait(0.3)
        return true
    end
    return false
end

local function usePotion(potionName)
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local potion = getPotionItem(potionName)

    if not potion and _G.Config and _G.Config.AutoPurchasePotion then
        purchasePotion(potionName)
        task.wait(0.5)
        potion = getPotionItem(potionName)
    end

    if not potion then return false end

    local success, err = pcall(function()
        if potion.Parent ~= character then
            potion.Parent = character
        end
    end)
    if not success then return false end

    task.wait(0.5)

    pcall(function()
        local equippedPotion = character:FindFirstChild(potionName)
        if equippedPotion and equippedPotion:IsA("Tool") then
            equippedPotion:Activate()
        end
    end)

    print("✓ Used potion:", potionName)
    task.wait(0.2)

    pcall(function()
        local equippedPotion = character:FindFirstChild(potionName)
        if equippedPotion then equippedPotion.Parent = LocalPlayer.Backpack end
    end)

    return true
end

local function StartAutoPotionLoop()
    if _G.Config and _G.Config.AutoPotionRunning then return end
    if _G.Config then _G.Config.AutoPotionRunning = true end

    task.spawn(function()
        while _G.Config and _G.Config.AutoPotionEnabled do
            local selectedList = _G.Config.SelectedPotions or {}
            if type(selectedList) == "string" then
                selectedList = {selectedList}
            end

            for _, selectedPotionName in pairs(selectedList) do
                if not (_G.Config and _G.Config.AutoPotionEnabled) then break end
                if type(selectedPotionName) ~= "string" then continue end

                pcall(function()
                    for _, potionData in pairs(POTIONS) do
                        if potionData.name == selectedPotionName then
                            if not isPotionActive(potionData.status) then
                                if _G.Config then
                                    _G.Config.PotionCooldowns = _G.Config.PotionCooldowns or {}
                                    local lastUsed = _G.Config.PotionCooldowns[potionData.name] or 0
                                    if tick() - lastUsed >= potionData.cooldown then
                                        local amountToUse = (_G.Config and _G.Config.AutoPotionCount) or 1
                                        for i = 1, amountToUse do
                                            if not (_G.Config and _G.Config.AutoPotionEnabled) then break end
                                            if usePotion(potionData.name) then
                                                task.wait(0.6)
                                            else
                                                break
                                            end
                                        end
                                        _G.Config.PotionCooldowns[potionData.name] = tick()
                                    end
                                end
                            end
                            break
                        end
                    end
                end)
                task.wait(0.2)
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
