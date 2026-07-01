local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)

                ExclusiveSection:AddSeperator({
                    Title = 'Auto Potion'
                })
                if _G.Config.AutoHopCosmic then
                    task.spawn(StartAutoHopCosmic)
                end
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local POTIONS = {
                    {name = "All Season Potion", status = "All Season", cooldown = 1},
                    {name = "Luck Potion", status = "Lucky", cooldown = 1},
                    {name = "Lure Speed Potion", status = "Lure Speed", cooldown = 1},
                    {name = "Glitched Potion", status = "Glitched", cooldown = 1},
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

                    if not success then
                        warn("Error checking status for:", statusName, "-", result)
                        return false
                    end

                    return result
                end
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
                        if not events then
                            warn("ReplicatedStorage.events not found")
                            return
                        end

                        local purchase = events:FindFirstChild("purchase")
                        if not purchase then
                            warn("Purchase event not found")
                            return
                        end

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
                    if not potionName then 
                        warn("No potion name provided")
                        return false 
                    end

                    local character = LocalPlayer.Character
                    if not character then 
                        warn("Character not found")
                        return false 
                    end

                    local humanoid = character:FindFirstChild("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then
                        warn("Character dead or no humanoid")
                        return false
                    end

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

                    if not success then
                        warn("✗ Failed to equip potion:", err)
                        return false
                    end

                    task.wait(0.5)

                    success, err = pcall(function()
                        local equippedPotion = character:FindFirstChild(potionName)
                        if equippedPotion and equippedPotion:IsA("Tool") then
                            equippedPotion:Activate()
                        end
                    end)

                    if not success then
                        warn("✗ Failed to activate potion:", err)
                        return false
                    end

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

                local function startAutoPotionLoop()
                    if _G.Config.AutoPotionRunning then
                        return
                    end

                    _G.Config.AutoPotionRunning = true
                    print("✓ Auto Potion started!")

                    task.spawn(function()
                        while _G.Config.AutoPotionEnabled do
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
                                if type(selectedPotionName) ~= "string" then continue end

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
                            task.wait(2)
                        end

                        _G.Config.AutoPotionRunning = false
                        print("✓ Auto Potion stopped!")
                    end)
                end

                local function stopAutoPotionLoop()
                    _G.Config.AutoPotionEnabled = false
                    task.wait(0.3)
                    _G.Config.AutoPotionRunning = false
                    print("✓ Auto Potion disabled!")
                end
                local PotionDropdown = ExclusiveSection:AddDropdown({
                    Title = "Select Potions",
                    Options = (function()
                        local options = {}
                        for _, potion in pairs(POTIONS) do
                            table.insert(options, potion.name)
                        end
                        return options
                    end)(),
                    Default = _G.Config.SelectedPotions or {},
                    PlaceHolder = "Select Potions",
                    Multi = true,
                    Callback = function(SelectedPotions)
                        local normalized = {}
                        if type(SelectedPotions) == "table" then
                            for k, v in pairs(SelectedPotions) do
                                if type(k) == "string" and v == true then
                                    table.insert(normalized, k)
                                elseif type(k) == "number" and type(v) == "string" then
                                    table.insert(normalized, v)
                                end
                            end
                        elseif type(SelectedPotions) == "string" and SelectedPotions ~= "" then
                            table.insert(normalized, SelectedPotions)
                        end
                        _G.Config.SelectedPotions = normalized
                    end,
                })

                ExclusiveSection:AddSlider({
                    Title = "Auto Potion Count",
                    Description = "Amount of potions to use per activation",
                    Default = _G.Config.AutoPotionCount or 1,
                    Min = 1,
                    Max = 10,
                    Rounding = 0,
                    Callback = function(Value)
                        _G.Config.AutoPotionCount = Value
                    end
                })

                local AutoPotionToggle = ExclusiveSection:AddToggle({
                    Title = "Auto Potion",
                    Default = _G.Config.AutoPotionEnabled or false,
                    Callback = function(isEnabled)
                        _G.Config.AutoPotionEnabled = isEnabled

                        if isEnabled then
                            if type(_G.Config.SelectedPotions) == "string" then
                                _G.Config.SelectedPotions = {_G.Config.SelectedPotions}
                            elseif type(_G.Config.SelectedPotions) ~= "table" then
                                _G.Config.SelectedPotions = {}
                            end

                            if #_G.Config.SelectedPotions == 0 then
                                warn("⚠ Please select at least one potion first!")
                                return
                            end

                            startAutoPotionLoop()
                        else
                            stopAutoPotionLoop()
                        end
                    end,
                })

                function UseAllSelectedPotions()
                    if type(_G.Config.SelectedPotions) == "string" then
                        _G.Config.SelectedPotions = {_G.Config.SelectedPotions}
                    end

                    if not _G.Config.SelectedPotions or #_G.Config.SelectedPotions == 0 then
                        warn("⚠ No potions selected!")
                        return
                    end

                    for _, potionName in pairs(_G.Config.SelectedPotions) do
                        if type(potionName) == "string" then
                            usePotion(potionName)
                            task.wait(0.3)
                        end
                    end
                end

                function CheckAllPotionStatus()

                    for _, potion in pairs(POTIONS) do
                        local isActive = isPotionActive(potion.status)
                        local status = isActive and "✓ ACTIVE" or "✗ Inactive"
                        print(string.format("%-30s %s", potion.name, status))
                    end
                end
end
return Init
