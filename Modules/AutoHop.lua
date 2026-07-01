local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local autoHopEnabled = false
local isHopping = false
local blacklistedServers = {}
local currentHopNotification = nil
local hopNotificationTask = nil
local targetHopEvents = {}

local API_URL_HOP = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

local function parseHopData(decoded)
    local servers = {}
    if type(decoded) == "table" and decoded.data then
        for _, srv in ipairs(decoded.data) do
            table.insert(servers, {
                jobId = srv.id,
                placeId = game.PlaceId,
                playerCount = srv.playing or 0,
                maxPlayers = srv.maxPlayers or 0,
                event = srv.name or "",
                relics = 0,
            })
        end
    end
    return servers
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
    local zones = workspace:FindFirstChild("zones")
    if not zones or not zones:FindFirstChild("fishing") then return false end
    local fishingZones = zones.fishing

    for k, v in pairs(targetHopEvents) do
        local targetName = ""
        if type(k) == "number" and type(v) == "string" then targetName = v
        elseif type(k) == "string" and v == true then targetName = k end

        if targetName == "Cosmic Relic" then
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name == "StarCrater" and child:FindFirstChild("Root")
                    and child.Root:FindFirstChild("Cosmic Relic") then
                    return true, "Cosmic Relic"
                end
            end
        elseif targetName ~= "" and fishingZones:FindFirstChild(targetName) then
            return true, targetName
        end
    end
    return false
end

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

local function StartAutoHop()
    if isHopping then return end
    isHopping = true

    local currentTargetJobId = nil
    local failed = false

    local connection = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == Players.LocalPlayer then
            createHopNotification("Teleport Failed", "Error: " .. tostring(errorMessage), Color3.fromRGB(255, 80, 80))
            if currentTargetJobId then blacklistedServers[currentTargetJobId] = true end
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
            if not blacklistedServers[srv.jobId] then
                if srv.maxPlayers - srv.playerCount >= 1 then
                    for k, v in pairs(targetHopEvents) do
                        local targetName = ""
                        if type(k) == "number" and type(v) == "string" then targetName = v
                        elseif type(k) == "string" and v == true then targetName = k end

                        if targetName ~= "" and srv.event then
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
                    if targetServer then break end
                end
            end
        end

        if targetServer then
            createHopNotification("Server Found!", "Joining " .. tostring(targetServer.event), Color3.fromRGB(0, 170, 255))
            currentTargetJobId = targetServer.jobId
            failed = false
            TeleportService:TeleportToPlaceInstance(targetServer.placeId, targetServer.jobId, Players.LocalPlayer)

            local startWait = tick()
            repeat task.wait(0.5) until failed or tick() - startWait > 8

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

local function SetTargetEvents(events)
    targetHopEvents = events or {}
end

local function SetEnabled(state)
    autoHopEnabled = state
    if state then
        task.spawn(StartAutoHop)
    end
end

return {
    SetEnabled = SetEnabled,
    SetTargetEvents = SetTargetEvents,
    StartAutoHop = StartAutoHop,
    CreateNotification = createHopNotification,
}
