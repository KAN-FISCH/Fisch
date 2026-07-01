local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Helper getMod loader (no script dependency)
local function getMod(name)
    if _G.getMod then return _G.getMod(name) end
    local core = game:GetService("ReplicatedStorage"):FindFirstChild("Shield_Core")
    if core then
        local folder = core:FindFirstChild(name)
        if folder then
            if folder:IsA("Folder") then
                local src = ""
                for i = 1, #folder:GetChildren() do
                    local chunk = folder:FindFirstChild(tostring(i))
                    if chunk then src = src .. chunk.Value end
                end
                return loadstring(src)()
            else
                return loadstring(folder.Value)()
            end
        end
    end
    return nil
end

local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
    -- ESP Toggles
    local ESP = getMod("ESP")
    if ESP then
        EspCharacterSection:AddToggle({
            Title = "ESP Player",
            Default = false,
            Callback = function(value)
                ESP.SetEspPlayers(value)
            end
        })
        EspEventSection:AddToggle({
            Title = "ESP Zone",
            Default = false,
            Callback = function(value)
                ESP.SetEspZone(value)
            end
        })
        EspNpcSection:AddToggle({
            Title = "ESP NPC",
            Default = false,
            Callback = function(value)
                ESP.SetEspNpc(value)
            end
        })
    end

    -- Auto Potion
    local AutoPotion = getMod("AutoPotion")
    if AutoPotion then
        ExclusiveSection:AddDropdown({
            Title = "Select Potions",
            Options = AutoPotion.GetPotionList(),
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
        ExclusiveSection:AddToggle({
            Title = "Auto Potion",
            Default = _G.Config.AutoPotionEnabled or false,
            Callback = function(isEnabled)
                _G.Config.AutoPotionEnabled = isEnabled
                if isEnabled then
                    AutoPotion.StartLoop()
                else
                    AutoPotion.StopLoop()
                end
            end,
        })
    end

    -- Spear Exploit
    ExclusiveSection:AddToggle({
        Title = "Spear Exploits",
        Description = "Spear Fishing Minigame Exploit",
        Default = _G.Config.DupeFischToggle or false,
        Callback = function(value)
            _G.Config.DupeFischToggle = value
            if value then
                task.spawn(function()
                    local remote = ReplicatedStorage:WaitForChild('packages')
                        :WaitForChild('Net')
                        :WaitForChild('RE/SpearFishing/Minigame')
                    local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
                    local hrp = char:WaitForChild('HumanoidRootPart')
                    local oldCF = hrp.CFrame
                    local locations = {
                        CFrame.new(-2831, 129, -2146),
                        CFrame.new(2602, -1112, 837),
                        CFrame.new(3077, -1116, 794),
                        CFrame.new(3076, -1144, 1718),
                        CFrame.new(3069, -1144, 2108)
                    }
                    if _G.ClonedSpearStorage then _G.ClonedSpearStorage:Destroy() end
                    _G.ClonedSpearStorage = Instance.new("Folder")
                    _G.ClonedSpearStorage.Name = "ClonedSpearStorage"
                    _G.ClonedSpearStorage.Parent = ReplicatedStorage

                    for _, loc in ipairs(locations) do
                        if not _G.Config.DupeFischToggle then break end
                        hrp.CFrame = loc
                        task.wait(4)
                        local targetFolder = nil
                        for i = 1, 10 do 
                            for _, v in ipairs(workspace:GetChildren()) do
                                if v.Name == 'Spearfishing Water' and #v:GetChildren() > 0 then
                                    targetFolder = v
                                    break
                                end
                            end
                            if targetFolder then break end
                            task.wait(0.5)
                        end
                        if targetFolder then
                            for _, zone in ipairs(targetFolder:GetChildren()) do
                                if zone:FindFirstChild("ZoneFish") and #zone.ZoneFish:GetChildren() > 0 then
                                    local zoneClone = zone:Clone()
                                    zoneClone.Parent = _G.ClonedSpearStorage
                                end
                            end
                        end
                    end

                    hrp.CFrame = oldCF
                    for _, v in ipairs(workspace:GetChildren()) do
                        if v.Name == 'Spearfishing Water' and #v:GetChildren() == 0 then
                            v:Destroy()
                        end
                    end

                    while _G.Config.DupeFischToggle do
                        if not _G.ClonedSpearStorage or #_G.ClonedSpearStorage:GetChildren() == 0 then break end
                        for _, zone in ipairs(_G.ClonedSpearStorage:GetChildren()) do
                            local zoneFish = zone:FindFirstChild('ZoneFish')
                            if zoneFish then
                                for _, fish in ipairs(zoneFish:GetChildren()) do
                                    local uid = fish:GetAttribute('UID')
                                    if uid then
                                        remote:FireServer(uid)
                                        task.wait()
                                        remote:FireServer(uid, true)
                                    end
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    -- Balance Nuke
    ExclusiveSection:AddToggle({
        Title = "Balance Nuke",
        Description = "Auto completes Love Nuke and Atomic Nuke minigames",
        Default = _G.Config.AutoNukeEnabled or false,
        Callback = function(Value)
            _G.Config.AutoNukeEnabled = Value
            if Value then
                task.spawn(function()
                    while _G.Config.AutoNukeEnabled do
                        task.wait(0.5)
                        pcall(function()
                            local nukeGui, pointer, leftBtn, rightBtn
                            for _, desc in pairs(game:GetDescendants()) do
                                if desc.Name == "NukeMinigame" and desc:IsA("ScreenGui") then
                                    nukeGui = desc
                                    pointer = nukeGui.Center.Marker.Pointer.Frame
                                    leftBtn = nukeGui.Center.Left
                                    rightBtn = nukeGui.Center.Right
                                    break
                                end
                            end
                            if nukeGui and pointer and leftBtn and rightBtn and nukeGui.Enabled then
                                local function pressButton(button)
                                    if getconnections then
                                        for _, connection in pairs(getconnections(button.Activated)) do
                                            connection:Fire({ UserInputType = Enum.UserInputType.Keyboard })
                                        end
                                    end
                                end
                                local rot = pointer.AbsoluteRotation
                                if rot < -35 then
                                    pressButton(rightBtn)
                                elseif rot > 35 then
                                    pressButton(leftBtn)
                                end
                            end
                        end)
                    end
                end)
            end
        end
    })

    -- Volley minigames (AutoMine)
    AutoMineSection:AddDropdown({
        Title = "Volley Mode (Farm)",
        Description = "Win = Teleport & Pukul | Lose = Diam saja (Farm Kalah Cepat)",
        Options = {"Win", "Lose"},
        Default = _G.Config.VolleyMode or "Win",
        Callback = function(Value)
            _G.Config.VolleyMode = Value
        end
    })
    AutoMineSection:AddDropdown({
        Title = "Select Court Side",
        Description = "Pilih sisi lapangan untuk Auto Join",
        Options = {"Side 1", "Side 2"},
        Default = _G.Config.VolleySide or "Side 1",
        Callback = function(Value)
            _G.Config.VolleySide = Value
        end
    })
    AutoMineSection:AddSlider({
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
    AutoMineSection:AddToggle({
        Title = "Auto Join Volley",
        Description = "Otomatis teleport & join lapangan yang dipilih saat tidak bermain",
        Default = _G.Config.AutoJoinVolley or false,
        Callback = function(state)
            _G.Config.AutoJoinVolley = state
        end
    })
    AutoMineSection:AddToggle({
        Title = "Auto Volley",
        Description = "Master Toggle untuk menyalakan fitur Voli Pantai (Beach Volleyball)",
        Default = _G.Config.AutoVolley or false,
        Callback = function(state)
            _G.Config.AutoVolley = state
            if state then
                local AutoMine = getMod("AutoMine")
                if AutoMine then AutoMine.Start() end
            end
        end
    })

    -- Config Saver (AutoSaveSection)
    local HttpService = game:GetService("HttpService")
    local configFolder = "ExclusiveConfigs/"
    local function getConfigs()
        local list = {"Default"}
        if isfolder and isfolder(configFolder) and listfiles then
            for _, file in ipairs(listfiles(configFolder)) do
                local name = file:match("([^/\\%.]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
        return list
    end
    local selectedConfig = "Default"
    local configDropdown

    local function refreshConfigs()
        if configDropdown then
            local list = getConfigs()
            pcall(function() configDropdown:SetValues(list) end)
        end
    end

    AutoSaveSection:AddInput({
        Title = "Config Name",
        Default = "Default",
        Callback = function(val)
            selectedConfig = val
        end
    })
    configDropdown = AutoSaveSection:AddDropdown({
        Title = "Saved Configs",
        Options = getConfigs(),
        Default = "Default",
        Callback = function(val)
            selectedConfig = val
        end
    })
    AutoSaveSection:AddButton({
        Title = "Save Config",
        Callback = function()
            if not isfolder(configFolder) then makefolder(configFolder) end
            writefile(configFolder .. selectedConfig .. ".json", HttpService:JSONEncode(_G.Config))
            refreshConfigs()
        end
    })
    AutoSaveSection:AddButton({
        Title = "Load Config",
        Callback = function()
            local path = configFolder .. selectedConfig .. ".json"
            if isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                if type(data) == "table" then
                    for k, v in pairs(data) do
                        _G.Config[k] = v
                    end
                    print("Config loaded:", selectedConfig)
                end
            end
        end
    })
    AutoSaveSection:AddButton({
        Title = "Delete Config",
        Callback = function()
            local path = configFolder .. selectedConfig .. ".json"
            if isfile(path) then
                delfile(path)
                refreshConfigs()
            end
        end
    })

    -- NPC & Balloon Teleport Sections
    local TeleportNPC = getMod("TeleportNPC")
    if TeleportNPC then
        NPCSection:AddDropdown({
            Title = "TP Area",
            Options = TeleportNPC.GetTpSpotList(),
            Default = "None",
            Callback = function(selected)
                TeleportNPC.TeleportTo(selected)
            end
        })
        local tpCoord = nil
        NPCSection:AddInput({
            Title = "Teleport Coordinate",
            Default = "",
            Callback = function(val)
                if val and val ~= "" then
                    local numbers = {}
                    for num in string.gmatch(val, "[-%d%.]+") do
                        table.insert(numbers, tonumber(num))
                    end
                    if #numbers >= 3 then
                        tpCoord = Vector3.new(numbers[1], numbers[2], numbers[3])
                    end
                end
            end
        })
        NPCSection:AddButton({
            Title = "Teleport",
            Callback = function()
                if tpCoord then
                    TeleportNPC.TeleportToCoords(tpCoord.X, tpCoord.Y, tpCoord.Z)
                end
            end
        })
        local selectedPlayer = "None"
        local function getPlayerNames()
            local names = {"None"}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer then table.insert(names, p.Name) end
            end
            return names
        end
        local playerDropdown = NPCSection:AddDropdown({
            Title = "Teleport Player",
            Options = getPlayerNames(),
            Default = "None",
            Callback = function(selected)
                selectedPlayer = selected
            end
        })
        NPCSection:AddButton({
            Title = "Teleport ke Pemain",
            Callback = function()
                if selectedPlayer ~= "None" then
                    local targetPlayer = Players:FindFirstChild(selectedPlayer)
                    if targetPlayer and targetPlayer.Character then
                        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myHrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and myHrp then
                            myHrp.CFrame = hrp.CFrame + Vector3.new(3, 1, 0)
                        end
                    end
                end
            end
        })
        
        -- Balloon Teleports
        for i, spot in ipairs(TeleportNPC.BalloonSpots) do
            BallonSection:AddButton({
                Title = "Teleport ke " .. spot.name,
                Callback = function()
                    TeleportNPC.TeleportToBalloon(i)
                end
            })
        end
    end
end

return Init
