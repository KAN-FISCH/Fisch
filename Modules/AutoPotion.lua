local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local POTIONS = {
    { name = "Golden Potion", status = "Golden Potion Status", cooldown = 600 },
    { name = "Luck Potion", status = "Luck Potion Status", cooldown = 600 },
    { name = "Haste Potion", status = "Haste Potion Status", cooldown = 600 },
}

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function isPotionActive(statusName)
    local character = getCharacter()
    if character and character:FindFirstChild(statusName) then
        return true
    end
    -- Check local UI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local activeEffects = playerGui:FindFirstChild("ActiveEffects")
        if activeEffects and activeEffects:FindFirstChild(statusName) then
            return true
        end
    end
    return false
end

local function usePotion(potionName)
    local character = getCharacter()
    if not character then return false end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end

    local potion = backpack:FindFirstChild(potionName)
    if not potion then
        potion = character:FindFirstChild(potionName)
    end

    if not potion then return false end

    pcall(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(potion)
        end
    end)

    task.wait(0.2)

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
                if type(selectedPotionName) == "string" then
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
                end
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
