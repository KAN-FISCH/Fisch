local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)

                ExclusiveSection:AddSeperator({
                    Title = 'Auto Minigames'
                })

                local lastBvTo = Vector3.new()

                local function AutoVolleyLoop()
                    while _G.Config.AutoVolley do
                        task.wait(0.1)
                        pcall(function()
                            local player = game.Players.LocalPlayer
                            local char = player.Character
                            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                            local hrp = char.HumanoidRootPart

                            local vbGui = player.PlayerGui:FindFirstChild("volleyball")
                            local isPlaying = vbGui and vbGui.Enabled

                            local CollectionService = game:GetService("CollectionService")
                            local courts = CollectionService:GetTagged("BeachVolleyballCourt")
                            if #courts == 0 then return end

                            local closestCourt = nil
                            local minDistance = math.huge
                            for _, court in ipairs(courts) do
                                if court:FindFirstChild("Side1") then
                                    local dist = (hrp.Position - court.Side1.Position).Magnitude
                                    if dist < minDistance then
                                        minDistance = dist
                                        closestCourt = court
                                    end
                                end
                            end

                            if not closestCourt then return end

                            if not isPlaying and _G.Config.AutoJoinVolley then
                                local targetSideStr = _G.Config.VolleySide or "Side 1"
                                local targetSideName = (targetSideStr == "Side 1") and "Side1" or "Side2"
                                local sidePart = closestCourt:FindFirstChild(targetSideName)

                                if sidePart then
                                    local prompt = sidePart:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and prompt.Enabled then
                                        hrp.CFrame = sidePart.CFrame * CFrame.new(0, 3, 0)
                                        task.wait(0.3)
                                        if fireproximityprompt then
                                            fireproximityprompt(prompt, 1, true)
                                        end
                                        task.wait(1.5)
                                    end
                                end
                                return
                            end

                            if isPlaying then
                                local scoreLabel = vbGui:FindFirstChild("Score") and vbGui.Score:FindFirstChild("ScoreLabel")
                                if scoreLabel and (_G.Config.VolleyTargetScore or 15) > 0 then
                                    local currentScore = tonumber(scoreLabel.Text) or 0
                                    if currentScore >= _G.Config.VolleyTargetScore then
                                        return
                                    end
                                end

                                local volleyMode = _G.Config.VolleyMode or "Win"
                                if volleyMode == "Lose" then
                                    return
                                end

                                local distance = (hrp.Position - closestCourt.Side1.Position).Magnitude
                                if distance < 200 then
                                    local ball = closestCourt:FindFirstChild("Ball")
                                    if ball and ball:GetAttribute("BV_Active") then
                                        local bvTo = ball:GetAttribute("BV_To")
                                        if bvTo and typeof(bvTo) == "Vector3" then
                                            if (bvTo - lastBvTo).Magnitude > 0.5 then
                                                local side1 = closestCourt:FindFirstChild("Side1")
                                                local side2 = closestCourt:FindFirstChild("Side2")

                                                local isOurSide = true
                                                if side1 and side2 then
                                                    local mySide = side1
                                                    if (hrp.Position - side2.Position).Magnitude < (hrp.Position - side1.Position).Magnitude then
                                                        mySide = side2
                                                    end
                                                    local otherSide = (mySide == side1) and side2 or side1

                                                    if (bvTo - mySide.Position).Magnitude > (bvTo - otherSide.Position).Magnitude then
                                                        isOurSide = false
                                                    end
                                                end

                                                if isOurSide then
                                                    lastBvTo = bvTo
                                                    hrp.CFrame = CFrame.new(bvTo.X, bvTo.Y + 1, bvTo.Z)
                                                    local net = closestCourt:FindFirstChild("Net")
                                                    if net then
                                                        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(net.Position.X, hrp.Position.Y, net.Position.Z))
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        lastBvTo = Vector3.new()
                                    end
                                end
                            end
                        end)
                    end
                end

                ExclusiveSection:AddDropdown({
                    Title = "Volley Mode (Farm)",
                    Description = "Win = Teleport & Pukul | Lose = Diam saja (Farm Kalah Cepat)",
                    Options = {"Win", "Lose"},
                    Default = _G.Config.VolleyMode or "Win",
                    Callback = function(Value)
                        _G.Config.VolleyMode = Value
                    end
                })

                ExclusiveSection:AddDropdown({
                    Title = "Select Court Side",
                    Description = "Pilih sisi lapangan untuk Auto Join",
                    Options = {"Side 1", "Side 2"},
                    Default = _G.Config.VolleySide or "Side 1",
                    Callback = function(Value)
                        _G.Config.VolleySide = Value
                    end
                })

                ExclusiveSection:AddSlider({
                    Title = "Target Score (Stop Hitting)",
                    Description = "Berhenti memukul setelah skor ini (0 = Tanpa Batas)",
                    Default = _G.Config.VolleyTargetScore or 15,
                    Min = 0,
                    Max = 500,
                    Rounding = 0,
                    Callback = function(Value)
                        _G.Config.VolleyTargetScore = Value
                    end
                })

                ExclusiveSection:AddToggle({
                    Title = "Auto Join Volley",
                    Description = "Otomatis teleport & join lapangan yang dipilih saat tidak bermain",
                    Default = _G.Config.AutoJoinVolley or false,
                    Callback = function(state)
                        _G.Config.AutoJoinVolley = state
                    end
                })

                ExclusiveSection:AddToggle({
                    Title = "Auto Volley",
                    Description = "Master Toggle untuk menyalakan fitur Voli Pantai (Beach Volleyball)",
                    Default = _G.Config.AutoVolley or false,
                    Callback = function(state)
                        _G.Config.AutoVolley = state
                        if state then
                            task.spawn(AutoVolleyLoop)
                        end
                    end
                })

                ExclusiveSection:AddSeperator({
                    Title = 'Egg Hunt Features'
                })

                StatusEggParagraph = ExclusiveSection:AddParagraph({
                    Title = "Egg Hunt Status",
                    Content = "Scanning eggs..."
                })

                _G.Config.SelectedEgg = _G.Config.SelectedEgg or "All"
                eggOptions = {"All"}

                EggDropdown = ExclusiveSection:AddDropdown({
                    Title = "Select Egg",
                    Options = eggOptions,
                    Default = _G.Config.SelectedEgg or "All",
                    Callback = function(val)
                        _G.Config.SelectedEgg = val
                    end
                })

                ExclusiveSection:AddButton({
                    Title = "Refresh Egg List",
                    Callback = function()
                        local newOptions = {"All"}
                        pcall(function()
                            local activeEggs = workspace:FindFirstChild("active") and workspace.active:FindFirstChild("ActiveEggHuntEggs")
                            if activeEggs then
                                for _, egg in pairs(activeEggs:GetChildren()) do
                                    if not table.find(newOptions, egg.Name) then
                                        table.insert(newOptions, egg.Name)
                                    end
                                end
                            end
                        end)
                        EggDropdown:Refresh(newOptions, { _G.Config.SelectedEgg or "All" })
                    end
                })

                ExclusiveSection:AddToggle({
                    Title = "Auto Collect Egg",
                    Description = "Automatically collects selected eggs",
                    Default = _G.Config.AutoCollectEgg or false,
                    Callback = function(state)
                        _G.Config.AutoCollectEgg = state
                        if state then
                            task.spawn(function()
                                while _G.Config.AutoCollectEgg do
                                    local player = game.Players.LocalPlayer
                                    local char = player.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                                    if hrp then
                                        local activeFolder = workspace:FindFirstChild("active")
                                        local activeEggs = activeFolder and activeFolder:FindFirstChild("ActiveEggHuntEggs")

                                        if activeEggs then
                                            local children = activeEggs:GetChildren()
                                            if #children == 0 then
                                            end

                                            for _, egg in pairs(children) do
                                                if not _G.Config.AutoCollectEgg then break end

                                                local selected = _G.Config.SelectedEgg or "All"
                                                if selected == "All" or egg.Name:find(selected) then
                                                    local targetPos = egg:GetPivot().Position
                                                    hrp.CFrame = CFrame.new(targetPos)

                                                    pcall(function()
                                                        local basket = player.Backpack:FindFirstChild("Egg Basket") or char:FindFirstChild("Egg Basket")
                                                        if basket and char:FindFirstChildOfClass("Humanoid") then
                                                            char:FindFirstChildOfClass("Humanoid"):EquipTool(basket)
                                                        end
                                                    end)

                                                    task.wait(0.1)

                                                    local cd = egg:FindFirstChildWhichIsA("ClickDetector", true)
                                                    if cd then pcall(function() fireclickdetector(cd) end) end

                                                    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                                                    if prompt then pcall(function() fireproximityprompt(prompt) end) end

                                                    task.wait(0.3)
                                                end
                                                task.wait(0.5)
                                            end
                                        end
                                    end
                                    task.wait(1)
                                end
                            end)
                        end
                    end
                })

                task.spawn(function()
                    while task.wait(2) do
                        pcall(function()
                            local activeEggs = workspace:FindFirstChild("active") and workspace.active:FindFirstChild("ActiveEggHuntEggs")
                            if activeEggs then
                                local eggs = activeEggs:GetChildren()
                                local eggCounts = {}
                                for _, egg in pairs(eggs) do
                                    eggCounts[egg.Name] = (eggCounts[egg.Name] or 0) + 1
                                end

                                local content = "Total Eggs: " .. #eggs .. "\n"
                                local sortedNames = {}
                                for name in pairs(eggCounts) do table.insert(sortedNames, name) end
                                table.sort(sortedNames)

                                for _, name in ipairs(sortedNames) do
                                    content = content .. "• " .. name .. ": " .. eggCounts[name] .. "\n"
                                end

                                if StatusEggParagraph.Set then
                                    StatusEggParagraph:Set({
                                        Title = "Egg Hunt Status",
                                        Content = content
                                    })
                                elseif StatusEggParagraph.SetDesc then
                                    StatusEggParagraph:SetDesc(content)
                                end
                            else
                                if StatusEggParagraph.Set then
                                    StatusEggParagraph:Set({
                                        Title = "Egg Hunt Status",
                                        Content = "No Egg Hunt active."
                                    })
                                elseif StatusEggParagraph.SetDesc then
                                    StatusEggParagraph:SetDesc("No Egg Hunt active.")
                                end
                            end
                        end)
                    end
                end)

            ExclusiveSection:AddSeperator({
                Title = 'Auto Chest Collector',
            })

            autoCollectRunning = false

            function getChestsWithProximity()
                chests = {}

                local world = workspace:FindFirstChild("world")
                if not world then return chests end

                local function scanFolder(folder)
                    if not folder then return end
                    for _, prompt in ipairs(folder:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local isChest = false
                            local lAction = string.lower(prompt.ActionText)
                            local lObject = string.lower(prompt.ObjectText)
                            if string.find(lAction, "open") or string.find(lAction, "claim") or string.find(lObject, "chest") then
                                isChest = true
                            elseif prompt.Parent and string.find(string.lower(prompt.Parent.Name), "chest") then
                                isChest = true
                            else
                                isChest = true 
                            end

                            if isChest then
                                local tpPart = nil
                                local parent = prompt.Parent
                                if parent:IsA("BasePart") then
                                    tpPart = parent
                                else
                                    local model = prompt:FindFirstAncestorWhichIsA("Model")
                                    if model then
                                        tpPart = model.PrimaryPart or model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart", true)
                                    end
                                end

                                if tpPart then
                                    table.insert(chests, {
                                        chest = tpPart,
                                        proximity = prompt,
                                        location = "Chest"
                                    })
                                end
                            end
                        end
                    end
                end

                scanFolder(world:FindFirstChild("ActiveChestsFolder"))
                scanFolder(world:FindFirstChild("chests"))

                return chests
            end

            function startAutoCollectChests()
                if autoCollectRunning then return end

                autoCollectRunning = true

                task.spawn(function()
                    while autoCollectRunning do
                        character = game.Players.LocalPlayer.Character
                        if not character then
                            task.wait(1)
                            continue
                        end

                        hrp = character:FindFirstChild("HumanoidRootPart")
                        if not hrp then
                            task.wait(1)
                            continue
                        end

                        chests = getChestsWithProximity()

                        if #chests == 0 then
                            task.wait(2)
                            continue
                        end

                        for _, chestData in ipairs(chests) do
                            if not autoCollectRunning then break end

                            character = game.Players.LocalPlayer.Character
                            if not character then break end

                            hrp = character:FindFirstChild("HumanoidRootPart")
                            if not hrp then break end

                            chest = chestData.chest
                            proximity = chestData.proximity

                            if not proximity or not proximity.Enabled or not proximity.Parent then
                                continue
                            end

                            local chestPos = nil
                            pcall(function()
                                chestPos = chest:GetPivot().Position
                            end)

                            if chestPos then
                                pcall(function()
                                    hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, 5, 0))
                                end)

                                task.wait(0.5)

                                if proximity and proximity.Parent and proximity.Enabled then
                                    pcall(function()
                                        fireproximityprompt(proximity)
                                    end)
                                end

                                task.wait(0.5)
                            end
                        end

                        task.wait(2)
                    end
                end)
            end

            function stopAutoCollectChests()
                autoCollectRunning = false
            end

            ExclusiveSection:AddToggle({
                Title = "Auto Collect Chests",
                Description = "Automatically collects all chests until none remain",
                Default = false,
                Callback = function(state)
                    if state then
                        startAutoCollectChests()
                    else
                        stopAutoCollectChests()
                    end
                end
            })

            ExclusiveSection:AddSeperator({
                Title = 'Auto Collect Shell'
            })

            local ShellLocations = {
                ["Moosewood"]       = Vector3.new(350,  135,  250),
                ["Roslit Bay"]      = Vector3.new(-1450, 135,  750),
                ["Sunstone Island"] = Vector3.new(-935,  130, -1105),
                ["Terrapin Island"] = Vector3.new(-200,  130,  1925),
                ["Mushgrove Swamp"] = Vector3.new(2425,  130,  -670),
                ["Forsaken Shores"] = Vector3.new(-2425, 135,  1555),
            }

            local ShellIslandOrder = {
                "Moosewood",
                "Roslit Bay",
                "Sunstone Island",
                "Terrapin Island",
                "Mushgrove Swamp",
                "Forsaken Shores",
            }

            local ShellIslandDropdown = ExclusiveSection:AddDropdown({
                Title = "Shell Islands",
                Content = "Pilih island untuk collect shell",
                Multi = true,
                Options = ShellIslandOrder,
                Default = _G.Config.SelectedShellIslands or {"Moosewood"},
                Callback = function(val)
                    _G.Config.SelectedShellIslands = val
                end
            })

            local _autoShellRunning = false

            local function findNearestShell(targetPos, maxDist)
                local best, bestDist, bestPrompt = nil, maxDist, nil
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name == "Shell" then
                        local handle = obj:FindFirstChild("Handle")
                        local prompt = handle and handle:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            local pos = nil
                            pcall(function()
                                pos = obj:GetPivot().Position
                            end)
                            if pos then
                                local dist = (pos - targetPos).Magnitude
                                if dist < bestDist then
                                    best = obj
                                    bestDist = dist
                                    bestPrompt = prompt
                                end
                            end
                        end
                    end
                end
                return best, bestPrompt
            end

            local function startAutoCollectShell()
                if _autoShellRunning then return end
                _autoShellRunning = true

                task.spawn(function()
                    while _G.Config.AutoCollectShell do
                        local player = game.Players.LocalPlayer
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")

                        if not hrp then
                            task.wait(1)
                            continue
                        end

                        local islands = _G.Config.SelectedShellIslands
                        if type(islands) ~= "table" or #islands == 0 then
                            task.wait(2)
                            continue
                        end

                        for _, islandName in ipairs(ShellIslandOrder) do
                            if not _G.Config.AutoCollectShell then break end
                            if not table.find(islands, islandName) then continue end

                            local targetPos = ShellLocations[islandName]
                            if not targetPos then continue end

                            char = player.Character
                            hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if not hrp then break end

                            pcall(function()
                                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                            end)
                            task.wait(0.5)

                            local shellObj, prompt = findNearestShell(targetPos, 300)

                            if shellObj and prompt then
                                local shellPos = nil
                                pcall(function() shellPos = shellObj:GetPivot().Position end)

                                if shellPos then
                                    pcall(function()
                                        hrp.CFrame = CFrame.new(shellPos + Vector3.new(0, 3, 0))
                                    end)
                                    task.wait(0.3)
                                end

                                pcall(function() fireproximityprompt(prompt) end)
                                task.wait(0.5)
                            end
                        end

                        task.wait(1)
                    end

                    _autoShellRunning = false
                end)
            end

            ExclusiveSection:AddToggle({
                Title = "Auto Collect Shell",
                Content = "Teleport ke tiap island → collect shell jika ada",
                Default = _G.Config.AutoCollectShell or false,
                Callback = function(state)
                    _G.Config.AutoCollectShell = state
                    if state then
                        startAutoCollectShell()
                    end
                end
            })

            local _autoSunkenChest = false
            local SunkenChestLocations = {
                ["Moosewood"] = {
                    Vector3.new(936, 130, -159), Vector3.new(693, 130, -362), Vector3.new(613, 130, 498), Vector3.new(285, 130, 564), Vector3.new(283, 130, -159)
                },
                ["Roslit"] = {
                    Vector3.new(-1179, 130, 565), Vector3.new(-1217, 130, 201), Vector3.new(-1967, 130, 980), Vector3.new(-2444, 130, 266), Vector3.new(-2444, 130, -37)
                },
                ["Sunstone"] = {
                    Vector3.new(-852, 130, -1560), Vector3.new(-1000, 130, -751), Vector3.new(-1500, 130, -750), Vector3.new(-1547, 130, -1080), Vector3.new(-1618, 130, -1560)
                },
                ["Terrapin"] = {
                    Vector3.new(798, 130, 1667), Vector3.new(562, 130, 2455), Vector3.new(393, 130, 2435), Vector3.new(-1, 130, 1632), Vector3.new(-190, 130, 2450)
                },
                ["Mushgrove"] = {
                    Vector3.new(2890, 130, -997), Vector3.new(2729, 130, -1098), Vector3.new(2410, 130, -1110), Vector3.new(2266, 130, -721)
                },
                ["Forsaken"] = {
                    Vector3.new(-2460, 130, 2047)
                }
            }

            local function GetSunkenChestLocationFromMessage(msg)
                local lMsg = string.lower(msg)
                for locName, coords in pairs(SunkenChestLocations) do
                    if string.find(lMsg, string.lower(locName)) then
                        return locName, coords
                    end
                end
                return nil, nil
            end

            local function ClaimSunkenChestAt(locName, coords)
                local player = game.Players.LocalPlayer
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                task.wait(2)

                local chestFound = false
                pcall(function()
                    local activeChestsFolder = workspace:FindFirstChild("world") 
                        and workspace.world:FindFirstChild("ActiveChestsFolder")

                    if activeChestsFolder then
                        for _, chestLocation in ipairs(activeChestsFolder:GetChildren()) do
                            local chestsFolder = chestLocation:FindFirstChild("Chests")
                            if chestsFolder then
                                for _, chestObj in ipairs(chestsFolder:GetChildren()) do
                                    local rootPart = chestObj:FindFirstChild("RootPart")
                                    if rootPart then
                                        local mainObj = rootPart:FindFirstChild("Main")
                                        if mainObj then
                                            local prompt = mainObj:FindFirstChildWhichIsA("ProximityPrompt")
                                            if prompt then
                                                hrp.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
                                                task.wait(1)
                                                fireproximityprompt(prompt)
                                                chestFound = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            if chestFound then break end
                        end
                    end
                end)

                if chestFound then
                    return
                end

                for _, pos in ipairs(coords) do
                    if not _autoSunkenChest then break end

                    char = player.Character
                    hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    pcall(function()
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                    end)
                    task.wait(1)

                    local prompt = nil
                    local searchRoot = workspace:FindFirstChild("world") or workspace
                    for _, obj in ipairs(searchRoot:GetChildren()) do
                        if obj:IsA("ProximityPrompt") then
                            local parent = obj.Parent
                            if parent and parent:IsA("BasePart") then
                                local dist = (parent.Position - hrp.Position).Magnitude
                                if dist <= 50 and (string.find(string.lower(obj.ActionText), "open") or string.find(string.lower(obj.ActionText), "claim") or string.find(string.lower(obj.ObjectText), "chest")) then
                                    prompt = obj
                                    hrp.CFrame = parent.CFrame + Vector3.new(0, 5, 0)
                                    break
                                end
                            end
                        end
                        for _, sub in ipairs(obj:GetChildren()) do
                            if sub:IsA("ProximityPrompt") then
                                local parent = sub.Parent
                                if parent and parent:IsA("BasePart") then
                                    local dist = (parent.Position - hrp.Position).Magnitude
                                    if dist <= 50 and (string.find(string.lower(sub.ActionText), "open") or string.find(string.lower(sub.ActionText), "claim") or string.find(string.lower(sub.ObjectText), "chest")) then
                                        prompt = sub
                                        hrp.CFrame = parent.CFrame + Vector3.new(0, 5, 0)
                                        break
                                    end
                                end
                            end
                        end
                        if prompt then break end
                    end

                    if prompt then
                        task.wait(0.5)
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                        task.wait(1)
                        break
                    end
                end
            end

            local RS = game:GetService("ReplicatedStorage")
            local eventsFolder = RS:WaitForChild("events", 5)
            if eventsFolder then
                local annoTop = eventsFolder:WaitForChild("anno_top", 5)
                if annoTop then
                    annoTop.OnClientEvent:Connect(function(text, icon, extraTime, sound)
                        if not _autoSunkenChest then return end
                        if typeof(text) == "string" and string.find(string.lower(text), "sunken") then
                            local locName, coords = GetSunkenChestLocationFromMessage(text)
                            if locName then
                                task.spawn(ClaimSunkenChestAt, locName, coords)
                            end
                        end
                    end)
                end

                local annoServer = eventsFolder:WaitForChild("anno_serverEvent", 5)
                if annoServer then
                    annoServer.OnClientEvent:Connect(function(text, icon, extraTime, sound)
                        if not _autoSunkenChest then return end
                        if typeof(text) == "string" and string.find(string.lower(text), "sunken") then
                            local locName, coords = GetSunkenChestLocationFromMessage(text)
                            if locName then
                                task.spawn(ClaimSunkenChestAt, locName, coords)
                            end
                        end
                    end)
                end
            end

            ExclusiveSection:AddToggle({
                Title = "Auto Sunken Chest",
                Description = "Listens to announcements & claims sunken chests based on target location",
                Default = false,
                Callback = function(state)
                    _autoSunkenChest = state
                end
            })

end
return Init
