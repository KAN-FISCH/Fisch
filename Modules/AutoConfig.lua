local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)

                ExclusiveSection:AddSeperator({
                    Title = 'Discord Webhook'
                })

                ExclusiveSection:AddToggle({
                    Title = "Enable Discord Webhook",
                    Description = "Send fish caught to Discord",
                    Default = _G.Config.DiscordWebhookEnabled,
                    Callback = function(Value)
                        _G.Config.DiscordWebhookEnabled = Value
                        if Value then
                            print("Discord Webhook: ENABLED")
                        else
                            print("Discord Webhook: DISABLED")
                        end
                    end
                })

                ExclusiveSection:AddInput({
                    Title = "Discord Webhook URL",
                    Default = _G.Config.DiscordWebhookURL or "",
                    Placeholder = "https://discord.com/api/webhooks/...",
                    Callback = function(Value)
                        _G.Config.DiscordWebhookURL = Value
                        print("Discord Webhook URL updated")
                    end
                })

            AutoSaveSection:AddToggle({
                Title = "Auto Teleport on Load",
                Description = "Teleport when loading",
                Default = true,
                Callback = function(Value)
                    _G.Config.AutoTeleportOnLoad = Value
                    print("[Config] Auto TP: " .. (Value and "ON" or "OFF"))
                    updateStatusDisplay()
                end
            })

            AutoSaveSection:AddDropdown({
                Title = "Load Config",
                Description = "Select to load",
                Options = savedConfigsList,
                Default = savedConfigsList[1],
                Callback = function(Value)
                    if Value ~= "No Configs" then
                        loadConfig(Value, _G.Config.AutoTeleportOnLoad)
                        currentConfigFile = Value
                        task.wait(0.2)
                        updateStatusDisplay()
                    end
                end
            })

            customConfigName = ""
            AutoSaveSection:AddInput({
                Title = "Config Name",
                Description = "Enter new name",
                Default = "",
                Placeholder = "MyConfig",
                Callback = function(Value)
                    customConfigName = Value
                end
            })
            AutoSaveSection:AddButton({
                Title = "Save New Config",
                Description = "Create with name above",
                ClipsDescendants = true,
                Callback = function()
                    if customConfigName ~= "" then
                        local cleanName = customConfigName:gsub("[^%w%s-_]", "")
                        saveConfig(cleanName)
                        customConfigName = ""
                    end
                end
            })

            AutoSaveSection:AddButton({
                Title = "Save Current",
                Description = "Update current file",
                ClipsDescendants = true,
                Callback = function()
                    saveConfig(currentConfigFile)
                end
            })

            AutoSaveSection:AddButton({
                Title = "Load + Teleport",
                Description = "Load and TP",
                ClipsDescendants = true,
                Callback = function()
                    loadConfig(currentConfigFile, true)
                end
            })

            AutoSaveSection:AddButton({
                Title = "Load Only",
                Description = "No teleport",
                ClipsDescendants = true,
                Callback = function()
                    loadConfig(currentConfigFile, false)
                end
            })

            AutoSaveSection:AddButton({
                Title = "Teleport Now",
                Description = "Go to saved position",
                ClipsDescendants = true,
                Callback = function()
                    if _G.Config.SavedPosition then
                        teleportToSavedPosition(_G.Config.SavedPosition)
                    else
                        warn("[Config] No position saved!")
                    end
                end
            })

            AutoSaveSection:AddButton({
                Title = "Delete Config",
                Description = "Delete current file",
                ClipsDescendants = true,
                Callback = function()
                        deleteConfig(currentConfigFile)
                end
            })

            AutoSaveSection:AddButton({
                Title = "Refresh Display",
                Description = "Update CONFIG INFO now",
                ClipsDescendants = true,
                Callback = function()
                    print("[Config] Manual refresh triggered")
                    updateStatusDisplay()
                end
            })

            task.spawn(function()
                task.wait(15)

                getSavedConfigsList()

                if #savedConfigsList > 0 and savedConfigsList[1] ~= "No Configs" then
                    loadConfig(savedConfigsList[1], true)
                    task.wait(0.5)
                    updateStatusDisplay()
                end
            end)

            task.spawn(function()
                while true do
                    task.wait(3)
                    updateStatusDisplay()
                end
            end)
        Main = AreaTab:AddSection('Main', true, "Left")
        SAVEPOSTION = AreaTab:AddSection('Save Positon', true, "Right")
        NPCSection = AreaTab:AddSection('NPC Teleport', true, "Left")
        BallonSection = AreaTab:AddSection('Ballon', false, "Right")

        _G.cachedNpcLocations = _G.cachedNpcLocations or {}
        cachedNpcLocations = _G.cachedNpcLocations
        knownLocations = {
            ["Angler (Moosewood)"] = CFrame.new(481, 151, 299),
            ["Angler (Roslit)"] = CFrame.new(-1512, 140, 688),
            ["Angler (Sunstone)"] = CFrame.new(-885, 135, -1115),
            ["Angler (Terrapin)"] = CFrame.new(-153, 144, 1954),
            ["Angler (Depths)"] = CFrame.new(980, -700, 1230),
            ["Angler (Ancient)"] = CFrame.new(5737, 177, -57),
            ["Angler (Forsaken)"] = CFrame.new(-2702, 169, 1798),
            ["Angler (Crimson)"] = CFrame.new(-1069, -361, -4811),
            ["Angler (Luminescent)"] = CFrame.new(-1050, -337, -4078),
            ["Angler (Jungle)"] = CFrame.new(-2726, 226, -2186),
            ["Merlin"] = CFrame.new(-929, 224, -996),
            ["Pierre"] = CFrame.new(387, 133, 258),
            ["Halt"] = CFrame.new(-1319, 133, 412),
            ["Appraiser (Roslit)"] = CFrame.new(-1644, 137, 727),
            ["Appraiser (Moosewood)"] = CFrame.new(446, 150, 230),
            ["Appraiser (Terrapin)"] = CFrame.new(-109, 157, 1956),
        }
        for n, c in pairs(knownLocations) do
            cachedNpcLocations[n] = c
        end

        function cacheCurrentNpcs()
            if workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") then
                for _, npc in pairs(workspace.world.npcs:GetChildren()) do
                    if npc:IsA("Model") then
                        root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                        if root then
                            cachedNpcLocations[npc.Name] = root.CFrame
                        end
                    end
                end
            end
        end

        if workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") then
            workspace.world.npcs.ChildAdded:Connect(function(child)
                task.wait(1) 
                if child:IsA("Model") then
                    root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head") or child.PrimaryPart
                    if root then
                        cachedNpcLocations[child.Name] = root.CFrame

                        if updateNpcList and NpcDropdown then
                            updateNpcList()
                            if NpcDropdown.SetValues then
                                NpcDropdown:SetValues(npcNames)
                            elseif NpcDropdown.SetOptions then
                                NpcDropdown:SetOptions(npcNames)
                            end
                        end
                    end
                end
            end)
        end

        npcNames = {}
        function updateNpcList()
            cacheCurrentNpcs()
            npcNames = {}
            for name, _ in pairs(cachedNpcLocations) do
                table.insert(npcNames, name)
            end
            table.sort(npcNames)
        end
        updateNpcList()

end
return Init
