local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Helper getMod loader (no script dependency)
local function getMod(name)
    if _G.getMod then return _G.getMod(name) end
    local core = game:GetService("ReplicatedStorage"):FindFirstChild("Shield_Core")
    if core then
        local folder = core:FindFirstChild(name)
        if folder then
            local src = ""
            if folder:IsA("Folder") then
                for i = 1, #folder:GetChildren() do
                    local chunk = folder:FindFirstChild(tostring(i))
                    if chunk then src = src .. chunk.Value end
                end
            else
                src = folder.Value
            end
            local fn, err = loadstring(src)
            if not fn then
                warn("[NewFish5] Failed to load module '" .. tostring(name) .. "': " .. tostring(err))
                return nil
            end
            local success, res = pcall(fn)
            if not success then
                warn("[NewFish5] Error executing module '" .. tostring(name) .. "': " .. tostring(res))
                return nil
            end
            return res
        end
    end
    return nil
end

local TweenService = game:GetService("TweenService")
local currentNotification = nil
local notificationTask = nil
local activeNotifications = {}
local MAX_NOTIFICATIONS = 3

-- Pre-cache UI and game libraries to eliminate notification lag
local LocalPlayer = Players.LocalPlayer
local PlayerGui = nil
local fishLib = nil
local mutLib = nil

local function getPlayerGui()
    if PlayerGui then return PlayerGui end
    PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    return PlayerGui
end

local function getFishLib()
    if fishLib then return fishLib end
    pcall(function()
        local shared = ReplicatedStorage:WaitForChild("shared", 5)
        local modules = shared and shared:WaitForChild("modules", 5)
        local library = modules and modules:WaitForChild("library", 5)
        local fishMod = library and library:WaitForChild("fish", 5)
        if fishMod then
            fishLib = require(fishMod)
        end
    end)
    return fishLib
end

local function getMutLib()
    if mutLib then return mutLib end
    pcall(function()
        local shared = ReplicatedStorage:WaitForChild("shared", 5)
        local modules = shared and shared:WaitForChild("modules", 5)
        local fishing = modules and modules:WaitForChild("fishing", 5)
        local mutMod = fishing and fishing:WaitForChild("mutations", 5)
        if mutMod then
            mutLib = require(mutMod)
        end
    end)
    return mutLib
end

local function createFishNotification(fishName, mutation, fishWeight, estimatedPrice, rarity)
    local playerGui = getPlayerGui()
    if not playerGui then return end
    local screenGui = playerGui:FindFirstChild("FishNotificationUI")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishNotificationUI"
        screenGui.Parent = playerGui
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    end

    if currentNotification and currentNotification.Parent then
        local display = currentNotification:GetAttribute("DisplayID")
        local newID = fishName .. mutation

        if display == newID then
            if notificationTask then task.cancel(notificationTask) end

            currentNotification.Size = UDim2.new(0, 270, 0, 85)
            TweenService:Create(currentNotification, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
                Size = UDim2.new(0, 280, 0, 87)
            }):Play()

            notificationTask = task.delay(4, function()
                if currentNotification and currentNotification.Parent then
                    local tw = TweenService:Create(currentNotification, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                        Position = UDim2.new(0, -300, 0.5, -43),
                        BackgroundTransparency = 1
                    })
                    tw:Play()
                    tw.Completed:Wait()
                    if currentNotification then 
                        currentNotification:Destroy() 
                        currentNotification = nil
                    end
                end
            end)
            return
        else
            if currentNotification then currentNotification:Destroy() end
            currentNotification = nil
            if notificationTask then task.cancel(notificationTask) end
        end
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 270, 0, 85)
    frame.Position = UDim2.new(0, -300, 0.5, -43) 
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame:SetAttribute("DisplayID", fishName .. mutation)

    currentNotification = frame

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

    createDot(Color3.fromRGB(255, 95, 87), UDim2.new(0, 8, 0, 8))
    createDot(Color3.fromRGB(255, 189, 46), UDim2.new(0, 20, 0, 8))
    createDot(Color3.fromRGB(40, 201, 64), UDim2.new(0, 32, 0, 8))

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 32, 0, 32)
    icon.Position = UDim2.new(0, 10, 0, 25)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://18820698114"
    icon.Parent = frame

    local title = Instance.new("TextLabel")
    title.Text = fishName
    title.Size = UDim2.new(1, -55, 0, 18)
    title.Position = UDim2.new(0, 48, 0, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = frame

    if rarity then
        local rarityBadge = Instance.new("Frame")
        rarityBadge.Size = UDim2.new(0, 50, 0, 16)
        rarityBadge.Position = UDim2.new(1, -58, 0, 24)
        local rarityColours = {
            ["Common"] = Color3.fromRGB(100, 100, 100),
            ["Uncommon"] = Color3.fromRGB(0, 200, 0),
            ["Unusual"] = Color3.fromRGB(0, 150, 255),
            ["Rare"] = Color3.fromRGB(150, 0, 255),
            ["Legendary"] = Color3.fromRGB(255, 150, 0),
            ["Mythical"] = Color3.fromRGB(255, 0, 100),
            ["Exotic"] = Color3.fromRGB(255, 255, 0)
        }
        rarityBadge.BackgroundColor3 = rarityColours[rarity] or Color3.fromRGB(100, 100, 100)
        rarityBadge.BorderSizePixel = 0
        rarityBadge.Parent = frame

        local rarityCorner = Instance.new("UICorner")
        rarityCorner.CornerRadius = UDim.new(0, 4)
        rarityCorner.Parent = rarityBadge

        local rarityText = Instance.new("TextLabel")
        rarityText.Size = UDim2.new(1, 0, 1, 0)
        rarityText.BackgroundTransparency = 1
        rarityText.Text = rarity:sub(1, 3):upper()
        rarityText.TextColor3 = Color3.fromRGB(255, 255, 255)
        rarityText.TextSize = 9
        rarityText.Font = Enum.Font.GothamBold
        rarityText.Parent = rarityBadge
    end

    local weightLabel = Instance.new("TextLabel")
    weightLabel.Text = "⚖️ " .. string.format("%.1f kg", fishWeight or 0)
    weightLabel.Size = UDim2.new(0.5, -25, 0, 14)
    weightLabel.Position = UDim2.new(0, 48, 0, 42)
    weightLabel.BackgroundTransparency = 1
    weightLabel.Font = Enum.Font.Gotham
    weightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    weightLabel.TextSize = 10
    weightLabel.TextXAlignment = Enum.TextXAlignment.Left
    weightLabel.Parent = frame

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Text = "💰 " .. (estimatedPrice or 0) .. " C$"
    priceLabel.Size = UDim2.new(0.5, -25, 0, 14)
    priceLabel.Position = UDim2.new(0.5, 0, 0, 42)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextSize = 10
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.Parent = frame

    local badgeContainer = Instance.new("Frame")
    badgeContainer.Size = UDim2.new(1, -48, 0, 18)
    badgeContainer.Position = UDim2.new(0, 48, 0, 60)
    badgeContainer.BackgroundTransparency = 1
    badgeContainer.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = badgeContainer

    local mutationsList = {}
    if mutation and mutation ~= "None" then
        for m in string.gmatch(mutation, "([^,]+)") do
            local clean = m:match("^%s*(.-)%s*$")
            if clean and clean ~= "" then
                table.insert(mutationsList, clean)
            end
        end
    end

    for _, mut in ipairs(mutationsList) do
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0, 0, 0, 16)
        badge.BorderSizePixel = 0
        badge.TextSize = 9
        badge.Font = Enum.Font.GothamBold
        badge.AutomaticSize = Enum.AutomaticSize.X

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = badge

        if mut == "Shiny" then
            badge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
            badge.Text = " ✨ SHINY "
            badge.TextColor3 = Color3.fromRGB(0, 0, 0)
        elseif mut == "Sparkling" then
            badge.BackgroundColor3 = Color3.fromRGB(147, 112, 219)
            badge.Text = " ⭐ SPARK "
            badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            badge.BackgroundColor3 = Color3.fromRGB(75, 0, 130)
            badge.Text = " 🧬 " .. mut .. " "
            badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

        badge.Parent = badgeContainer
    end

    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 0.5, -43)
    }):Play()

    notificationTask = task.delay(4, function()
        if currentNotification == frame then
            local tw = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -300, 0.5, -43),
                BackgroundTransparency = 1
            })
            tw:Play()
            tw.Completed:Wait()
            if currentNotification == frame then
                frame:Destroy()
                currentNotification = nil
            end
        end
    end)
end

local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, EspCharacterSection, EspEventSection, EspNpcSection)
    local AutoCosmic = getMod("AutoCosmic")
    local AutoStorage = getMod("AutoStorage")
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
            Title = "ESP Zone Event",
            Default = false,
            Callback = function(value)
                ESP.SetEspZone(value)
            end
        })
        EspEventSection:AddToggle({
            Title = "ESP Zone",
            Default = false,
            Callback = function(value)
                ESP.SetEspZoneAll(value)
            end
        })
        EspNpcSection:AddToggle({
            Title = "ESP NPC",
            Default = false,
            Callback = function(value)
                ESP.SetEspNpc(value)
            end
        })
        EspNpcSection:AddToggle({
            Title = "ESP Roaming Fish",
            Default = false,
            Callback = function(value)
                ESP.SetEspRoaming(value)
            end
        })
    end

    -- Cosmic Features
    ExclusiveSection:AddSeperator({
        Title = 'Cosmic Features'
    })
    local _tCosmicHop = ExclusiveSection:AddToggle({
        Title = "Auto Hop Cosmic",
        Description = "Specifically searches for Cosmic Relics",
        Default = _G.Config.AutoHopCosmic or false,
        Callback = function(state)
            _G.Config.AutoHopCosmic = state
            if state then
                _G.Config.AutoHopUptime = false
                if AutoCosmic then AutoCosmic.SetEnabled(true) end
            else
                if AutoCosmic then AutoCosmic.SetEnabled(false) end
            end
        end
    })
    if getgenv().regUIElement then
        getgenv().regUIElement(_tCosmicHop, "AutoHopCosmic", function(state)
            _G.Config.AutoHopCosmic = state
            if state then
                _G.Config.AutoHopUptime = false
                if AutoCosmic then AutoCosmic.SetEnabled(true) end
            else
                if AutoCosmic then AutoCosmic.SetEnabled(false) end
            end
        end)
    end

    local _tCollectCosmic = ExclusiveSection:AddToggle({
        Title = "Collect Cosmic",
        Description = "Claim Lunar Thread, Starfall Totem, Cosmic Relic, Meteoric",
        Default = _G.Config.AutoClaimMulti or false,
        Callback = function(state)
            _G.Config.AutoClaimMulti = state
            if state and getgenv().startAutoClaimMulti then
                getgenv().startAutoClaimMulti()
            end
        end
    })
    if getgenv().regUIElement then
        getgenv().regUIElement(_tCollectCosmic, "AutoClaimMulti", function(state)
            _G.Config.AutoClaimMulti = state
            if state and getgenv().startAutoClaimMulti then
                getgenv().startAutoClaimMulti()
            end
        end)
    end

    -- Auto Potion
    ExclusiveSection:AddSeperator({
        Title = 'Auto Potion'
    })
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

    -- Discord Webhook
    ExclusiveSection:AddSeperator({
        Title = 'Discord Webhook'
    })
    ExclusiveSection:AddToggle({
        Title = "Enable Discord Webhook",
        Description = "Send fish caught to Discord",
        Default = _G.Config.DiscordWebhookEnabled or false,
        Callback = function(Value)
            _G.Config.DiscordWebhookEnabled = Value
        end
    })
    ExclusiveSection:AddInput({
        Title = "Discord Webhook URL",
        Default = _G.Config.DiscordWebhookURL or "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(Value)
            _G.Config.DiscordWebhookURL = Value
        end
    })



    -- Auto Move Fish to Storage
    ExclusiveSection:AddSeperator({
        Title = 'Auto Move Fish to Storage',
    })
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
            if value and AutoStorage then
                AutoStorage.StartLoop()
            end
        end
    })

    -- Auto Sell Storage
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
        Default = _G.Config.AutoSellStorage or false,
        Callback = function(value)
            _G.Config.AutoSellStorage = value
            if value and AutoStorage then
                AutoStorage.StartSellStorage()
            end
        end
    })

    -- Delete Animation
    local isFreaze = false
    local function FreazeChar(state)
        isFreaze = state  
        local Character = Players.LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChild("Humanoid")
            local Animator = Humanoid and Humanoid:FindFirstChild("Animator")
            local AnimateScript = Character:FindFirstChild("Animate")
            if isFreaze then
                if AnimateScript then AnimateScript.Disabled = true end
                if Animator then
                    pcall(function()
                        for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
                            track:Stop()
                        end
                    end)
                end
            else
                if AnimateScript then AnimateScript.Disabled = false end
            end
        end
    end
    Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if isFreaze then FreazeChar(true) end
    end)

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

    -- Startup loops for storage & animation
    if _G.Config.AutoStorageEnabled then
        if AutoStorage then AutoStorage.StartLoop() end
    end
    if _G.Config.AutoSellStorage then
        if AutoStorage then AutoStorage.StartSellStorage() end
    end
    if _G.Config.DeleteAnimation then
        task.spawn(function() FreazeChar(true) end)
    end

    -- Server Hop Uptime Features
    ExclusiveSection:AddSeperator({
        Title = 'Server Hop Uptime'
    })
    local StatusUptimeParagraph = ExclusiveSection:AddParagraph({
        Title = "Server Uptime Status",
        Content = "Checking realtime status..."
    })

    local function isServerInTargetWindow(total_mins)
        if total_mins < 50 then return false end
        return (total_mins - 50) % 70 < 10
    end

    local function HopToLowUptimeServer()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        while _G.Config.AutoHopUptime do
            task.wait(10)
            local currentUptimeSeconds = workspace.DistributedGameTime
            local currentMinutes = math.floor(currentUptimeSeconds / 60)
            if not isServerInTargetWindow(currentMinutes) then
                pcall(function()
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Uptime Server Hop",
                        Text = "Server ini belum mendekati Event. Mencari server...",
                        Duration = 5
                    })
                end)
                local success, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://key.shieldteam.asia/api/key/weebhooks"))
                end)
                if success and result and result.success and result.rows then
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
                                    local total_server_mins = ((tonumber(d) or 0) * 1440) + ((tonumber(h) or 0) * 60) + (tonumber(m) or 0)
                                    if isServerInTargetWindow(total_server_mins) then
                                        pcall(function()
                                            game.StarterGui:SetCore("SendNotification", {
                                                Title = "Uptime Server Hop",
                                                Text = "Menemukan server pas (" .. tostring(total_server_mins) .. " Menit). Teleporting!",
                                                Duration = 5
                                            })
                                        end)
                                        task.wait(1)
                                        pcall(function()
                                            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, Players.LocalPlayer)
                                        end)
                                        task.wait(5)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local _tHopUptime = ExclusiveSection:AddToggle({
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
    if getgenv().regUIElement then
        getgenv().regUIElement(_tHopUptime, "AutoHopUptime", function(state)
            _G.Config.AutoHopUptime = state
            if state then
                task.spawn(HopToLowUptimeServer)
            end
        end)
    end



    -- Server Finder / Solo Server Finder
    local function toggleSoloServer(state)
        if state then
            local gameId = game.PlaceId
            local httpService = game:GetService("HttpService")

            local success, result = pcall(function()
                return httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..gameId.."/servers/Public?sortOrder=Asc&limit=100"))
            end)

            if success and result.data then
                local validServers = {}

                for _, server in ipairs(result.data) do
                    if server.playing == 1 and server.id ~= game.JobId then
                        table.insert(validServers, server)
                    end
                end

                if #validServers > 0 then
                    table.sort(validServers, function(a, b)
                        if a.maxPlayers ~= b.maxPlayers then
                            return a.maxPlayers > b.maxPlayers
                        end
                        return a.id < b.id
                    end)
                    local targetServer = validServers[1]
                    print("Found solo server! MaxPlayers: " .. targetServer.maxPlayers .. ", ID: " .. targetServer.id)
                    local TeleportService = game:GetService("TeleportService")
                    TeleportService:TeleportToPlaceInstance(gameId, targetServer.id, Players.LocalPlayer)
                    return
                else
                    warn("No solo servers found. Trying to find old empty server...")
                    local emptyServers = {}
                    for _, server in ipairs(result.data) do
                        if server.playing == 0 then
                            table.insert(emptyServers, server)
                        end
                    end

                    if #emptyServers > 0 then
                        table.sort(emptyServers, function(a, b)
                            if a.maxPlayers ~= b.maxPlayers then
                                return a.maxPlayers > b.maxPlayers
                            end
                            return a.id < b.id
                        end)

                        local targetServer = emptyServers[1]
                        print("Found old empty server! MaxPlayers: " .. targetServer.maxPlayers .. ", ID: " .. targetServer.id)
                        local TeleportService = game:GetService("TeleportService")
                        TeleportService:TeleportToPlaceInstance(gameId, targetServer.id, Players.LocalPlayer)
                        return
                    end

                    warn("No suitable servers found.")
                end
            else
                warn("Failed to fetch server list")
            end
        end
    end

    local function findOldSoloServer()
        local gameId = game.PlaceId
        local httpService = game:GetService("HttpService")
        for page = 0, 2 do
            local cursor = page > 0 and "&cursor=" .. (page * 100) or ""
            local url = "https://games.roblox.com/v1/games/"..gameId.."/servers/Public?sortOrder=Asc&limit=100" .. cursor

            local success, result = pcall(function()
                return httpService:JSONDecode(game:HttpGet(url))
            end)

            if success and result.data then
                for _, server in ipairs(result.data) do
                    if server.playing == 1 and server.id ~= game.JobId then
                        if server.maxPlayers >= 25 then
                            print("Found old solo server! Page: " .. page .. ", MaxPlayers: " .. server.maxPlayers)
                            local TeleportService = game:GetService("TeleportService")
                            TeleportService:TeleportToPlaceInstance(gameId, server.id, Players.LocalPlayer)
                            return true
                        end
                    end
                end
            end
            task.wait(0.5)
        end
        return false
    end

    local function executeServerHop()
        if not findOldSoloServer() then
            toggleSoloServer(true)
        end
    end

    ExclusiveSection:AddSeperator({
        Title = 'Server Finder'
    })

    ExclusiveSection:AddButton({
        Title = "Join Lowest Player Server",
        Description = "Teleports you to a public server with the fewest players",
        Callback = function()
            task.spawn(executeServerHop)
        end
    })

    local _tPlayerDetect = ExclusiveSection:AddToggle({
        Title = "Auto Rejoin if Players >= 3",
        Description = "Automatically leaves and finds a solo server if player count grows",
        Default = _G.Config.playerDetectionEnabled or false,
        Callback = function(state)
            _G.Config.playerDetectionEnabled = state
        end
    })
    if getgenv().regUIElement then
        getgenv().regUIElement(_tPlayerDetect, "playerDetectionEnabled", function(state)
            _G.Config.playerDetectionEnabled = state
        end)
    end

    task.spawn(function()
        local rejoinCooldown = false
        while task.wait(5) do
            if _G.Config and _G.Config.playerDetectionEnabled then
                local playerCount = #Players:GetPlayers()
                if playerCount >= 3 and not rejoinCooldown then
                    rejoinCooldown = true
                    print("Player count: " .. playerCount .. " - Initiating rejoin...")
                    task.spawn(executeServerHop)
                    task.wait(10)
                    rejoinCooldown = false
                end
            end
        end
    end)

    ExclusiveSection:AddToggle({
        Title = "Enable Fish Notification UI",
        Description = "Show on-screen notification when catching a fish",
        Default = _G.Config.FishNotificationEnabled or false,
        Callback = function(Value)
            _G.Config.FishNotificationEnabled = Value
        end
    })

    -- Server Uptime Monitor loop
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local uptimeText = "0D 0H 0M"
                local foundUptime = false
                pcall(function()
                    local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("serverInfo")
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
                    if StatusUptimeParagraph.SetDesc then
                        StatusUptimeParagraph:SetDesc(contentText)
                    elseif StatusUptimeParagraph.Set then
                        StatusUptimeParagraph:Set({ Title = "Server Uptime Status", Content = contentText })
                    end
                end
            end)
        end
    end)

    local filterCache = nil

    local function clearSnapCache()
        filterCache = nil
    end
    _G.ClearSnapCache = clearSnapCache

    local function buildFilterCache()
        local cache = {
            names      = {},
            relics     = {},
            rarities   = {},
            mutations  = {},
            traits     = {},
        }

        local targetManual = _G.__var and _G.__var.SnapTargetManual
        if targetManual and targetManual ~= "" then
            for t in string.gmatch(targetManual, "([^,]+)") do
                local trimmed = t:match("^%s*(.-)%s*$")
                if trimmed ~= "" then
                    table.insert(cache.names, trimmed:lower())
                end
            end
        end

        local snapRelics = _G.__var and _G.__var.SnapRelics
        if snapRelics then
            for k, v in pairs(snapRelics) do
                if type(k) == "string" and v == true then
                    table.insert(cache.relics, k:lower())
                elseif type(k) == "number" and type(v) == "string" and v ~= "" then
                    table.insert(cache.relics, v:lower())
                end
            end
        end

        local snapRarity = _G.__var and _G.__var.SnapRarity
        if snapRarity then
            if type(snapRarity) == "table" then
                for k, v in pairs(snapRarity) do
                    if type(k) == "string" and v == true then
                        -- { Rare = true, Uncommon = true } format (Linoria / Speed_Library Multi)
                        table.insert(cache.rarities, k:lower())
                    elseif type(k) == "number" and type(v) == "string" and v ~= "" then
                        -- { "Rare", "Uncommon" } array format (JSON load)
                        table.insert(cache.rarities, v:lower())
                    elseif type(v) == "string" and v ~= "" then
                        table.insert(cache.rarities, v:lower())
                    end
                end
            elseif type(snapRarity) == "string" and snapRarity ~= "" then
                table.insert(cache.rarities, snapRarity:lower())
            end
        end

        local snapMutations = _G.__var and _G.__var.SnapMutations
        if snapMutations then
            for k, v in pairs(snapMutations) do
                local val = nil
                if type(k) == "string" and v == true then
                    val = k:lower()
                elseif type(k) == "number" and type(v) == "string" and v ~= "" then
                    val = v:lower()
                elseif type(v) == "string" and v ~= "" then
                    val = v:lower()
                end

                if val then
                    if val == "shiny" or val == "sparkling" then
                        table.insert(cache.traits, val)
                    else
                        table.insert(cache.mutations, val)
                    end
                end
            end
        end

        -- Debug log
        if #cache.rarities > 0 or #cache.names > 0 or #cache.relics > 0 then
            local parts = {}
            if #cache.rarities > 0 then table.insert(parts, "rarities=" .. table.concat(cache.rarities, ",")) end
            if #cache.names > 0 then table.insert(parts, "names=" .. table.concat(cache.names, ",")) end
            if #cache.relics > 0 then table.insert(parts, "relics=" .. table.concat(cache.relics, ",")) end
            warn("[SnapFilter] Cache built: " .. table.concat(parts, " | "))
        end

        filterCache = cache
        return cache
    end

    local function checkSnapFilter(fishData)
        if not fishData then return true end

        local cache = filterCache or buildFilterCache()

        local hasNameFilter     = (#cache.names > 0)
        local hasRelicFilter    = (#cache.relics > 0)
        local hasRarityFilter   = (#cache.rarities > 0)
        local hasMutationFilter = (#cache.mutations > 0 or #cache.traits > 0)

        if not hasNameFilter and not hasRelicFilter and not hasRarityFilter and not hasMutationFilter then
            return true
        end

        local fishName = fishData.Name or fishData.name or "Unknown"
        local fName = fishName:lower()

        -- Retrieve rarity directly from fishData first!
        local rarity = fishData.Rarity or fishData.rarity
        if not rarity then
            local currentFishLib = getFishLib()
            local fishInfo = currentFishLib and (currentFishLib[fishName] or (fishData.Id and currentFishLib[fishData.Id]))
            if fishInfo then
                rarity = fishInfo.Rarity or fishInfo.rarity
            end
        end
        if not rarity then
            rarity = "Common"
        end
        local fRarity = tostring(rarity):lower()

        local isShiny = fishData.Shiny or false
        local isSparkling = fishData.Sparkling or false
        local mutation = fishData.Mutation

        local nameMatch = false
        if hasNameFilter then
            for _, t in ipairs(cache.names) do
                if fName:find(t, 1, true) then
                    nameMatch = true
                    break
                end
            end
        end

        local relicMatch = false
        if hasRelicFilter then
            for _, t in ipairs(cache.relics) do
                if fName:find(t, 1, true) then
                    relicMatch = true
                    break
                end
            end
        end

        local rarityMatch = false
        if hasRarityFilter then
            for _, t in ipairs(cache.rarities) do
                if fRarity == t or fRarity:find(t, 1, true) then
                    rarityMatch = true
                    break
                end
            end
        end

        local mutationMatch = false
        if hasMutationFilter then
            local traitOK = (#cache.traits == 0)
            if not traitOK then
                for _, tr in ipairs(cache.traits) do
                    if (tr == "shiny" and isShiny) or (tr == "sparkling" and isSparkling) then
                        traitOK = true
                        break
                    end
                end
            end

            local mutOK = (#cache.mutations == 0)
            if not mutOK and mutation then
                local currentMutLib = getMutLib()
                local mutLibData = currentMutLib and (currentMutLib.Mutations or currentMutLib)
                local mutDisplay = mutation
                if mutLibData and mutLibData[mutation] and mutLibData[mutation].Display then
                    mutDisplay = mutLibData[mutation].Display
                end

                local mLower        = mutation:lower()
                local mDisplayLower = mutDisplay:lower()
                for _, t in ipairs(cache.mutations) do
                    if mLower:find(t, 1, true) or mDisplayLower:find(t, 1, true) then
                        mutOK = true
                        break
                    end
                end
            end

            mutationMatch = (traitOK and mutOK)
        end

        local anyActive = hasRelicFilter or hasNameFilter or hasRarityFilter or hasMutationFilter
        if not anyActive then return true end

        -- Jika Rarity DAN Mutation sama-sama dipilih/aktif, gunakan AND logic (harus Rarity Match DAN Mutation Match)
        local rarityAndMutationOK = true
        if hasRarityFilter and hasMutationFilter then
            rarityAndMutationOK = (rarityMatch and mutationMatch)
        elseif hasRarityFilter then
            rarityAndMutationOK = rarityMatch
        elseif hasMutationFilter then
            rarityAndMutationOK = mutationMatch
        else
            rarityAndMutationOK = false
        end

        local shouldKeep = false
        if (hasRarityFilter or hasMutationFilter) and rarityAndMutationOK then
            shouldKeep = true
        end
        if hasRelicFilter and relicMatch then
            shouldKeep = true
        end
        if hasNameFilter and nameMatch then
            shouldKeep = true
        end

        return shouldKeep
    end
    _G.CheckSnapFilter = checkSnapFilter

    -- Global Catch Notification Helper (Instant Catch Notifications & Webhooks)
    local function showCatchNotification(fishData)
        if not fishData then return end
        local fishName = fishData.Name or "Unknown"
        local fishWeight = fishData.Weight or 0
        local isShiny = fishData.Shiny or false
        local isSparkling = fishData.Sparkling or false
        local mutation = fishData.Mutation
        local currentFishLib = getFishLib()
        local fishInfo = currentFishLib and currentFishLib[fishName]
        local price = 0
        local rarity = nil
        if fishInfo then
            rarity = fishInfo.Rarity
            price = fishInfo.Price or 0
            if fishWeight and fishInfo.WeightPool then
                price = math.ceil(fishWeight / (fishInfo.WeightPool[2] / 10) * (fishInfo.Price or 0))
            end
            if isShiny then price = math.ceil(price * 1.85) end
            if isSparkling then price = math.ceil(price * 1.85) end
            local currentMutLib = getMutLib()
            if mutation and currentMutLib and currentMutLib.Mutations and currentMutLib.Mutations[mutation] then
                price = math.ceil(price * (currentMutLib.Mutations[mutation].PriceMultiply or 1))
            end
        end
        local mutationParts = {}
        if isShiny then table.insert(mutationParts, "Shiny") end
        if isSparkling then table.insert(mutationParts, "Sparkling") end
        if mutation and mutation ~= "None" and mutation ~= "" then
            table.insert(mutationParts, mutation)
        end
        local mutationDisplay = (#mutationParts > 0) and table.concat(mutationParts, ", ") or "None"

        -- 1. Show Screen Notification
        if _G.Config.FishNotificationEnabled then
            if #activeNotifications >= MAX_NOTIFICATIONS then
                local old = table.remove(activeNotifications, 1)
                if old then pcall(function() task.cancel(old) end) end
            end
            local t = task.spawn(function()
                createFishNotification(fishName, mutationDisplay, fishWeight, price, rarity)
            end)
            table.insert(activeNotifications, t)
        end

        -- 2. Send Discord Webhook
        if _G.Config.DiscordWebhookEnabled and _G.Config.DiscordWebhookURL and _G.Config.DiscordWebhookURL ~= "" then
            task.spawn(function()
                local requestFunc = (syn and syn.request) or (http and http.request) or request or http_request
                if not requestFunc then return end
                local rarityColors = {
                    ["Common"] = 5921370,
                    ["Uncommon"] = 5294195,
                    ["Unusual"] = 14392656,
                    ["Rare"] = 286207,
                    ["Legendary"] = 16766720,
                    ["Mythical"] = 16724889,
                    ["Exotic"] = 16737228,
                    ["Limited"] = 16747520,
                    ["Event"] = 65437,
                    ["Relic"] = 3394559,
                    ["Aurora"] = 3066993,
                    ["Admin"] = 16776960,
                    ["Secret"] = 0
                }
                local embedColor = rarityColors[rarity] or 5921370
                local cleanName = fishName:gsub(" ", "_")
                local thumbnail = "https://fischipedia.org/wiki/Special:Redirect/file/" .. cleanName .. ".png"
                mutationDisplay = (mutationDisplay and mutationDisplay ~= "None") and mutationDisplay or "Standard"
                local fields = {
                    { name = "🧬 Mutation", value = mutationDisplay, inline = true },
                    { name = "⚖️ Weight", value = string.format("%.1f kg", fishWeight or 0), inline = true },
                    { name = "💰 Value", value = "$" .. tostring(price or 0), inline = true },
                    { name = "✨ Rarity", value = rarity or "Common", inline = true },
                }
                local player = Players.LocalPlayer
                local payload = {
                    username = "Shield Team Notification",
                    avatar_url = "https://i.imgur.com/4M34hi2.png",
                    embeds = {{
                        title = "🎣 " .. fishName .. " Caught!",
                        url = "https://fisch.fandom.com/wiki/" .. cleanName,
                        description = "Successfully caught by ||" .. player.Name .. "||",
                        color = embedColor,
                        fields = fields,
                        thumbnail = { url = thumbnail },
                        footer = {
                            text = "Shield Team Client • " .. os.date("%Y-%m-%d"),
                            icon_url = "https://i.imgur.com/4M34hi2.png"
                        },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    }}
                }
                pcall(function()
                    requestFunc({
                        Url = _G.Config.DiscordWebhookURL,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = game:GetService("HttpService"):JSONEncode(payload)
                    })
                end)
            end)
        end
    end
    _G.ShowCatchNotification = showCatchNotification

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
            -- Simpan posisi player saat ini sebelum save config
            local player = game.Players.LocalPlayer
            local char = player and player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                _G.Config.SavedPosition = hrp.CFrame
            end

            if getgenv().saveConfig then
                getgenv().saveConfig(selectedConfig)
            else
                if not isfolder(configFolder) then makefolder(configFolder) end
                writefile(configFolder .. selectedConfig .. ".json", HttpService:JSONEncode(_G.Config))
            end
            refreshConfigs()
        end
    })
    AutoSaveSection:AddButton({
        Title = "Load Config",
        Callback = function()
            if getgenv().loadConfig then
                getgenv().loadConfig(selectedConfig)
            else
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
        end
    })
    AutoSaveSection:AddButton({
        Title = "Load Only",
        Description = "No teleport",
        ClipsDescendants = true,
        Callback = function()
            if getgenv().loadConfig then
                getgenv().loadConfig(selectedConfig, false)
            end
        end
    })
    AutoSaveSection:AddButton({
        Title = "Teleport Now",
        Description = "Go to saved position",
        ClipsDescendants = true,
        Callback = function()
            if _G.Config.SavedPosition and getgenv().teleportToSavedPosition then
                getgenv().teleportToSavedPosition(_G.Config.SavedPosition)
            else
                warn("[Config] No position saved!")
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

    if _G.Config.AutoHopCosmic then
        if AutoCosmic then AutoCosmic.SetEnabled(true) end
    end
end

return Init
