local function InitExclusive(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
        ExclusiveSection:AddSeperator({
                Title = 'Auto Cosmic'
            })

            ExclusiveSection:AddToggle({
                Title = "Auto Claim Multi Items",
                Description = "Claim Lunar, Starfall, Cosmic",
                Default = _G.Config.AutoClaimMulti,
                Callback = function(Value)
                    _G.Config.AutoClaimMulti = Value
                    if Value then
                        startAutoClaimMulti()
                    else
                        print("Auto Claim Multi Items: DISABLED")
                    end
                end
            })

            AutoMineSection:AddToggle({
                Title = "Auto Mine Dripstone",
                Default = _G.Config.AutoMineDripstone or false,
                Callback = function(Value)
                    _G.Config.AutoMineDripstone = Value
                    isAutoMineDripstone = Value

                    if isAutoMineDripstone then
                        task.spawn(function()
                            function getCharacter()
                                player = game.Players.LocalPlayer
                                return player.Character or player.CharacterAdded:Wait()
                            end
                            char = getCharacter()
                            root = char and char:FindFirstChild("HumanoidRootPart")

                            if root then
                                for _, part in pairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.CanCollide = false
                                    end
                                end
                                root.CFrame = CFrame.new(4365, -1100, 923)
                                root.Velocity = Vector3.zero
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero

                                task.wait(0.5)
                            end

                            dripstoneCache = {}
                            lastDripCacheTime = 0
                            function refreshDripCache()
                                dripstoneCache = {}
                                function scanForDrip(parent, depth)
                                    if depth > 4 then return end
                                    for _, v in ipairs(parent:GetChildren()) do
                                        if v:IsA("BasePart") and v.Name:match("DripstoneMineable") then
                                            table.insert(dripstoneCache, v)
                                        elseif v:IsA("Model") or v:IsA("Folder") then
                                            scanForDrip(v, depth + 1)
                                        end
                                    end
                                end
                                worldFolder = workspace:FindFirstChild("world")
                                if worldFolder then scanForDrip(worldFolder, 0) end
                                lastDripCacheTime = tick()
                            end
                            refreshDripCache()

                            while isAutoMineDripstone do
                                char = getCharacter()
                                root = char and char:FindFirstChild("HumanoidRootPart")

                                if tick() - lastDripCacheTime > 15 then
                                    refreshDripCache()
                                end

                                if root then
                                    nearest = nil
                                    minDst = math.huge

                                    for i = #dripstoneCache, 1, -1 do
                                        desc = dripstoneCache[i]
                                        if not desc or not desc.Parent then
                                            table.remove(dripstoneCache, i)
                                        else
                                            health = desc:GetAttribute("Health")
                                            if health and health > 0 then
                                                dist = (desc.Position - root.Position).Magnitude
                                                if dist < minDst then
                                                    minDst = dist
                                                    nearest = desc
                                                end
                                            end
                                        end
                                    end

                                    if nearest then
                                        player = game.Players.LocalPlayer
                                        humanoid = char:FindFirstChild("Humanoid")
                                        pickaxe = player.Backpack:FindFirstChild("Pickaxe") or char:FindFirstChild("Pickaxe")

                                        if pickaxe and pickaxe.Parent == player.Backpack and humanoid then
                                            humanoid:EquipTool(pickaxe)
                                            task.wait(0.1)
                                        end
                                        local dripPos = nearest.Position
                                        local targetCFrame = CFrame.new(dripPos + Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                                        for _, part in pairs(char:GetDescendants()) do
                                            if part:IsA("BasePart") then
                                                part.CanCollide = false
                                            end
                                        end
                                        if workspace.CurrentCamera then
                                            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                                            workspace.CurrentCamera.CameraSubject = nearest
                                        end
                                        root.CFrame = targetCFrame
                                        root.Velocity = Vector3.zero
                                        root.AssemblyLinearVelocity = Vector3.zero
                                        root.AssemblyAngularVelocity = Vector3.zero
                                        repeat
                                            task.wait()
                                            if root and nearest and nearest.Parent then
                                                local dripPos = nearest.Position
                                                for _, part in pairs(char:GetDescendants()) do
                                                    if part:IsA("BasePart") then
                                                        part.CanCollide = false
                                                    end
                                                end
                                                local mineCFrame = CFrame.new(dripPos + Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                                                root.CFrame = mineCFrame
                                                root.Velocity = Vector3.zero
                                                local pickaxe = char:FindFirstChild("Pickaxe")
                                                if pickaxe and pickaxe:IsA("Tool") then
                                                    pickaxe:Activate()
                                                end

                                                local health = nearest:GetAttribute("Health")
                                                if not health or health <= 0 then break end
                                            else
                                                break
                                            end
                                        until (not isAutoMineDripstone)
                                    end
                                end
                                task.wait(0.1)
                            end
                            if workspace.CurrentCamera then
                                local player = game.Players.LocalPlayer
                                char = player.Character
                                local humanoid = char and char:FindFirstChild("Humanoid")
                                if humanoid then
                                    workspace.CurrentCamera.CameraSubject = humanoid
                                end
                            end
                        end)
                    end
                end
            })

            task.spawn(function()
                task.wait(1)
                if _G.Config.AutoStorageEnabled and type(startAutoStorageLoop) == "function" then
                    startAutoStorageLoop()
                end
                if _G.Config.AutoClaimMulti and type(startAutoClaimMulti) == "function" then
                    startAutoClaimMulti()
                end
                if _G.Config.DeleteAnimation then
                    task.spawn(function() FreazeChar(true) end)
                end
            end)

            local API_URL_HOP = "https://key.shieldteam.asia/api/key/weebhooks"
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")
            local request = (syn and syn.request) or (http and http.request) or request

            local autoHopEnabled = false
            local targetHopEvents = {}
            local isHopping = false

            local function parseHopData(apiResponse)
                local parsed = {}
                local success, err = pcall(function()
                    if not apiResponse or type(apiResponse) ~= "table" then return end
                    if not apiResponse.rows or type(apiResponse.rows) ~= "table" then return end

                    for idx = 1, math.min(#apiResponse.rows, 50) do
                        local row = apiResponse.rows[idx]
                        if not row or not row.payload or not row.payload.embeds then continue end

                        local embeds = row.payload.embeds
                        if type(embeds) ~= "table" or #embeds == 0 then continue end
                        local embed = embeds[1]
                        if not embed then continue end

                        local serverData = { event = "No Events", jobId = nil, placeId = game.PlaceId, playerCount = 0, maxPlayers = 20 }

                        if embed.description then
                            local desc = tostring(embed.description)
                            local jobMatch = desc:match("`([a-f0-9%-]+)`")
                            if jobMatch and #jobMatch >= 36 then
                                serverData.jobId = jobMatch
                            end
                        end

                        if serverData.jobId then
                            local fields = embed.fields or {}
                            for _, field in ipairs(fields) do
                                if field and field.name then
                                    local name = tostring(field.name)
                                    local value = tostring(field.value)

                                    if name:find("Active Events") then
                                        local zones = value
                                        zones = zones:match("```(.-)```") or zones
                                        zones = zones:gsub("^[,%s]+", ""):gsub("%s+$", "")
                                        if zones:find("No active") or zones:find("❌") or zones == "" then
                                            serverData.event = "No Events"
                                        else
                                            serverData.event = zones
                                        end
                                    elseif name:find("Players") then
                                        local pMatch = value:match("(%d+)%s*/%s*(%d+)")
                                        if pMatch then
                                            local current, max = value:match("(%d+)%s*/%s*(%d+)")
                                            serverData.playerCount = tonumber(current) or 0
                                            serverData.maxPlayers = tonumber(max) or 20
                                        end
                                    elseif name:find("Cosmic Relics") then
                                        local relics = value:match("```(%d+)```")
                                        if relics then
                                            serverData.relics = tonumber(relics)
                                        else
                                            serverData.relics = 0
                                        end
                                    end
                                end
                            end
                            table.insert(parsed, serverData)
                        end
                    end
                end)
                return parsed
            end

            local function fetchHopServers()
                if not request then return {} end
                local success, response = pcall(function()
                    return request({
                        Url = API_URL_HOP,
                        Method = "GET",
                        Headers = { ["Content-Type"] = "application/json" }
                    })
                end)

                if success and response and response.StatusCode == 200 then
                    local decodeSuccess, decoded = pcall(function()
                        return HttpService:JSONDecode(response.Body)
                    end)
                    if decodeSuccess then
                        return parseHopData(decoded)
                    end
                end
                return {}
            end

            local function CheckCurrentServer()
                if not workspace:FindFirstChild("zones") or not workspace.zones:FindFirstChild("fishing") then return false end
                local zones = workspace.zones.fishing

                for k, v in pairs(targetHopEvents) do
                    local targetName = ""
                    if type(k) == "number" and type(v) == "string" then targetName = v
                    elseif type(k) == "string" and v == true then targetName = k end

                    if targetName == "Cosmic Relic" then
                        for _, child in ipairs(workspace:GetChildren()) do
                            if child.Name == "StarCrater" and child:FindFirstChild("Root") and child.Root:FindFirstChild("Cosmic Relic") then
                                return true, "Cosmic Relic"
                            end
                        end
                    elseif targetName ~= "" and zones:FindFirstChild(targetName) then
                        return true, targetName
                    end
                end
                return false
            end

            blacklistedServers = {}
            currentHopNotification = nil
            hopNotificationTask = nil

            function createHopNotification(titleText, statusText, statusColor)
                playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                local screenGui = playerGui:FindFirstChild("HopNotificationUI")
                if not screenGui then
                    screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "HopNotificationUI"
                    screenGui.Parent = playerGui
                    screenGui.ResetOnSpawn = false
                end

                if currentHopNotification and currentHopNotification.Parent then
                    if hopNotificationTask then task.cancel(hopNotificationTask) end
                    currentHopNotification:Destroy()
                    currentHopNotification = nil
                end

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 200, 0, 50)
                frame.Position = UDim2.new(0, -260, 0.7, 0)
                frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                frame.BackgroundTransparency = 0.1
                frame.BorderSizePixel = 0
                frame.Parent = screenGui

                currentHopNotification = frame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 12)
                corner.Parent = frame

                local stroke = Instance.new("UIStroke")
                stroke.Thickness = 1.2
                stroke.Color = Color3.fromRGB(80, 80, 80)
                stroke.Transparency = 0.6
                stroke.Parent = frame

                local function createDot(color, position)
                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.new(0, 8, 0, 8)
                    dot.Position = position
                    dot.BackgroundColor3 = color
                    dot.BorderSizePixel = 0
                    dot.Parent = frame
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = dot
                end

                createDot(Color3.fromRGB(255, 95, 87), UDim2.new(0, 8, 0, 6))
                createDot(Color3.fromRGB(255, 189, 46), UDim2.new(0, 20, 0, 6))
                createDot(Color3.fromRGB(40, 201, 64), UDim2.new(0, 32, 0, 6))

                local icon = Instance.new("ImageLabel")
                icon.Size = UDim2.new(0, 24, 0, 24)
                icon.Position = UDim2.new(0, 12, 0.5, 0)
                icon.BackgroundTransparency = 1
                icon.Image = "rbxassetid://6034509923" -- Globe Icon
                icon.ImageColor3 = statusColor or Color3.fromRGB(200, 200, 200)
                icon.Parent = frame

                local titleVal = Instance.new("TextLabel")
                titleVal.Text = titleText
                titleVal.Size = UDim2.new(1, -50, 0, 14)
                titleVal.Position = UDim2.new(0, 46, 0, 14)
                titleVal.BackgroundTransparency = 1
                titleVal.Font = Enum.Font.GothamBold
                titleVal.TextColor3 = Color3.fromRGB(240, 240, 240)
                titleVal.TextSize = 10
                titleVal.TextXAlignment = Enum.TextXAlignment.Left
                titleVal.Parent = frame

                local subtitle = Instance.new("TextLabel")
                subtitle.Text = statusText
                subtitle.Size = UDim2.new(1, -50, 0, 12)
                subtitle.Position = UDim2.new(0, 46, 0, 30)
                subtitle.BackgroundTransparency = 1
                subtitle.Font = Enum.Font.GothamMedium
                subtitle.TextColor3 = statusColor or Color3.fromRGB(180, 180, 180)
                subtitle.TextSize = 9
                subtitle.TextXAlignment = Enum.TextXAlignment.Left
                subtitle.TextTruncate = Enum.TextTruncate.AtEnd
                subtitle.Parent = frame

                game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 20, 0.7, 0)
                }):Play()

                hopNotificationTask = task.delay(4, function()
                    if currentHopNotification == frame then
                        local tw = game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                            Position = UDim2.new(0, -260, 0.7, 0),
                            BackgroundTransparency = 1
                        })
                        tw:Play()
                        tw.Completed:Wait()
                        if currentHopNotification == frame then
                            frame:Destroy()
                            currentHopNotification = nil
                        end
                    end
                end)
            end

            local function StartAutoHop()
                if isHopping then return end
                isHopping = true

                local currentTargetJobId = nil
                local failed = false

                local connection
                connection = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
                    if player == game.Players.LocalPlayer then
                        createHopNotification("Teleport Failed", "Error: " .. tostring(errorMessage), Color3.fromRGB(255, 80, 80))

                        if currentTargetJobId then
                            blacklistedServers[currentTargetJobId] = true
                        end
                        failed = true
                    end
                end)

                while autoHopEnabled do
                    local found, eventName = CheckCurrentServer()
                    if found then
                        createHopNotification("Event Found!", "Stay here! " .. tostring(eventName), Color3.fromRGB(80, 255, 100))
                        autoHopEnabled = false
                        isHopping = false
                        if connection then connection:Disconnect() end
                        break 
                    end

                    createHopNotification("Auto Hop", "Scanning servers...", Color3.fromRGB(255, 200, 50))
                    local servers = fetchHopServers()
                    local targetServer = nil

                    for _, srv in ipairs(servers) do
                        if blacklistedServers[srv.jobId] then
                            continue
                        end

                        if srv.maxPlayers - srv.playerCount < 1 then
                            continue 
                        end

                        for k, v in pairs(targetHopEvents) do
                            local targetName = ""
                            if type(k) == "number" and type(v) == "string" then targetName = v
                            elseif type(k) == "string" and v == true then targetName = k end

                        if targetName ~= "" then
                                if srv.event then
                                    for serverEvent in string.gmatch(srv.event, "([^,]+)") do
                                        serverEvent = serverEvent:gsub("^%s+", ""):gsub("%s+$", "")
                                        if serverEvent:lower() == targetName:lower() then
                                            targetServer = srv
                                            break
                                        end
                                    end
                                    if targetServer then break end
                                end
                            end
                        end
                        if targetServer then break end
                    end

                    if targetServer then
                        createHopNotification("Server Found!", "Joining " .. targetServer.event, Color3.fromRGB(0, 170, 255))

                        currentTargetJobId = targetServer.jobId

                        failed = false
                        TeleportService:TeleportToPlaceInstance(targetServer.placeId, targetServer.jobId, game.Players.LocalPlayer)

                        local startWait = tick()
                        repeat 
                            task.wait(0.5)
                        until failed or tick() - startWait > 8

                        if failed then
                            createHopNotification("Failed", "Retrying search...", Color3.fromRGB(255, 100, 100))
                        else
                            createHopNotification("Status", "Teleport timeout...", Color3.fromRGB(255, 150, 50))
                            blacklistedServers[currentTargetJobId] = true
                        end
                    else
                        createHopNotification("Not Found", "Retrying in 5s...", Color3.fromRGB(150, 150, 150))
                        task.wait(5)
                    end
                end

                if connection then connection:Disconnect() end
                isHopping = false
            end

            local lastBlacklistClear = tick()

            local function setupErrorPromptRemover()
                local CoreGui = game:GetService("CoreGui")
                local Lighting = game:GetService("Lighting")
                local ReplicatedFirst = game:GetService("ReplicatedFirst")

                pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

                if not _G._LightingBlurConn then
                    _G._LightingBlurConn = Lighting.ChildAdded:Connect(function(child)
                        if _G.Config.AutoHopCosmic and (child:IsA("BlurEffect") or child.Name:lower():find("blur")) then
                            task.defer(function()
                                if child.Parent then
                                    child.Enabled = false
                                    child:Destroy()
                                end
                            end)
                        end
                    end)
                end

                if not _G._CameraBlurConn then
                    _G._CameraBlurConn = workspace.CurrentCamera.ChildAdded:Connect(function(child)
                        if _G.Config.AutoHopCosmic and (child:IsA("BlurEffect") or child.Name:lower():find("blur")) then
                            task.defer(function()
                                if child.Parent then
                                    child.Enabled = false
                                    child:Destroy()
                                end
                            end)
                        end
                    end)
                end

                task.spawn(function()
                    while _G.Config.AutoHopCosmic do
                        pcall(function()
                            local targets = {Lighting, workspace.CurrentCamera}
                            for _, parent in ipairs(targets) do
                                for _, v in pairs(parent:GetChildren()) do
                                    if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                                        v.Enabled = false
                                        v:Destroy()
                                    end
                                end
                            end

                            local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
                            if promptGui and promptGui:FindFirstChild("promptOverlay") then
                                for _, child in ipairs(promptGui.promptOverlay:GetChildren()) do
                                    if child.Name == "ErrorPrompt" then
                                        child:Destroy()
                                    end
                                end
                            end

                            for _, gui in ipairs(CoreGui:GetChildren()) do
                                if gui:IsA("ScreenGui") and gui.Enabled then
                                    local name = gui.Name
                                    if name == "RobloxGui" or name == "CoreScripts" or name == "TopBar" or 
                                    name == "TouchGui" or name == "InGameMenu" or name == "Chat" or
                                    name:find("Shield") or name:find("Than") or name:find("Fluent") or name:find("ScreenGui") then 
                                        continue 
                                    end
                                    local lowerName = name:lower()
                                    if lowerName:find("loading") or lowerName:find("teleport") or lowerName:find("black") then
                                        gui:Destroy()
                                    end
                                end
                            end
                        end)
                        task.wait(2)
                    end
                end)
            end

            local function unlockControls()
                pcall(function()
                    local Player = game.Players.LocalPlayer
                    local PlayerModule = Player.PlayerScripts:FindFirstChild("PlayerModule")
                    if PlayerModule then
                        require(PlayerModule):GetControls():Enable()
                    end

                    Player.CameraMode = Enum.CameraMode.Classic
                    Player.Character.Humanoid.PlatformStand = false
                    game:GetService("UserInputService").ModalEnabled = false
                    game:GetService("GuiService").SelectedObject = nil
                end)
            end

            local function StartAutoHopCosmic()
                if isHopping then return end
                isHopping = true

                setupErrorPromptRemover()

                local currentTargetJobId = nil
                local failed = false

                local function fetchSmartServers()
                    local HttpService = game:GetService("HttpService")
                    local API_URL = "https://key.shieldteam.asia/api/key/weebhooks"

                    print("[Auto Hop] 📡 Fetching servers from API Webhook...")
                    local success, result = pcall(function()
                        return game:HttpGet(API_URL)
                    end)

                    local parsedServers = {}
                    if success then
                        local data = HttpService:JSONDecode(result)

                        if data and data.rows and type(data.rows) == "table" then
                            for _, row in ipairs(data.rows) do
                                if not row.payload or not row.payload.embeds then continue end

                                local embed = row.payload.embeds[1]
                                if not embed then continue end

                                local serverData = {
                                    jobId = nil,
                                    placeId = game.PlaceId,
                                    relics = 0,
                                    event = "No Events",
                                    playerCount = 0,
                                    maxPlayers = 20
                                }

                                if embed.description then
                                    local desc = tostring(embed.description)
                                    local jobMatch = desc:match("`([a-f0-9%-]+)`")
                                    if jobMatch and #jobMatch >= 36 then
                                        serverData.jobId = jobMatch
                                    end
                                end

                                if embed.fields then
                                    for _, field in ipairs(embed.fields) do
                                        local name = tostring(field.name)
                                        local value = tostring(field.value)

                                        if name:find("Active Events") then
                                            local zones = value:match("```(.-)```") or value
                                            zones = zones:gsub("^[,%s]+", ""):gsub("%s+$", "")
                                            if zones:find("No active") or zones:find("❌") or zones == "" then
                                                serverData.event = "No Events"
                                            else
                                                serverData.event = zones
                                            end
                                        elseif name:find("Cosmic Relics") then
                                            serverData.relics = tonumber(value:match("%d+")) or 0
                                        elseif name:find("Players") then
                                            local match = value:match("```(.-)```")
                                            if match then
                                                local curr, max = match:match("(%d+)%s*/%s*(%d+)")
                                                if curr then
                                                    serverData.playerCount = tonumber(curr) or 0
                                                    serverData.maxPlayers = tonumber(max) or 20
                                                end
                                            end
                                        elseif name:find("Place ID") or name:find("Server Info") then
                                            local match = value:match("(%d+)")
                                            if match then serverData.placeId = tonumber(match) end
                                        end
                                    end
                                end

                                if serverData.jobId then
                                    table.insert(parsedServers, serverData)
                                end
                            end
                        end
                    else
                        warn("[Auto Hop] ❌ API Fetch Failed:", result)
                    end

                    return parsedServers
                end

                local connection
                connection = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
                    if player == game.Players.LocalPlayer then
                        createHopNotification("Teleport Failed", "Error: " .. tostring(errorMessage), Color3.fromRGB(255, 80, 80))

                        unlockControls()

                        if currentTargetJobId then
                            blacklistedServers[currentTargetJobId] = true
                        end
                        failed = true
                    end
                end)

                while _G.Config.AutoHopCosmic do
                    if tick() - lastBlacklistClear > 1800 then
                        blacklistedServers = {}
                        lastBlacklistClear = tick()
                        createHopNotification("Blacklist Cleared", "Reset blacklist cache", Color3.fromRGB(100, 200, 255))
                    end

                    local foundCosmic = false
                    local function hasCosmic(parent, depth)
                        if depth > 10 then return false end
                        for _, child in ipairs(parent:GetChildren()) do
                            if child.Name == "Cosmic Relic" or child.Name == "Starfall Totem" or child.Name == "Lunar Thread" then
                                local prompt = nil
                                local center = child:FindFirstChild("Center")
                                if center then prompt = center:FindFirstChildWhichIsA("ProximityPrompt") end
                                if not prompt then prompt = child:FindFirstChildWhichIsA("ProximityPrompt") end
                                if prompt and prompt.Enabled then return true end
                            end
                            if child:IsA("Folder") or child:IsA("Model") or child.Name == "StarCrater" or child.Name == "Root" then
                                if hasCosmic(child, depth + 1) then return true end
                            end
                        end
                        return false
                    end
                    foundCosmic = hasCosmic(workspace, 0)

                    if foundCosmic then
                        createHopNotification("Farming Cosmic", "Waiting for relics to deplete...", Color3.fromRGB(80, 255, 100))
                        task.wait(3)
                        continue
                    end

                    if not foundCosmic then
                        createHopNotification("Cosmic Hop", "Fetching API Servers...", Color3.fromRGB(155, 89, 182))

                        local servers = fetchSmartServers()
                        local targetServer = nil
                        local validCosmicCount = 0

                        for _, srv in ipairs(servers) do
                            local jobId = srv.jobId
                            local placeId = srv.placeId 

                            local playerCount = srv.playerCount or 0
                            local maxPlayers = srv.maxPlayers or 20
                            local eventList = srv.event or ""

                            if not jobId or not placeId then 
                                continue 
                            end

                            if blacklistedServers[jobId] then 
                                continue 
                            end

                            if maxPlayers - playerCount < 2 then 
                                blacklistedServers[jobId] = true
                                continue 
                            end

                            local isCosmic = false 

                            if type(eventList) == "string" and eventList:lower():find("cosmic") then
                                isCosmic = true
                            end

                            if (srv.relics or 0) > 0 then
                                isCosmic = true
                            end

                            if isCosmic then
                                validCosmicCount = validCosmicCount + 1
                                targetServer = {
                                    jobId = jobId,
                                    placeId = placeId,
                                    relics = srv.relics or 0,
                                    event = eventList
                                }

                                break
                            end
                        end

                        if targetServer then
                            createHopNotification("Cosmic Found!", "Relics: " .. tostring(targetServer.relics), Color3.fromRGB(155, 89, 182))
                            currentTargetJobId = targetServer.jobId

                            failed = false

                            local teleportSuccess, teleportErr = pcall(function()
                                TeleportService:TeleportToPlaceInstance(targetServer.placeId, targetServer.jobId, game.Players.LocalPlayer)
                            end)

                            if not teleportSuccess then
                                blacklistedServers[currentTargetJobId] = true
                                print("[Auto Hop] ❌ Blacklisted server:", currentTargetJobId, "Reason:", teleportErr)
                                task.wait(1) 
                                continue
                            end

                            local startWait = tick()
                            repeat 
                                task.wait(0.5)
                            until failed or tick() - startWait > 12

                            if failed then
                                createHopNotification("Failed", "Retrying...", Color3.fromRGB(255, 100, 100))
                                task.wait(2) 
                            else
                                createHopNotification("Timeout", "Server slow, skipping...", Color3.fromRGB(255, 150, 50))
                                blacklistedServers[currentTargetJobId] = true
                            end
                        else
                            createHopNotification("No Cosmic", "API has no cosmic servers", Color3.fromRGB(150, 150, 150))
                            task.wait(5)
                        end
                    end
                end

                if connection then connection:Disconnect() end
                    isHopping = false
                end

                ExclusiveSection:AddToggle({
                    Title = "Auto Hop Cosmic",
                    Description = "Specifically searches for Cosmic Relics",
                    Default = _G.Config.AutoHopCosmic,
                    Callback = function(state)
                        _G.Config.AutoHopCosmic = state
                        if state then
                            _G.Config.AutoHopEnabled = false
                            task.spawn(StartAutoHopCosmic)
                        end
                    end
                })
                ExclusiveSection:AddSeperator({
                    Title = 'Notifications'
                })

                ExclusiveSection:AddToggle({
                    Title = "Enable Fish Notification UI",
                    Description = "Show on-screen notification when catching a fish",
                    Default = _G.Config.FishNotificationEnabled,
                    Callback = function(Value)
                        _G.Config.FishNotificationEnabled = Value
                    end
                })

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
                    Title = 'Server Hop Uptime'
                })

                _G.Config.AutoHopUptime = _G.Config.AutoHopUptime or false
                _searchingNotified = false

                local function isServerInTargetWindow(total_mins)
                    if total_mins < 50 then return false end
                    return (total_mins - 50) % 70 < 10
                end

                local function HopToLowUptimeServer()
                    while _G.Config.AutoHopUptime do
                        task.wait(10)
                        local currentUptimeSeconds = workspace.DistributedGameTime
                        local currentMinutes = math.floor(currentUptimeSeconds / 60)

                        if not isServerInTargetWindow(currentMinutes) then
                            if not _searchingNotified then
                                pcall(function()
                                    game.StarterGui:SetCore("SendNotification", {
                                        Title = "Uptime Server Hop",
                                        Text = "Server ini belum mendekati Event. Mencari server dari Webhook...",
                                        Duration = 5
                                    })
                                end)
                                _searchingNotified = true
                            end

                            local HttpService = game:GetService("HttpService")
                            local TeleportService = game:GetService("TeleportService")

                            local success, result = pcall(function()
                                return HttpService:JSONDecode(
                                    game:HttpGet("https://key.shieldteam.asia/api/key/weebhooks")
                                )
                            end)

                            if success and result and result.success and result.rows then
                                local hasTeleported = false
                                for _, row in ipairs(result.rows) do
                                    if not _G.Config.AutoHopUptime then break end
                                    local payload = row.payload
                                    if payload and payload.embeds and payload.embeds[1] and payload.embeds[1].fields then
                                        local fields = payload.embeds[1].fields
                                        local serverDesc = payload.embeds[1].description

                                        local uptimeVal = ""
                                        local playerCount = 0

                                        for _, field in ipairs(fields) do
                                            if field.name == "⏰ Uptime" then
                                                uptimeVal = field.value
                                            elseif field.name == "👥 Players" then
                                                local pStr = string.match(field.value, "%d+")
                                                if pStr then playerCount = tonumber(pStr) end
                                            end
                                        end

                                        local serverId = string.match(serverDesc, "`([%w%-]+)`")

                                        if serverId and serverId ~= game.JobId and playerCount < 20 then
                                            local d, h, m = string.match(uptimeVal, "(%d+)D%s+(%d+)H%s+(%d+)M")
                                            if not d then
                                                d, h, m = 0, 0, string.match(uptimeVal, "(%d+)M")
                                            end

                                            if m then
                                                local hari = tonumber(d) or 0
                                                local jam = tonumber(h) or 0
                                                local menit = tonumber(m) or 0

                                                local total_server_mins = (hari * 24 * 60) + (jam * 60) + menit

                                                if isServerInTargetWindow(total_server_mins) then
                                                    pcall(function()
                                                        game.StarterGui:SetCore("SendNotification", {
                                                            Title = "Uptime Server Hop",
                                                            Text = "Menemukan server pas (" .. tostring(total_server_mins) .. " Menit). Teleporting!",
                                                            Duration = 5
                                                        })
                                                    end)
                                                    hasTeleported = true
                                                    task.wait(1)
                                                    pcall(function()
                                                        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, game.Players.LocalPlayer)
                                                    end)
                                                    task.wait(5)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if hasTeleported then
                                    task.wait(10)
                                end
                            end
                        else
                            if _searchingNotified then
                                pcall(function()
                                    game.StarterGui:SetCore("SendNotification", {
                                        Title = "Uptime Server Hop",
                                        Text = "Siap-siap! Server ini akan segera menjatuhkan Sunken Chest.",
                                        Duration = 5
                                    })
                                end)
                                _searchingNotified = false
                            end
                        end
                    end
                end
                StatusUptimeParagraph = ExclusiveSection:AddParagraph({
                    Title = "Server Uptime Status",
                    Content = "Checking realtime status..."
                })

                ExclusiveSection:AddToggle({
                    Title = "Auto Hop (Sunken Chest Timers)",
                    Description = "Pindah ketika server mendekati menit 60, 130, 200 dst (-10 Mnt)",
                    Default = _G.Config.AutoHopUptime or false,
                    Callback = function(state)
                        _G.Config.AutoHopUptime = state

                        pcall(function()
                            game.StarterGui:SetCore("SendNotification", {
                                Title = "Uptime Server Hop",
                                Text = state and "Auto Hop (Uptime) Diaktifkan!" or "Auto Hop (Uptime) Dimatikan!",
                                Duration = 3
                            })
                        end)

                        if state then
                            task.spawn(HopToLowUptimeServer)
                        end
                    end
                })

                task.spawn(function()
                    while task.wait(1) do
                        pcall(function()
                            local uptimeText = "0D 0H 0M"
                            local foundUptime = false

                            pcall(function()
                                local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("serverInfo")
                                if gui and gui:FindFirstChild("serverInfo") and gui.serverInfo:FindFirstChild("uptime") then
                                    uptimeText = string.gsub(gui.serverInfo.uptime.Text, "Uptime: ", "")
                                    foundUptime = true
                                end
                            end)

                            local currentMinutes = 0
                            if foundUptime then
                                local d = tonumber(string.match(uptimeText, "(%d+)D")) or 0
                                local h = tonumber(string.match(uptimeText, "(%d+)H")) or 0
                                local m = tonumber(string.match(uptimeText, "(%d+)M")) or 0
                                currentMinutes = (d * 1440) + (h * 60) + m
                            else
                                currentMinutes = math.floor(workspace.DistributedGameTime / 60)
                                local d = math.floor(currentMinutes / 1440)
                                local h = math.floor((currentMinutes % 1440) / 60)
                                local m = currentMinutes % 60
                                uptimeText = tostring(d) .. "D " .. tostring(h) .. "H " .. tostring(m) .. "M"
                            end

                            local n = math.floor((currentMinutes + 10) / 70)
                            local nextTarget = 60 + (70 * n)
                            local minsTogo = nextTarget - currentMinutes

                            local tHari = math.floor(nextTarget / 1440)
                            local tJam = math.floor((nextTarget % 1440) / 60)
                            local tMenit = nextTarget % 60
                            local targetUptimeStr = tostring(tHari) .. "D " .. tostring(tJam) .. "H " .. tostring(tMenit) .. "M"

                            local sJam = math.floor(minsTogo / 60)
                            local sMenit = minsTogo % 60
                            local sisaWaktuStr = (sJam > 0 and tostring(sJam) .. "H " or "") .. tostring(sMenit) .. "M"

                            if StatusUptimeParagraph then
                                local contentText = "Uptime Server: " .. uptimeText .. "\nNext Drop Uptime: " .. targetUptimeStr .. " (In: " .. sisaWaktuStr .. ")"

                                if StatusUptimeParagraph.Set then
                                    StatusUptimeParagraph:Set({
                                        Title = "Server Uptime Status",
                                        Content = contentText
                                    })
                                elseif StatusUptimeParagraph.SetDesc then
                                    StatusUptimeParagraph:SetDesc(contentText)
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

                if _G.Config.AutoHopUptime then
                    autoHopUptimeEnabled = true
                    task.spawn(HopToLowUptimeServer)
                end

                ExclusiveSection:AddSeperator({
                    Title = 'Auto Hop Event'
                })
                ExclusiveSection:AddDropdown({
                    Title = "Select Target Event",
                    Description = "Auto Hop will search for these events",
                    Options = {
                        'Baby Bloop Fish', 
                        'Bloop Fish',
                        'Whales Pool',
                        'Lovestorm', 
                        "Plesiosaur Hunt", "Pliosaur Hunt", "Goldwraith Hunt", "Reef Titan Hunt", "Sunken Reliquary", "Omnithal Hunt",
                        'Orcas Pool',
                        'The Kraken Pool',
                        'Animal Pool',
                        'Animal Pool - Second Sea',
                        'Octophant Pool Without Elephant',
                        'Sea Leviathan Pool',
                        'Isonade',
                        'Forsaken Veil - Scylla',
                        'Blue Moon - Second Sea',
                        'Blue Moon - First Sea',
                        'LEGO',
                        'LEGO - Studolodon',
                        'Mosslurker',
                        'Narwhal',
                        'Whale Shark',
                        'Birthday Megalodon',
                        'Colossal Blue Dragon',
                        'Colossal Ancient Dragon',
                        'Colossal Ethereal Dragon',
                        'MossjawHunt',
                        'BrineStorm',
                        'KrakenHunt',
                        'MegHunt',
                        'MoonlitMirage',
                        'ScyllaHunt',
                        'ReefTitan',
                        'FrostwyrmHunt',
                        'The Sanctum Hunt',
                        'The Sanctum Profane Hunt',
                        'DepthsAbsoluteDarkness',
                        'SkeletalLeviathanHunt',
                        'WyvernHunt',
                        'NectarBloom',
                        'RotbloomHunt',
                        'FlowerGuardianHunt'
                    },
                    Multi = true,
                    Default = _G.Config.AutoHopEvents or {},
                    Callback = function(val)
                        targetHopEvents = val
                        _G.Config.AutoHopEvents = val
                    end
                })

                ExclusiveSection:AddToggle({
                    Title = "Enable Auto Hop",
                    Description = "Will keep hopping until target event is found in server list or current server",
                    Default = _G.Config.AutoHopEnabled or false,
                    Callback = function(state)
                        autoHopEnabled = state
                        _G.Config.AutoHopEnabled = state
                        if state then
                            task.spawn(StartAutoHop)
                        end
                    end
                })

                if _G.Config.AutoHopEnabled then
                    autoHopEnabled = true
                    task.spawn(StartAutoHop)
                end
                ExclusiveSection:AddSeperator({
                    Title = 'Auto Move Fish to Storage',
                })
                autoStorageRunning = false
                autoStorageEnabled = _G.Config.AutoStorageEnabled or false
                storageClonedCrate = nil
                storageFreezeActive = false

                local EXCLUDED_ITEMS = {
                    ["totem"] = true,
                    ["gps"] = true,
                    ["suit"] = true,
                    ["diving gear"] = true,
                    ["cage"] = true,
                    ["bag"] = true,
                    ["cloak"] = true,
                    ["glider"] = true,
                    ["keystone"] = true,
                    ["thread"] = true,
                    ["potion"] = true,
                    ["map"] = true,
                    ["tank"] = true,
                    ["fragment"] = true,
                    ["essence"] = true,
                    ["amulet"] = true,
                    ["conch"] = true,
                    ["egg"] = true,
                    ["shard"] = true,
                    ["firework"] = true,
                    ["flipper"] = true,
                    ["bait"] = true,
                    ["rod"] = true,
                    ["translator"] = true,
                    ["spearhead"] = true,
                    ["glove"] = true,
                    ["plushie"] = true,
                    ["coil"] = true,
                    ["seal"] = true,
                    ["waders"] = true,
                    ["whistle"] = true,
                    ["matrix"] = true,
                }

                function executeAutoStorage()
                    if autoStorageRunning then
                        return
                    end

                    autoStorageRunning = true
                    local prevAutoCast = nil
                    local prevEquipRod = nil

                    task.spawn(function()
                        local overallOk, overallErr = pcall(function()
                        local needsTeleport = not storageClonedCrate or not storageClonedCrate.Parent
                        if needsTeleport then
                            if _G.Config then 
                                prevAutoCast = _G.Config.AutoCast
                                prevEquipRod = _G.Config.equipRod
                                _G.Config.equipRod = false 
                                _G.Config.AutoCast = false
                            end
                            pcall(function()
                                local char = game:GetService("Players").LocalPlayer.Character
                                if char then
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    task.wait(0.2)
                                    if hum then hum:UnequipTools() end
                                    task.wait(1.5)
                                end
                            end)
                        end

                        local success, err = pcall(function()
                            local ReplicatedStorage = game:GetService("ReplicatedStorage")
                            local Players = game:GetService("Players")
                            local Workspace = game:GetService("Workspace")

                            local Net = require(ReplicatedStorage.packages.Net)
                            local DataController = require(ReplicatedStorage.client.legacyControllers.DataController)
                            local itemDisplayInfo = require(ReplicatedStorage.client.modules.ui.Backpack.itemDisplayInfo)

                            local LocalPlayer = Players.LocalPlayer
                            local Character = LocalPlayer.Character
                            if not Character then
                                return
                            end

                            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                            if not HumanoidRootPart then
                                return
                            end

                            local BulkMoveRemote = Net:RemoteFunction("Storage/RequestBulkMove")
                            local JoinAquarium = ReplicatedStorage.packages.Net["RE/PersonalAquarium/Join"]

                            local rarityMap = {}
                            local selectedRarities = _G.Config.AutoStorageRarities or {}
                            for _, rarity in ipairs(selectedRarities) do
                                rarityMap[rarity] = true
                            end

                            if next(rarityMap) == nil then
                                return
                            end

                            local function waitForChild(parent, childName, timeout)
                                local startTime = tick()
                                timeout = timeout or 10

                                while tick() - startTime < timeout do
                                    local child = parent:FindFirstChild(childName)
                                    if child then
                                        return child
                                    end
                                    task.wait(0.1)
                                end

                                return nil
                            end
                            local function isExcludedItem(itemName)
                                if not itemName then return true end

                                local lowerName = string.lower(itemName)

                                if string.find(lowerName, "cindercoil eel") or 
                                string.find(lowerName, "molten serpent") or
                                string.find(lowerName, "obsidian ray") or
                                string.find(lowerName, "infernal isonade") then
                                    return false
                                end

                                for keyword, _ in pairs(EXCLUDED_ITEMS) do
                                    if string.find(lowerName, keyword) then
                                        return true
                                    end
                                end

                                return false
                            end

                            if not storageClonedCrate or not storageClonedCrate.Parent then
                                local frozenPosition = HumanoidRootPart.CFrame
                                storageFreezeActive = true

                                task.spawn(function()
                                    while storageFreezeActive do
                                        local char = LocalPlayer.Character
                                        if char then
                                            local hrp = char:FindFirstChild("HumanoidRootPart")
                                            local hum = char:FindFirstChildOfClass("Humanoid")

                                            if hrp and frozenPosition then
                                                hrp.CFrame = frozenPosition
                                                hrp.AssemblyLinearVelocity = Vector3.zero
                                                hrp.AssemblyAngularVelocity = Vector3.zero

                                                if hum then
                                                    hum:ChangeState(Enum.HumanoidStateType.Seated)
                                                end
                                            end
                                        end

                                        task.wait()
                                    end
                                end)

                                task.wait(4)
                                pcall(function()
                                    JoinAquarium:FireServer(LocalPlayer.UserId)
                                end)

                                task.wait(2)
                                local userFolder = waitForChild(Workspace, tostring(LocalPlayer.UserId), 5)

                                if userFolder then
                                    local storageCrate = waitForChild(userFolder, "StorageCrate", 3)

                                    if storageCrate then
                                        pcall(function()
                                            storageClonedCrate = storageCrate:Clone()
                                            storageClonedCrate.Name = "ClonedStorageCrate_" .. LocalPlayer.UserId
                                            storageClonedCrate.Parent = ReplicatedStorage
                                        end)
                                    end
                                end

                                task.wait(0.5)
                            end

                            local inventory = nil
                            pcall(function()
                                if DataController.InventoryReplicator then
                                    inventory = DataController.InventoryReplicator:Index({"Inventory"})
                                else
                                    inventory = DataController.fetch("Inventory")
                                end
                            end)

                            if not inventory then
                                return
                            end

                            local itemsToDeposit = {}

                            for itemId, itemData in pairs(inventory) do
                                local displayInfo = itemDisplayInfo[itemData.name]

                                local hasValidRarity = false
                                if displayInfo and displayInfo.rarity then
                                    if rarityMap[displayInfo.rarity] then
                                        hasValidRarity = true
                                    end
                                end

                                local isGeode = string.find(string.lower(itemData.name), "geode") ~= nil

                                if hasValidRarity or isGeode then
                                    local isFavorited = itemData.sub and itemData.sub.Favourited

                                    if not isFavorited then
                                        if not isExcludedItem(itemData.name) then
                                            table.insert(itemsToDeposit, itemId)
                                        end
                                    end
                                end
                            end

                            if #itemsToDeposit > 0 then
                                pcall(function()
                                    return BulkMoveRemote:InvokeServer(itemsToDeposit, false)
                                end)

                                task.wait(0.5)
                            end

                            storageFreezeActive = false
                        end)

                        storageFreezeActive = false

                        if not success then
                            warn("[AutoStorage] Inner error: " .. tostring(err))
                        end

                        if needsTeleport then
                            task.spawn(function()
                                if _G.Config then
                                    if prevEquipRod ~= nil then
                                        _G.Config.equipRod = prevEquipRod
                                    end
                                    if prevAutoCast ~= nil then
                                        _G.Config.AutoCast = prevAutoCast
                                    end
                                end

                                if autoEquipRod and _G.Config.equipRod then
                                    task.wait(2)
                                    autoEquipRod()
                                elseif _G.Config.equipRod then
                                    local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                                    if backpack then
                                        local rod = backpack:FindFirstChild("Rod") or backpack:FindFirstChildOfClass("Tool")
                                        if rod then
                                            local char = game:GetService("Players").LocalPlayer.Character
                                            if char then
                                                local hum = char:FindFirstChildOfClass("Humanoid")
                                                if hum then hum:EquipTool(rod) end
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                        end)

                        if not overallOk then
                            warn("[AutoStorage] Error: " .. tostring(overallErr))
                        end
                        storageFreezeActive = false
                        autoStorageRunning = false
                    end)
                end
            function startAutoStorageLoop()
                task.spawn(function()
                    while _G.Config.AutoStorageEnabled do
                        if not autoStorageRunning then
                            executeAutoStorage()
                            while autoStorageRunning and _G.Config.AutoStorageEnabled do
                                task.wait(0.5)
                            end
                            if _G.Config.AutoStorageEnabled then
                                local interval = _G.Config.AutoStorageInterval or 60
                                task.wait(interval)
                            end
                        else
                            task.wait(1)
                        end
                    end
                end)
            end
            ExclusiveSection:AddDropdown({
                Title = "Select Rarities",
                Description = "Choose which fish rarities to move",
                Options = {"Trash", "Common", "Uncommon", "Unusual", "Rare", "Legendary", "Mythical", "Exotic", "Secret", "Divine Secret", "Limited", "Special", "Event", "Extinct", "Apex"},
                Multi = true,
                Default = _G.Config.AutoStorageRarities or {},
                Callback = function(value)
                    if type(value) == 'table' then
                        _G.Config.AutoStorageRarities = {}
                        for _, selectedValue in pairs(value) do
                            table.insert(_G.Config.AutoStorageRarities, selectedValue)
                        end
                    else
                        _G.Config.AutoStorageRarities = value
                    end
                end
            })
            ExclusiveSection:AddSlider({
                Title = "Auto Interval (seconds)",
                Description = "Delay between automatic storage cycles",
                Min = 1,
                Max = 300,
                Default = _G.Config.AutoStorageInterval or 60,
                Callback = function(value)
                    _G.Config.AutoStorageInterval = value
                end
            })

            ExclusiveSection:AddToggle({
                Title = "Auto Fish Storage",
                Description = "Automatically move fish on interval",
                Default = _G.Config.AutoStorageEnabled or false,
                Callback = function(value)
                    _G.Config.AutoStorageEnabled = value
                    if _G.Config.AutoStorageEnabled then
                        startAutoStorageLoop()
                    end
                end
            })
            ExclusiveSection:AddSeperator({
                Title = 'Auto Sell Storage',
            })
            ExclusiveSection:AddDropdown({
                Title = "Select Admin Events",
                Description = "Choose which events trigger the auto sell",
                Options = {"Buffed Goldstorm", "Goldstorm", "Blackout"},
                Multi = true,
                Default = _G.Config.AutoSellEvents or {},
                Callback = function(value)
                    local t = {}
                    if type(value) == 'table' then
                        for k, v in pairs(value) do
                            if type(k) == "number" then
                                table.insert(t, v:lower())
                            else
                                table.insert(t, k:lower())
                            end
                        end
                    elseif type(value) == 'string' then
                        table.insert(t, value:lower())
                    end
                    _G.Config.AutoSellEvents = t
                end
            })
            ExclusiveSection:AddToggle({
                Title = "Auto Sell Storage (Admin Event)",
                Description = "Sell all storage elements whenever an admin event occurs.",
                Default = _G.Config.AutoSellStorage,
                Callback = function(value)
                    _G.Config.AutoSellStorage = value
                    if value then
                        AutoSellStorage()
                    end
                end
            })

            ExclusiveSection:AddSeperator({
                Title = 'Anti AFK',
            })
            local antiAfkConnection
            ExclusiveSection:AddToggle({
                Title = "Anti AFK",
                Description = "Prevents being kicked for idleness (Memory Safe for 24h+)",
                Default = true,
                Callback = function(state)
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    if state then
                        pcall(function()
                            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                                if conn.Disable then conn:Disable() 
                                elseif conn.Disconnect then conn:Disconnect() end
                            end
                        end)
                    else
                        if antiAfkConnection then
                            antiAfkConnection:Disconnect()
                            antiAfkConnection = nil
                        end
                    end
                end
            })

            ExclusiveSection:AddSeperator({
                Title = 'Delete Animation',
            })
            ExclusiveSection:AddToggle({
                Title = "Delete Animation (Fishing)",
                Description = "Removes character animation to reduce lag",
                Default = _G.Config.DeleteAnimation or false,
                Callback = function(state)
                    _G.Config.DeleteAnimation = state
                    task.spawn(function()
                        FreazeChar(state)
                    end)
                end
            })

            if isfolder and not isfolder(configFolder) then
                if makefolder then
                    makefolder(configFolder)
                end
            end

            function getTimeSinceLastSave()
                local diff = os.time() - lastSaveTime
                if diff < 60 then
                    return diff .. "s ago"
                elseif diff < 3600 then
                    return math.floor(diff / 60) .. "m ago"
                else
                    return math.floor(diff / 3600) .. "h ago"
                end
            end

            function getPlayerPosition()
                local player = game.Players.LocalPlayer
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if root then
                    local pos = root.Position
                    local savedPos = {
                        X = math.floor(pos.X),
                        Y = math.floor(pos.Y),
                        Z = math.floor(pos.Z)
                    }
                    print("[Config] Position: " .. savedPos.X .. ", " .. savedPos.Y .. ", " .. savedPos.Z)
                    return savedPos
                end
                return nil
            end

            function getSavedConfigsList()
                savedConfigsList = {}

                if listfiles and isfolder and isfolder(configFolder) then
                    local files = listfiles(configFolder)

                    for _, file in pairs(files) do
                        if type(file) == "string" and file:match("%.json$") then
                            local fileName = file:match("([^/\\]+)%.json$")
                            if fileName then
                                table.insert(savedConfigsList, fileName)
                            end
                        end
                    end

                    table.sort(savedConfigsList)
                end
                return savedConfigsList
            end
            function updateStatusDisplay()
                if ConfigStatusParagraph then
                    local newContent = getConfigStatusText()
                    pcall(function()
                        if ConfigStatusParagraph.SetDesc then
                            ConfigStatusParagraph:SetDesc(newContent)
                        elseif ConfigStatusParagraph.Set then
                            ConfigStatusParagraph:Set({Content = newContent})
                        end
                    end)
                end
            end

            function saveConfig(configName)
                configName = configName or currentConfigFile
                local HttpService = game:GetService("HttpService")

                local currentPos = getPlayerPosition()
                if currentPos then
                    _G.Config.SavedPosition = deepCopy(currentPos)
                end

                local savePacket = {
                    Config = _G.Config,
                    Var = {}
                }

                for k, v in pairs(__var) do
                    if type(v) ~= "userdata" and type(v) ~= "function" then
                        savePacket.Var[k] = deepCopy(v)
                    end
                end

                local configString = HttpService:JSONEncode(savePacket)
                local filePath = configFolder .. configName .. ".json"

                if writefile then
                    writefile(filePath, configString)
                    lastSaveTime = os.time()
                    totalSaves = totalSaves + 1
                    currentConfigFile = configName

                    getSavedConfigsList()
                    updateStatusDisplay()
                    return true
                end
                return false
            end
            function loadConfig(configName, autoTeleport)
                configName = configName or currentConfigFile
                if autoTeleport == nil then 
                    autoTeleport = _G.Config.AutoTeleportOnLoad 
                end

                local filePath = configFolder .. configName .. ".json"
                if readfile and isfile and isfile(filePath) then
                    local HttpService = game:GetService("HttpService")
                    local success, result = pcall(function()
                        return HttpService:JSONDecode(readfile(filePath))
                    end)

                    if success and result then
                        local loadedConfig = result.Config or result
                        local loadedVar = result.Var or {}

                        for key, value in pairs(loadedConfig) do
                            if type(value) == "table" then
                                _G.Config[key] = deepCopy(value)
                            else
                                _G.Config[key] = value
                            end
                        end

                        for key, value in pairs(loadedVar) do
                            if key ~= "reelConnection" and key ~= "isReeling" then
                                if type(value) == "table" then
                                    __var[key] = deepCopy(value)
                                else
                                    __var[key] = value
                                end
                            end
                        end

                        currentConfigFile = configName
                        lastSaveTime = os.time()
                        updateStatusDisplay()
                        if autoTeleport and _G.Config.SavedPosition then
                            task.wait(0.5)
                            teleportToSavedPosition(_G.Config.SavedPosition)
                        end

                        return true
                    end
                end
                return false
            end

            function deleteConfig(configName)
                local filePath = configFolder .. configName .. ".json"
                if delfile and isfile and isfile(filePath) then
                    delfile(filePath)

                    getSavedConfigsList()

                    if #savedConfigsList > 0 then
                        currentConfigFile = savedConfigsList[1]
                        loadConfig(currentConfigFile, false)
                    else
                        currentConfigFile = "Default"
                        _G.Config.SavedPosition = nil
                    end

                    updateStatusDisplay()
                    return true
                end
                return false
            end

            function getConfigStatusText()
                local status = "File: " .. currentConfigFile .. ".json\n"
                local filePath = configFolder .. currentConfigFile .. ".json"

                status = status .. "Total Configs: " .. #savedConfigsList .. "\n"

                if isfile and isfile(filePath) then
                    status = status .. "Status: FOUND\n"
                    status = status .. "Last Save: " .. getTimeSinceLastSave() .. "\n"

                    if _G.Config.SavedPosition and _G.Config.SavedPosition.X then
                        local pos = _G.Config.SavedPosition
                        status = status .. "Position: " .. pos.X .. ", " .. pos.Y .. ", " .. pos.Z .. "\n"
                    else
                        local HttpService = game:GetService("HttpService")
                        local success, fileData = pcall(function()
                            return HttpService:JSONDecode(readfile(filePath))
                        end)

                        if success and fileData and fileData.SavedPosition then
                            local pos = fileData.SavedPosition
                            status = status .. "Position: " .. pos.X .. ", " .. pos.Y .. ", " .. pos.Z .. "\n"
                        else
                            status = status .. "Position: Not Saved\n"
                        end
                    end

                    status = status .. "Auto TP: " .. (_G.Config.AutoTeleportOnLoad and "ON" or "OFF")
                else
                    status = status .. "Status: NOT FOUND\nSave to create file"
                end

                return status
            end

            getSavedConfigsList()

            if #savedConfigsList == 0 then
                savedConfigsList = {"No Configs"}
            end

            ConfigStatusParagraph = AutoSaveSection:AddParagraph({
                Title = 'CONFIG INFO',
                Content = getConfigStatusText()
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

        selectedNpcToTp = nil
        NpcDropdown = NPCSection:AddDropdown({
            Title = "Select NPC",
            Options = npcNames,
            Default = "None",
            Callback = function(Value)
                selectedNpcToTp = Value
            end
        })

        NPCSection:AddButton({
            Title = "Teleport",
            Callback = function()
                targetCFrame = cachedNpcLocations[selectedNpcToTp]

                if selectedNpcToTp and workspace.world.npcs:FindFirstChild(selectedNpcToTp) then
                    npc = workspace.world.npcs[selectedNpcToTp]
                    root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc.PrimaryPart
                    if root then
                        targetCFrame = root.CFrame
                    end
                end

                if targetCFrame and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
                else
                    print("NPC location unknown or character not ready.")
                end
            end
        })

        NPCSection:AddButton({
            Title = "Refresh NPC List",
            Callback = function()
                updateNpcList()
                if NpcDropdown.SetValues then
                    NpcDropdown:SetValues(npcNames)
                elseif NpcDropdown.SetOptions then
                    NpcDropdown:SetOptions(npcNames)
                end
            end
        })
        local function teleportTo(pos)
            local p = game.Players.LocalPlayer
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end
        local teleportSpots = { 'None' }
        local teleportData = {}

        local function teleportTo22(areaName)
            local Character = LocalPlayer.Character
            if not Character then
                return
            end

            local HumanoidRootPart = Character:FindFirstChild('HumanoidRootPart')
            if not HumanoidRootPart then
                return
            end
            if areaName == 'None' and previousLocation then
                HumanoidRootPart.CFrame = previousLocation
                return
            end
            local targetCFrame = teleportData[areaName]
            if targetCFrame then
                previousLocation = HumanoidRootPart.CFrame
                HumanoidRootPart.CFrame = targetCFrame
            else
            end
        end

    local function getTpSpots()
        local world = Workspace:WaitForChild('world', 5)
        local spawns = world and world:WaitForChild('spawns', 5)
        local TpSpotsFolder = spawns and spawns:WaitForChild('TpSpots', 5)

        if not TpSpotsFolder then
            return { 'None' }
        end

        local spots = {}
        local children = TpSpotsFolder:GetChildren()
        for _, spot in pairs(children) do
            if spot:IsA('Part') or spot:IsA('CFrameValue') then
                table.insert(spots, spot.Name)
                if spot:IsA('Part') then
                    teleportData[spot.Name] = spot.CFrame
                elseif spot:IsA('CFrameValue') then
                    teleportData[spot.Name] = spot.Value
                end
            end
        end
        table.sort(spots)
        table.insert(spots, 1, 'None')
        return spots
    end
        teleportSpots = getTpSpots() 
        Dropdown(Main, "TP Area", "None", teleportSpots, false, function(selected)
            teleportTo22(selected)
        end)

        local tpCoord = nil

        Main:AddInput({
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
                        print("Koordinat siap:", tpCoord)
                    else
                        warn("Format salah! Masukkan setidaknya x, y, z")
                    end
                end
            end
        })

        Main:AddButton({
            Title = "Teleport",
            Callback = function()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and tpCoord then
                    char.HumanoidRootPart.CFrame = CFrame.new(tpCoord)
                    print("Teleported ke:", tpCoord)
                else
                    warn("Belum ada koordinat valid!")
                end
            end
        })
        local function getFishingZones()
            local zones = Workspace:WaitForChild('zones', 5)
            local FishingZonesFolder = zones and zones:FindFirstChild('fishing', 5)
            if not FishingZonesFolder then
                return { 'None' }
            end
            local spots = {}
            local zonesData = {}
            local children = FishingZonesFolder:GetChildren()
            for _, spot in pairs(children) do
                if spot:IsA('Part') then
                    if not zonesData[spot.Name] then
                        zonesData[spot.Name] = {}
                        table.insert(spots, spot.Name)
                    end
                    table.insert(zonesData[spot.Name], spot)
                end
            end

            table.sort(spots)
            table.insert(spots, 1, 'None')
            local sortedZonesData = {}
            for _, name in ipairs(spots) do
                if zonesData[name] then
                    sortedZonesData[name] = zonesData[name]
                end
            end

            return spots, sortedZonesData
        end

        local fishingSpots, _ = getFishingZones()
        local function AddZone(name)
            for _, spot in ipairs(fishingSpots) do
                if spot == name then
                    return 
                end
            end
            table.insert(fishingSpots, name)
        end
        AddZone("Crystal Cove")
        Dropdown(Main, "Teleport Zone", _G.Config.selectedZone, fishingSpots, false, function(selected)
            _G.Config.selectedZone = selected
        end)

        Main:AddButton({
            Title = "Teleport Zone",
            Content = "Teleport to selected zone",
            Callback = function()
                task.spawn(function()
                    TeleportFishingZoneNoFrezeandNoBoat(_G.Config.selectedZone)
                end)
            end
        })

        selectedPlayer = "None"
        local teleportPlayerDropdown

        function getPlayerNames()
            names = {"None"}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= speaker then
                    table.insert(names, player.Name)
                end
            end
            return names
        end
        teleportPlayerDropdown = Dropdown(Main, "Teleport Player", "None", getPlayerNames(), false, function(selected)
            selectedPlayer = selected
        end)
        function teleportToPlayer(playerName)
        root = getRoot(LocalPlayer.Character)
        targetPlayer = Players:FindFirstChild(playerName)

        if not root or not targetPlayer or not targetPlayer.Character then return end
        targetRoot = getRoot(targetPlayer.Character)
        if not targetRoot then return end

        targetCFrame = targetRoot.CFrame + Vector3.new(3, 1, 0)

        root.Anchored = true
        task.wait(0.05)

        local distance = (root.Position - targetRoot.Position).Magnitude
        if distance > 500 then
            local midPoint = root.CFrame:Lerp(targetCFrame, 0.5)
            root.CFrame = midPoint
            task.wait(0.1)
        end

        root.CFrame = targetCFrame
        task.wait(0.05)

        root.Anchored = false
        breakVelocity()
    end
        local teleportPlayerButton = Button(Main, "Teleport ke Pemain", function()
            if selectedPlayer ~= "None" then
                teleportToPlayer(selectedPlayer)
            end
        end)
        BallonSection:AddSeperator({
            Title = 'Ballon Teleport',
        })
        Button(BallonSection, "Teleport ke Balon 1", function()
            teleportTo(Vector3.new(201.9, 162, -33.7))
        end)
        Button(BallonSection, "Teleport ke Balon 2", function()
            teleportTo(Vector3.new(1005, 131, -1234))
        end)
        Button(BallonSection, "Teleport ke Balon 3", function()
            teleportTo(Vector3.new(-2800, 260, 1550))
        end)
        Button(BallonSection, "Teleport ke Balon 4", function()
            teleportTo(Vector3.new(-1244, 131, 1594))
        end)
        Button(BallonSection, "Teleport ke Balon 5", function()
            teleportTo(Vector3.new(-2001, 190, 389))
        end)
        Button(BallonSection, "Teleport ke Balon 6", function()
            teleportTo(Vector3.new(-1129, 228, -1158))
        end)
        Button(BallonSection, "Teleport ke Balon 7", function()
            teleportTo(Vector3.new(1237, 140, 551))
        end)
        Button(BallonSection, "Teleport ke Balon 8", function()
            teleportTo(Vector3.new(2747, 142, -785))
        end)
        Button(BallonSection, "Teleport ke Balon 9", function()
            teleportTo(Vector3.new(-3881, 131, 326))
        end)
        Button(BallonSection, "Teleport ke Balon 10", function()
            teleportTo(Vector3.new(-1804, 188, 256))
        end)
        Button(BallonSection, "Teleport ke Balon 11", function()
            teleportTo(Vector3.new(-9.5, 157, -1079))
        end)
        Button(BallonSection, "Teleport ke Balon 12", function()
            teleportTo(Vector3.new(545, 295, -1887))
        end)
        Button(BallonSection, "Teleport ke Balon 13", function()
            teleportTo(Vector3.new(-2015, 224, -496))
        end)
        Button(BallonSection, "Teleport ke Balon 14", function()
            teleportTo(Vector3.new(506, 172, 220))
        end)
        Button(BallonSection, "Teleport ke Balon 15", function()
            teleportTo(Vector3.new(1742, 141, -2481))
        end)
        Button(BallonSection, "Teleport ke Balon 16", function()
            teleportTo(Vector3.new(1742, 141, -2481))
        end)
        Button(BallonSection, "Teleport ke Balon 17", function()
            teleportTo(Vector3.new(106, 184, 2074))
        end)
        Button(BallonSection, "Teleport ke Balon 18", function()
            teleportTo(Vector3.new(3019, -130, 2451))
        end)
        Button(BallonSection, "Teleport ke Balon 19", function()
            teleportTo(Vector3.new(5934, 259, 216))
        end)
        Button(BallonSection, "Teleport ke Balon 20", function()
            teleportTo(Vector3.new(-1520, 130, 2194))
        end)

        _spPlayer = game:GetService("Players").LocalPlayer
        _spHttpService = game:GetService("HttpService")

        savedPositions = {}
        savedPositionName = "SHIELD"
        selectedPosition = "None"
        saveFileName = "saved_positions_shieldteam.json"

        function loadSavedPositions()
            local success, result = pcall(function()
                if isfile and isfile(saveFileName) then
                    jsonData = readfile(saveFileName)
                    return _spHttpService:JSONDecode(jsonData)
                end
                return {}
            end)

            if success and type(result) == "table" then
                return result
            else
                warn("Gagal memuat posisi tersimpan:", result)
                return {}
            end
        end

        function savePositionsToFile()
            local success, errorMsg = pcall(function()
                if writefile then
                    jsonData = _spHttpService:JSONEncode(savedPositions)
                    writefile(saveFileName, jsonData)
                end
            end)

            if not success then
                warn("Gagal menyimpan posisi:", errorMsg)
            end
        end

        savedPositions = loadSavedPositions()

        function getPositionNames()
            names = {"None"}
            for name, _ in pairs(savedPositions) do
                table.insert(names, name)
            end
            return names
        end

        SAVEPOSTION:AddInput({
            Title = "Name Spot",
            Default = savedPositionName,
            Callback = function(val)
                if val and val ~= "" then
                    savedPositionName = val
                end
            end
        })

        teleportPositionDropdown = SAVEPOSTION:AddDropdown({
            Title = "Saved Positions",
            Content = "Select a saved position to teleport",
            Multi = false,
            Options = getPositionNames(),
            Default = "None",
            Callback = function(val)
                selectedPosition = val
                print("Position selected:", val)
            end
        })

        function refreshDropdown()
            names = getPositionNames()
            local success, err = pcall(function()
                if teleportPositionDropdown.SetValues then
                    teleportPositionDropdown:SetValues(names)
                elseif teleportPositionDropdown.SetOptions then
                    teleportPositionDropdown:SetOptions(names)
                elseif teleportPositionDropdown.Refresh then
                    teleportPositionDropdown:Refresh(names)
                else
                    warn("Dropdown refresh method not found!")
                end
            end)
            if not success then
                warn("Gagal refresh dropdown:", err)
            end
        end

        SAVEPOSTION:AddButton({
            Title = "Save Position",
            Callback = function()
                if savedPositionName and savedPositionName ~= "" then
                    character = _spPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        pos = character.HumanoidRootPart.Position
                        savedPositions[savedPositionName] = {
                            X = pos.X,
                            Y = pos.Y,
                            Z = pos.Z
                        }
                        savePositionsToFile()
                        refreshDropdown()
                        print("Posisi disimpan:", savedPositionName)
                    else
                        warn("Character atau HumanoidRootPart tidak ditemukan!")
                    end
                else
                    warn("Nama posisi kosong!")
                end
            end
        })
        SAVEPOSTION:AddButton({
            Title = "Teleport ke Posisi",
            Callback = function()
                if selectedPosition ~= "None" and savedPositions[selectedPosition] then
                    character = _spPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        posData = savedPositions[selectedPosition]
                        targetPosition = Vector3.new(posData.X, posData.Y, posData.Z)

                        character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                        print("Teleport ke:", selectedPosition)
                    end
                else
                    warn("Tidak ada posisi yang dipilih atau posisi tidak valid!")
                end
            end
        })
        SAVEPOSTION:AddButton({
            Title = "Delete Selected Position",
            Callback = function()
                if selectedPosition ~= "None" and savedPositions[selectedPosition] then
                    savedPositions[selectedPosition] = nil
                    savePositionsToFile()
                    refreshDropdown()
                    selectedPosition = "None"
                    print("Posisi dihapus!")
                end
            end
        })
        SettingFish = FishingTab:AddSection("Fishing Setting", true, "Right")
        FishingZone = FishingTab:AddSection("Fishing Zone", true, "Right")
        FishingEventZone = FishingTab:AddSection("Fishing Event Zone", true, "Left")

        ShopBait = ShopTab:AddSection("Bait", true, "Left")
        ShopItem = ShopTab:AddSection("Shop Item", true, "Right")

    ShopItem:AddToggle({
        Title = "Auto Buy Carrot",
        Default = false,
        Callback = function(state)
            _G.Config.AutoBuyCarrot = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCarrot do
                        pcall(function()
                            local player = game:GetService("Players").LocalPlayer
                            local char = player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(266, 147, -146)
                            end
                            task.wait(0.2)
                            local args = { buffer.fromstring("h\\000\\006Carrot") }
                            game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

        ShopRod = ShopTab:AddSection("Rod", true, "Left")
        Merlin = ShopTab:AddSection("Merlin", true, "Right")

        AutosCollect = AutosTab:AddSection("Auto Collect Chest", true, "Left")

        AutosQuest = AutosTab:AddSection("Auto Quest", true, "Left")
        AutosJack = AutosTab:AddSection("Auto Treasure", true, "Right")
        AutosFavorit = AutosTab:AddSection("Auto Fav Item/Fish", true, "Left")
        AutosAppraise = AutosTab:AddSection("Appraise Treasure", true, "Right")
        AutoAppraise = AutosTab:AddSection("Appraise", true, "Left")
        AutoEnchant = AutosTab:AddSection("Enchant", true, "Right")
        Collect = AutosTab:AddSection("Collect", true, "Left")
        AutosSection = AutosTab:AddSection("Auto Sell", true, "Right")

        AuraSection = AutosTab:AddSection("Totem", true, "Left")

        EspPlayers = false
        EspZone = false
        EspNpc = false

        function AddEsp(target, name, color, offset)
            if not target then return end
            if target:FindFirstChild("BF_ESP") then return end

            bill = Instance.new("BillboardGui")
            bill.Name = "BF_ESP"
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 200, 0, 50)
            bill.Adornee = target
            bill.StudsOffset = offset or Vector3.new(0, 3, 0)

            text = Instance.new("TextLabel", bill)
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.TextColor3 = color
            text.TextStrokeTransparency = 0
            text.TextStrokeColor3 = Color3.new(0,0,0)
            text.Font = Enum.Font.GothamBold
            text.TextSize = 13
            text.Text = name

            bill.Parent = target

            if target.Parent and target.Parent:IsA("Model") then
                h = Instance.new("Highlight")
                h.Name = "BF_Highlight"
                h.FillColor = color
                h.OutlineColor = color
                h.FillTransparency = 0.8
                h.Adornee = target.Parent
                h.Parent = target
            end
        end

        function RemoveEsp(target)
            if target and target:FindFirstChild("BF_ESP") then
                target.BF_ESP:Destroy()
            end
            if target and target:FindFirstChild("BF_Highlight") then
                target.BF_Highlight:Destroy()
            end
        end

        task.spawn(function()
            while true do
                if EspPlayers then
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            hrp = p.Character.HumanoidRootPart
                            AddEsp(hrp, p.Name, Color3.fromRGB(255, 0, 0))
                            if hrp:FindFirstChild("BF_ESP") then
                                myRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot then
                                    dist = (myRoot.Position - hrp.Position).Magnitude
                                    hrp.BF_ESP.TextLabel.Text = p.Name .. " ["..math.floor(dist).."m]"
                                end
                            end
                        end
                    end
                else
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            RemoveEsp(p.Character.HumanoidRootPart)
                        end
                    end
                end

                if EspZone then
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        local targetEvents = {
                            ["Orca"] = true, ["Baby Bloop Fish"] = true, ["Bloop Fish"] = true, ["Moby"] = true, 
                            ["Megalodon"] = true, ["Mossjaw"] = true, ["Megalodon Ancient"] = true, 
                            ["Megalodon Phantom"] = true, ["Great White Shark"] = true, ["Hammerhead Shark"] = true, 
                            ["Whale Shark"] = true, ["The Depths - Serpent"] = true, ["Isonade"] = true, 
                            ["Forsaken Veil - Scylla"] = true, ["Blarney McBreeze"] = true, ["Sea Leviathan Pool"] = true, 
                            ["Animal Pool"] = true, ["Octophant Pool Without Elephant"] = true, ["Kraken Pool"] = true, 
                            ["Blue Moon - Second Sea"] = true, ["Blue Moon - First Sea"] = true, 
                            ["LEGO"] = true, ["LEGO - Studolodon"] = true, ["Mosslurker"] = true, ["Narwhal"] = true,
                            ["Megalodon Default"] = true
                        }
                        for _, z in pairs(zones:GetChildren()) do
                            if targetEvents[z.Name] then
                                if z:IsA("BasePart") then 
                                    AddEsp(z, z.Name, Color3.fromRGB(0, 255, 255))
                                elseif z:IsA("Model") and z.PrimaryPart then
                                    AddEsp(z.PrimaryPart, z.Name, Color3.fromRGB(0, 255, 255))
                                end
                            end
                        end
                    end
                elseif EspZoneAll then
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        for _, z in pairs(zones:GetChildren()) do
                            if z:IsA("BasePart") then 
                                AddEsp(z, z.Name, Color3.fromRGB(200, 200, 200))
                            elseif z:IsA("Model") and z.PrimaryPart then
                                AddEsp(z.PrimaryPart, z.Name, Color3.fromRGB(200, 200, 200))
                            end
                        end
                    end
                else
                    zones = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                    if zones then
                        for _, z in pairs(zones:GetChildren()) do
                            if z:IsA("BasePart") then RemoveEsp(z) 
                            elseif z:IsA("Model") and z.PrimaryPart then RemoveEsp(z.PrimaryPart) end
                        end
                    end
                end

                if EspNpc then
                    npcFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                    if npcFolder then
                        for _, n in pairs(npcFolder:GetChildren()) do
                            if n:FindFirstChild("HumanoidRootPart") then
                                AddEsp(n.HumanoidRootPart, n.Name, Color3.fromRGB(0, 255, 0))
                                if n.HumanoidRootPart:FindFirstChild("BF_ESP") then
                                    myRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if myRoot then
                                        dist = (myRoot.Position - n.HumanoidRootPart.Position).Magnitude
                                        n.HumanoidRootPart.BF_ESP.TextLabel.Text = n.Name .. " ["..math.floor(dist).."m]"
                                    end
                                end
                            end
                        end
                    end
                else
                    npcFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                    if npcFolder then
                        for _, n in pairs(npcFolder:GetChildren()) do
                            if n:FindFirstChild("HumanoidRootPart") then
                                RemoveEsp(n.HumanoidRootPart)
                            end
                        end
                    end
                end

                task.wait(1)
            end
        end)

        EspCharacterSection = EspTab:AddSection("ESP Character", true, "Left")
        EspCharacterSection:AddToggle({
            Title = "Enable ESP Character",
            Default = false,
            Callback = function(v)
                EspPlayers = v
            end
        })

        EspEventSection = EspTab:AddSection("ESP Zone", true, "Right")
        EspEventSection:AddToggle({
            Title = "Enable ESP Zone Event",
            Default = false,
            Callback = function(v)
                EspZone = v
            end
        })
        EspEventSection:AddToggle({
            Title = "Enable ESP Zone",
            Default = false,
            Callback = function(v)
                EspZoneAll = v
            end
        })

        EspNpcSection = EspTab:AddSection("ESP NPC", true, "Right")
        EspNpcSection:AddToggle({
            Title = "Enable ESP NPC",
            Default = false,
            Callback = function(v)
                EspNpc = v
            end
        })


end

return InitExclusive
