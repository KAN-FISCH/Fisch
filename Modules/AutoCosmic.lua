local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
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
end
return Init
