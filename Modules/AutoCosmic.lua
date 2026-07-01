local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local isHopping = false
local blacklistedServers = {}
local lastBlacklistClear = tick()
local currentHopNotification = nil
local hopNotificationTask = nil

local function createHopNotification(titleText, statusText, statusColor)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
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

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = titleText
    titleLabel.Size = UDim2.new(1, -20, 0, 16)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = statusText
    statusLabel.Size = UDim2.new(1, -20, 0, 14)
    statusLabel.Position = UDim2.new(0, 10, 0, 28)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextColor3 = statusColor or Color3.fromRGB(180, 180, 180)
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = frame

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

local function setupErrorPromptRemover()
    local CoreGui = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")
    
    task.spawn(function()
        while _G.Config and _G.Config.AutoHopCosmic do
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
            end)
            task.wait(2)
        end
    end)
end

local function unlockControls()
    pcall(function()
        Players.LocalPlayer.Character.Humanoid.PlatformStand = false
    end)
end

local function fetchSmartServers()
    local API_URL = "https://key.shieldteam.asia/api/key/weebhooks"
    print("[Auto Hop Cosmic] Fetching servers from API Webhook...")
    local success, result = pcall(function()
        return game:HttpGet(API_URL)
    end)

    local parsedServers = {}
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(result) end)
        if ok and data and data.rows and type(data.rows) == "table" then
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
                            if zones:find("No active") or zones == "" then
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
        warn("[Auto Hop Cosmic] API Fetch Failed:", result)
    end
    return parsedServers
end

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

local function StartAutoHopCosmic()
    if isHopping then return end
    isHopping = true

    setupErrorPromptRemover()

    local currentTargetJobId = nil
    local failed = false

    local connection = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == Players.LocalPlayer then
            createHopNotification("Teleport Failed", "Error: " .. tostring(errorMessage), Color3.fromRGB(255, 80, 80))
            unlockControls()
            if currentTargetJobId then
                blacklistedServers[currentTargetJobId] = true
            end
            failed = true
        end
    end)

    while _G.Config and _G.Config.AutoHopCosmic do
        if tick() - lastBlacklistClear > 1800 then
            blacklistedServers = {}
            lastBlacklistClear = tick()
            createHopNotification("Blacklist Cleared", "Reset blacklist cache", Color3.fromRGB(100, 200, 255))
        end

        local foundCosmic = hasCosmic(workspace, 0)
        if foundCosmic then
            createHopNotification("Farming Cosmic", "Waiting for relics to deplete...", Color3.fromRGB(80, 255, 100))
            task.wait(5)
            continue
        end

        createHopNotification("Cosmic Hop", "Fetching API Servers...", Color3.fromRGB(155, 89, 182))
        local servers = fetchSmartServers()
        local targetServer = nil

        for _, srv in ipairs(servers) do
            local jobId = srv.jobId
            local placeId = srv.placeId
            local playerCount = srv.playerCount or 0
            local maxPlayers = srv.maxPlayers or 20
            local eventList = srv.event or ""

            if not jobId or not placeId then continue end
            if blacklistedServers[jobId] then continue end
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
                TeleportService:TeleportToPlaceInstance(targetServer.placeId, targetServer.jobId, Players.LocalPlayer)
            end)

            if not teleportSuccess then
                blacklistedServers[currentTargetJobId] = true
                task.wait(1)
                continue
            end

            local startWait = tick()
            repeat task.wait(0.5) until failed or tick() - startWait > 12

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

    if connection then connection:Disconnect() end
    isHopping = false
end

local function SetEnabled(state)
    if state then
        _G.Config.AutoHopCosmic = true
        task.spawn(StartAutoHopCosmic)
    else
        _G.Config.AutoHopCosmic = false
    end
end

return {
    SetEnabled = SetEnabled,
    StartLoop = StartAutoHopCosmic,
}
