local ReplicatedStorage = game:GetService("ReplicatedStorage")
local storageFolder = ReplicatedStorage:WaitForChild("Shield_Core", 10)

if not storageFolder then
    warn("[NewFish5] Core folder not found in ReplicatedStorage!")
    return
end

local function getMod(name)
    local val = storageFolder:FindFirstChild(name)
    if val then
        if val:IsA("Folder") then
            local fullSrc = ""
            local count = #val:GetChildren()
            for i = 1, count do
                local chunk = val:FindFirstChild(tostring(i))
                if chunk then
                    fullSrc = fullSrc .. chunk.Value
                end
            end
            return loadstring(fullSrc)()
        else
            return loadstring(val.Value)()
        end
    else
        warn("[NewFish5] Missing module:", name)
    end
end

local Config = getMod("Config")
local Utils = getMod("Utils")
local InstantBobber = getMod("InstantBobber")
local AutoCast = getMod("AutoCast")
local AutoReel = getMod("AutoReel")
local PerfectCatch = getMod("PerfectCatch")
local AutoShake = getMod("AutoShake")
local AutoBuyBait = getMod("AutoBuyBait")
local AutoBuyRod = getMod("AutoBuyRod")
local AutoSell = getMod("AutoSell")
local TeleportArea = getMod("TeleportArea")
local TeleportNPC = getMod("TeleportNPC")
local TeleportZone = getMod("TeleportZone")
local ESP = getMod("ESP")
local AutoMine = getMod("AutoMine")
local AutoQuest = getMod("AutoQuest")
local WalkSpeed = getMod("WalkSpeed")
local MiscFishing = getMod("MiscFishing")
local DisableOxygen = getMod("DisableOxygen")

local executorName = Utils and Utils.DetectExecutor() or "Unknown"

local GUI_URL = "https://raw.githubusercontent.com/KAN-FISCH/tesss/refs/heads/main/tester26"
local _guiOk, Speed_Library = pcall(function()
    return loadstring(game:HttpGet(GUI_URL))()
end)

if not (_guiOk and Speed_Library) then
    warn("[NewFish5] Gagal load Speed_Library!")
    return
end

    local function formatSecondsToReadable(secs)
        local ok, num = pcall(function() return tonumber(secs) end)
        if not ok or not num or num <= 0 then return "Expired" end
        num = math.floor(num)
        local years  = math.floor(num / (365 * 86400))
        local months = math.floor((num % (365 * 86400)) / (30 * 86400))
        local days   = math.floor((num % (30 * 86400)) / 86400)
        local hours  = math.floor((num % 86400) / 3600)
        local mins   = math.floor((num % 3600) / 60)
        if years > 0 then
            if months > 0 then
                return years .. " Tahun " .. months .. " Bulan"
            end
            return years .. " Tahun"
        elseif months > 0 then
            return months .. " Bulan " .. days .. " Hari"
        elseif days > 0 then
            return days .. " Hari " .. hours .. " Jam " .. mins .. " Mnt"
        elseif hours > 0 then
            return hours .. " Jam " .. mins .. " Mnt"
        else
            return mins .. " Mnt"
        end
    end

    local function formatTimestamp(ts)
        local ok, num = pcall(function() return tonumber(ts) end)
        if not ok or not num then return tostring(ts) end
        if num > 9999999999 then num = math.floor(num / 1000) end
        local t = os.date("*t", num)
        if not t then return tostring(ts) end
        return string.format("%02d/%02d/%04d %02d:%02d", t.day, t.month, t.year, t.hour, t.min)
    end

    local function validateKey(Key)
        local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
        local url = "https://key.shieldteam.asia/api/validate?key=" .. tostring(Key) .. "&hwid=" .. HWID
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            local Http = game:GetService("HttpService")
            local data = nil
            local jsonSuccess, jsonErr = pcall(function()
                data = Http:JSONDecode(response)
            end)
            if jsonSuccess and data then
                if data.status then
                    local sisaWaktu = "Active"
                    if data.timeLeft and tonumber(data.timeLeft) then
                        sisaWaktu = formatSecondsToReadable(data.timeLeft)
                    end

                    local waktuExpired = "Active"
                    local rawExpiry = data.expiry or data.expired or data.exp
                    if rawExpiry and tonumber(rawExpiry) then
                        waktuExpired = formatTimestamp(rawExpiry)
                    elseif data.timeLeft and tonumber(data.timeLeft) then
                        local tl = tonumber(data.timeLeft)
                        local expiryTs = os.time() + math.floor(tl)
                        waktuExpired = formatTimestamp(expiryTs)
                    end

                    return data.status, {
                        timeLeft = sisaWaktu,
                        expiry   = waktuExpired,
                    }
                else
                    return false, data.msg or "Key tidak valid."
                end
            end
        end
        return false, "Gagal terhubung ke server validasi."
    end

    local function saveSavedKey(Key)
        if writefile then
            pcall(function()
                writefile("ShieldKey.txt", tostring(Key))
            end)
        end
    end

    local function getSavedKey()
        if isfile and isfile("ShieldKey.txt") and readfile then
            local ok, content = pcall(readfile, "ShieldKey.txt")
            if ok then
                return content:gsub("%s+", "")
            end
        end
        return ""
    end

    local function createPremiumKeyUI(Info, Exclusive, AutosTab, AreaTab, EspTab, Misc, SettingsTab, Speed_Library)
        local genvKey = (getgenv and getgenv().Key) or ""
        local globalKey = tostring(_G.Key or "")
        local savedKey = getSavedKey()

        local userKey = ""
        if genvKey ~= "" then
            userKey = genvKey
        elseif globalKey ~= "" and globalKey ~= "nil" then
            userKey = globalKey
        elseif savedKey ~= "" then
            userKey = savedKey
        end

        if userKey ~= "" then
            _G.Key = userKey
            getgenv().Key = userKey
        end

        local function Create(Name, Properties, Parent)
            local _instance = Instance.new(Name)
            for i, v in pairs(Properties) do
                _instance[i] = v
            end
            if Parent then
                _instance.Parent = Parent
            end
            return _instance
        end

        local ScrolLayers = Info.ScrolLayers
        local LayersFolder = ScrolLayers.Parent
        local LayersReal = LayersFolder.Parent
        local Layers = LayersReal.Parent
        local PanelsArea = Layers.Parent
        local ContentArea = PanelsArea.Parent
        local ContentHeader = ContentArea:FindFirstChild("ContentHeader")

        local NameTab = ContentHeader:FindFirstChild("NameTab")
        local NameTabSub = ContentHeader:FindFirstChild("NameTabSub")
        local LayersRight = PanelsArea:FindFirstChild("LayersRight")

        local SubTabBar = Create("Frame", {
            Name = "SubTabBar",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false
        }, ContentHeader)

        local subTabList = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 20),
            VerticalAlignment = Enum.VerticalAlignment.Center
        }, SubTabBar)

        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 15)
        }, SubTabBar)

        local infoEventBtn = Create("TextButton", {
            Name = "InfoEventBtn",
            Text = "Info Event",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(160, 160, 180),
            Size = UDim2.new(0, 80, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, SubTabBar)

        local infoEventUnderline = Create("Frame", {
            Name = "Underline",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226),
            BorderSizePixel = 0,
            Visible = false
        }, infoEventBtn)

        local premKeyBtn = Create("TextButton", {
            Name = "PremKeyBtn",
            Text = "Premium Key System",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 130, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 2
        }, SubTabBar)

        local premKeyUnderline = Create("Frame", {
            Name = "Underline",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226),
            BorderSizePixel = 0,
            Visible = true
        }, premKeyBtn)

        local PremiumKeyPage = Create("Frame", {
            Name = "PremiumKeyPage",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = true
        }, PanelsArea)

        local leftCol = Create("Frame", {
            Name = "LeftColumn",
            Size = UDim2.new(0.5, -6, 1, -26),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, PremiumKeyPage)

        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        }, leftCol)

        local rightCol = Create("Frame", {
            Name = "RightColumn",
            Size = UDim2.new(0.5, -6, 1, -26),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1
        }, PremiumKeyPage)

        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        }, rightCol)

        local leftTitleFrame = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, leftCol)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6023426915", -- Crown
            ImageColor3 = Color3.fromRGB(138, 43, 226),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, -10)
        }, leftTitleFrame)

        Create("TextLabel", {
            Text = "Premium Key System",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 30, 0, 2),
            Size = UDim2.new(1, -30, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, leftTitleFrame)

        Create("TextLabel", {
            Text = "Masukkan key premium Anda untuk unlock fitur premium.",
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            Position = UDim2.new(0, 30, 0, 16),
            Size = UDim2.new(1, -30, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, leftTitleFrame)

        local inputCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 2
        }, leftCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, inputCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, inputCard)

        local textInputBg = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 28),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = Color3.fromRGB(12, 12, 16),
            BorderSizePixel = 0
        }, inputCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, textInputBg)
        Create("UIStroke", { Color = Color3.fromRGB(35, 35, 45), Thickness = 1, Transparency = 0.5 }, textInputBg)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031087405", -- Key icon
            ImageColor3 = Color3.fromRGB(120, 120, 130),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 8, 0.5, -6)
        }, textInputBg)

        local keyTextBox = Create("TextBox", {
            PlaceholderText = "",
            Text = userKey,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, textInputBg)

        local censorLabel = Create("TextLabel", {
            Text = (userKey and #userKey > 0) and string.rep("•", #userKey) or "Masukkan Premium Key Anda...",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = (userKey and #userKey > 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(90, 90, 100),
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, textInputBg)

        keyTextBox:GetPropertyChangedSignal("Text"):Connect(function()
            userKey = keyTextBox.Text
            if #userKey > 0 then
                censorLabel.Text = string.rep("•", #userKey)
                censorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                censorLabel.Text = "Masukkan Premium Key Anda..."
                censorLabel.TextColor3 = Color3.fromRGB(90, 90, 100)
            end
        end)

        local validateBtn = Create("TextButton", {
            Text = "Validate Key",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, -12, 0, 28),
            Position = UDim2.new(0, 6, 0, 40),
            BackgroundColor3 = Color3.fromRGB(120, 60, 210),
            BorderSizePixel = 0
        }, inputCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, validateBtn)
        local btnGrad = Create("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 30, 160))
            }
        }, validateBtn)

        local shieldIcon = Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031068433", -- Shield / Ribbon style check
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, -46, 0.5, -6)
        }, validateBtn)

        local featuresCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 95),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 3
        }, leftCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, featuresCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, featuresCard)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6034825996", -- Sparkles
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 8, 0, 6)
        }, featuresCard)

        Create("TextLabel", {
            Text = "Keunggulan Premium",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Position = UDim2.new(0, 24, 0, 4),
            Size = UDim2.new(1, -30, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, featuresCard)

        local gridFrame = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 42),
            Position = UDim2.new(0, 6, 0, 24),
            BackgroundTransparency = 1
        }, featuresCard)

        Create("UIGridLayout", {
            CellPadding = UDim2.new(0, 4, 0, 2),
            CellSize = UDim2.new(0.5, -2, 0, 11),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, gridFrame)

        local function addFeature(text, order)
            local item = Create("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = order
            }, gridFrame)
            Create("TextLabel", {
                Text = "✓",
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextColor3 = Color3.fromRGB(160, 100, 255),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 12, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, item)
            Create("TextLabel", {
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextColor3 = Color3.fromRGB(200, 200, 210),
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, item)
        end

        addFeature("Akses Semua Fitur", 1)
        addFeature("Fitur Eksklusif", 2)
        addFeature("Auto Farming", 3)
        addFeature("Priority Support", 4)
        addFeature("Unlock Semua Area", 5)
        addFeature("Update Lebih Cepat", 6)

        local banner = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 20),
            Position = UDim2.new(0, 6, 0, 74),
            BackgroundColor3 = Color3.fromRGB(28, 15, 48),
            BorderSizePixel = 0
        }, featuresCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, banner)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031068433", -- Ribbon/Star
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 6, 0.5, -5)
        }, banner)

        Create("TextLabel", {
            Text = "Jadi bagian dari komunitas premium ShieldTeam!",
            Font = Enum.Font.GothamMedium,
            TextSize = 8,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, banner)

        local rightTitleFrame = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, rightCol)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031080356", -- Info "i"
            ImageColor3 = Color3.fromRGB(138, 43, 226),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, -10)
        }, rightTitleFrame)

        Create("TextLabel", {
            Text = "Key Information",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 30, 0, 2),
            Size = UDim2.new(1, -30, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, rightTitleFrame)

        Create("TextLabel", {
            Text = "Informasi status key Anda",
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            Position = UDim2.new(0, 30, 0, 16),
            Size = UDim2.new(1, -30, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, rightTitleFrame)

        local statusCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 2
        }, rightCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, statusCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, statusCard)

        local keyGlowFrame = Create("Frame", {
            Size = UDim2.new(0, 46, 0, 46),
            Position = UDim2.new(0, 8, 0.5, -23),
            BackgroundColor3 = Color3.fromRGB(16, 12, 28),
            BorderSizePixel = 0
        }, statusCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, keyGlowFrame)
        Create("UIStroke", { Color = Color3.fromRGB(138, 43, 226), Thickness = 1, Transparency = 0.4 }, keyGlowFrame)

        local keyHead = Create("Frame", {
            Size = UDim2.new(0, 22, 0, 22),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 3),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, keyHead)

        local keyHole = Create("Frame", {
            Size = UDim2.new(0, 9, 0, 9),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(16, 12, 28),
            BorderSizePixel = 0,
        }, keyHead)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, keyHole)

        Create("Frame", {
            Size = UDim2.new(0, 5, 0, 17),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 23),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)

        Create("Frame", {
            Size = UDim2.new(0, 8, 0, 4),
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0.5, 3, 0, 28),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)

        Create("Frame", {
            Size = UDim2.new(0, 5, 0, 4),
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0.5, 3, 0, 34),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)

        local function addStatusRow(labelText, yPos)
            Create("TextLabel", {
                Text = labelText,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(140, 140, 150),
                TextSize = 9,
                Size = UDim2.new(0, 70, 0, 14),
                Position = UDim2.new(0, 62, 0, yPos),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, statusCard)

            local valLbl = Create("TextLabel", {
                Text = "-",
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(210, 210, 220),
                TextSize = 9,
                Size = UDim2.new(1, -140, 0, 14),
                Position = UDim2.new(0, 132, 0, yPos),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, statusCard)
            return valLbl
        end

        Create("TextLabel", {
            Text = "Status",
            Font = Enum.Font.GothamMedium,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 9,
            Size = UDim2.new(0, 70, 0, 14),
            Position = UDim2.new(0, 62, 0, 7),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, statusCard)

        local statusBadge = Create("Frame", {
            Size = UDim2.new(0, 65, 0, 14),
            Position = UDim2.new(0, 132, 0, 7),
            BackgroundColor3 = Color3.fromRGB(80, 20, 20),
            BorderSizePixel = 0
        }, statusCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }, statusBadge)

        local statusBadgeText = Create("TextLabel", {
            Text = "Belum Valid",
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(255, 100, 100),
            TextSize = 8,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        }, statusBadge)

        local typeVal = addStatusRow("Tipe Key", 24)
        local expVal = addStatusRow("Waktu Expired", 41)
        local leftVal = addStatusRow("Sisa Waktu", 58)

        local getKeyCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 76),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 3
        }, rightCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, getKeyCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, getKeyCard)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6034824707", -- Gift box
            ImageColor3 = Color3.fromRGB(160, 100, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 8, 0, 6)
        }, getKeyCard)

        Create("TextLabel", {
            Text = "Butuh Key Premium?",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(230, 230, 240),
            Position = UDim2.new(0, 26, 0, 4),
            Size = UDim2.new(1, -30, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, getKeyCard)

        Create("TextLabel", {
            Text = "Dapatkan key premium untuk membuka semua fitur eksklusif dan pengalaman terbaik!",
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextColor3 = Color3.fromRGB(150, 150, 160),
            Position = UDim2.new(0, 8, 0, 20),
            Size = UDim2.new(1, -16, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            TextWrapped = true
        }, getKeyCard)

        local getKeyBtn = Create("TextButton", {
            Text = "Dapatkan Premium Key",
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Size = UDim2.new(1, -16, 0, 24),
            Position = UDim2.new(0, 8, 0, 44),
            BackgroundColor3 = Color3.fromRGB(28, 15, 48),
            BorderSizePixel = 0
        }, getKeyCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, getKeyBtn)
        Create("UIStroke", { Color = Color3.fromRGB(138, 43, 226), Thickness = 1, Transparency = 0.6 }, getKeyBtn)

        local cartIcon = Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031265886", -- Shopping cart
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, -64, 0.5, -5)
        }, getKeyBtn)

        getKeyBtn.Activated:Connect(function()
            local link = "https://key.shieldteam.asia/"
            local setClp = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if setClp then
                setClp(link)
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Link get key berhasil disalin ke clipboard!",
                    Time = 0.5,
                    Delay = 3
                })
            else
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Link: " .. link,
                    Time = 0.5,
                    Delay = 5
                })
            end
        end)

        local footer = Create("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 1, -20),
            BackgroundTransparency = 1
        }, PremiumKeyPage)

        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031075929", -- bulb/tips icon
            ImageColor3 = Color3.fromRGB(230, 200, 50),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 6, 0.5, -5)
        }, footer)

        Create("TextLabel", {
            Text = "Tips: Dapatkan key premium hanya di server resmi ShieldTeam untuk keamanan akun Anda.",
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 8,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(0.65, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, footer)

        local footerStatus = Create("TextLabel", {
            Text = 'Status: <font color="#ffffff">Free User</font>',
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 8,
            Position = UDim2.new(0.7, 0, 0, 0),
            Size = UDim2.new(0.3, -6, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            RichText = true
        }, footer)

        local function updateKeyStatus(isValid, info)
            if isValid then
                statusBadge.BackgroundColor3 = Color3.fromRGB(120, 60, 210)
                statusBadgeText.Text = "Valid"
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)

                typeVal.Text = "Premium"

                local expStr = "Active"
                local leftStr = "Active"
                if type(info) == "string" then
                    leftStr = info
                elseif type(info) == "table" then
                    leftStr = info.timeLeft or "Active"
                    expStr = info.expiry or "Active"
                end

                expVal.Text = expStr
                leftVal.Text = leftStr

                footerStatus.Text = 'Status: <font color="#A064FF">Premium User</font>'
            else
                statusBadge.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                statusBadgeText.Text = "Belum Valid"
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 100, 100)

                typeVal.Text = "-"
                expVal.Text = "-"
                leftVal.Text = "-"

                footerStatus.Text = 'Status: <font color="#ffffff">Free User</font>'
            end
        end

        local function updateWindowTitle()
            _G.IsPremium = true

            local function scanContainer(container)
                if not container then return end
                pcall(function()
                    for _, desc in ipairs(container:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            local txt = rawget(desc, "Text") or pcall(function() return desc.Text end) and desc.Text
                            if type(txt) == "string" and txt:find("ShieldTeam") and txt:find("Executor") then
                                desc.Text = txt:gsub("|| Free ||", "|| Premium ||")
                            end
                        end
                    end
                end)
            end

            pcall(function()
                scanContainer(game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
            end)

            pcall(function()
                scanContainer(game:GetService("CoreGui"))
            end)

            pcall(function()
                if gethui then scanContainer(gethui()) end
            end)

            pcall(function()
                for _, desc in ipairs(game:GetDescendants()) do
                    if (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
                        local ok, txt = pcall(function() return desc.Text end)
                        if ok and type(txt) == "string" and txt:find("ShieldTeam") and txt:find("Executor") then
                            pcall(function() desc.Text = txt:gsub("|| Free ||", "|| Premium ||") end)
                        end
                    end
                end
            end)
        end

        local activeSubTab = "Premium Key System"

        local function switchSubTabUI(tabName)
            activeSubTab = tabName
            if tabName == "Info Event" then
                infoEventBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                infoEventUnderline.Visible = true

                premKeyBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
                premKeyUnderline.Visible = false

                Layers.Visible = true
                LayersRight.Visible = true
                PremiumKeyPage.Visible = false
            else
                infoEventBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
                infoEventUnderline.Visible = false

                premKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                premKeyUnderline.Visible = true

                Layers.Visible = false
                LayersRight.Visible = false
                PremiumKeyPage.Visible = true
            end
        end

        infoEventBtn.Activated:Connect(function()
            switchSubTabUI("Info Event")
        end)

        premKeyBtn.Activated:Connect(function()
            switchSubTabUI("Premium Key System")
        end)

        local isChecking = false
        validateBtn.Activated:Connect(function()
            if isChecking then return end
            isChecking = true

            task.spawn(function()
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Sedang memverifikasi key, mohon tunggu...",
                    Time = 0.5,
                    Delay = 3
                })

                local status, msg = validateKey(userKey)
                isChecking = false

                if status then
                    _G.Key = userKey
                    getgenv().Key = userKey
                    saveSavedKey(userKey)

                    Exclusive:Unlock()
                    AutosTab:Unlock()
                    EspTab:Unlock()
                    Misc:Unlock()
                    SettingsTab:Unlock()

                    updateKeyStatus(true, msg)
                    updateWindowTitle()

                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "✅ Sukses! Semua fitur premium berhasil dibuka.",
                        Time = 0.5,
                        Delay = 5
                    })
                else
                    updateKeyStatus(false, nil)
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "❌ Key Invalid/Expired: " .. tostring(msg or "gagal"),
                        Time = 0.5,
                        Delay = 5
                    })
                end
            end)
        end)

        local function checkInfoTabState()
            local isInfoVisible = Info.ScrolLayers.Visible
            if isInfoVisible then
                NameTab.Visible = false
                NameTabSub.Visible = false
                SubTabBar.Visible = true

                if activeSubTab == "Info Event" then
                    Layers.Visible = true
                    LayersRight.Visible = true
                    PremiumKeyPage.Visible = false
                else
                    Layers.Visible = false
                    LayersRight.Visible = false
                    PremiumKeyPage.Visible = true
                end
            else
                SubTabBar.Visible = false
                NameTab.Visible = true
                NameTabSub.Visible = true

                Layers.Visible = true
                LayersRight.Visible = true
                PremiumKeyPage.Visible = false
            end
        end

        Info.ScrolLayers:GetPropertyChangedSignal("Visible"):Connect(checkInfoTabState)
        task.spawn(checkInfoTabState)

        local autoKeySource = ""
        if (getgenv and getgenv().Key or "") ~= "" then
            autoKeySource = "getgenv"
        elseif (tostring(_G.Key or "")) ~= "" and (tostring(_G.Key or "")) ~= "nil" then
            autoKeySource = "global"
        elseif userKey ~= "" then
            autoKeySource = "saved"
        end

        if userKey ~= "" then
            task.spawn(function()
                task.wait(0.5)

                pcall(function()
                    keyTextBox.Text = userKey
                end)

                statusBadgeText.Text = "Checking..."
                statusBadge.BackgroundColor3 = Color3.fromRGB(80, 80, 40)
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 220, 100)

                local sourceLabel = (
                    autoKeySource == "getgenv" and "getgenv().Key" or
                    autoKeySource == "global" and "_G.Key" or
                    "Saved Key"
                )

                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Mendeteksi " .. sourceLabel .. "... Memverifikasi otomatis.",
                    Time = 0.5,
                    Delay = 3
                })

                local status, msg = validateKey(userKey)
                if status then
                    _G.Key = userKey
                    getgenv().Key = userKey
                    saveSavedKey(userKey)

                    Exclusive:Unlock()
                    AutosTab:Unlock()
                    EspTab:Unlock()
                    Misc:Unlock()
                    SettingsTab:Unlock()

                    updateKeyStatus(true, msg)
                    updateWindowTitle()

                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "✅ Auto-Login sukses via " .. sourceLabel .. "! Semua fitur premium dibuka.",
                        Time = 0.5,
                        Delay = 5
                    })
                else
                    updateKeyStatus(false, nil)
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "❌ Auto-Login Gagal: Key invalid/expired.",
                        Time = 0.5,
                        Delay = 4
                    })
                end
            end)
        else
            updateKeyStatus(false, nil)
        end
    end

local function setupGUI()
    local Window = Speed_Library:CreateWindow({
        Title = "ShieldTeam || NewFish5 || Executor : " .. executorName,
        ["Tab Width"] = 110,
        SizeUi = UDim2.fromOffset(630, 330)
    })

    local GrpMain = Window:CreateGroup({"Main", "rbxassetid://7733960981"})
    local GrpMore = Window:CreateGroup({"More", "rbxassetid://7733765398"})
    local GrpSettings = Window:CreateGroup({"Settings", "rbxassetid://6031280882"})

    local Info        = GrpMain:CreateTab({ "Info",     "", "Informasi & Event" })
    local FishingTab  = GrpMain:CreateTab({ "Fishing",  "", "Auto Fishing & Cast" })
    local ShopTab     = GrpMain:CreateTab({ "Shop",     "", "Auto Shop" })

    local Exclusive   = GrpMore:CreateTab({ "Exclusive", "", "Fitur Eksklusif", Locked = true })
    local AutosTab    = GrpMore:CreateTab({ "Autos",     "", "Auto Features", Locked = true })
    local AreaTab     = GrpMore:CreateTab({ "Area/TP",   "", "Area & Teleport"})
    local EspTab      = GrpMore:CreateTab({ "ESP",       "", "ESP & Visuals", Locked = true })

    local Misc        = GrpSettings:CreateTab({ "Misc",    "", "Misc & Utils", Locked = true })
    local SettingsTab = GrpSettings:CreateTab({ "Setting", "", "Pengaturan", Locked = true })

    local Infr = Info:AddSection('Info Event', true, "Left")
    createPremiumKeyUI(Info, Exclusive, AutosTab, AreaTab, EspTab, Misc, SettingsTab, Speed_Library)

    local MainSection      = FishingTab:AddSection("Fishing", true, "Left")
    local SettingFish      = FishingTab:AddSection("Fishing Setting", true, "Right")
    local FishingZone      = FishingTab:AddSection("Fishing Zone", true, "Right")
    local FishingEventZone = FishingTab:AddSection("Fishing Event Zone", true, "Left")

    local ShopBait = ShopTab:AddSection("Bait", true, "Left")
    local ShopItem = ShopTab:AddSection("Shop Item", true, "Right")
    local ShopRod  = ShopTab:AddSection("Rod", true, "Left")
    local Merlin   = ShopTab:AddSection("Merlin", true, "Right")

    local ExclusiveSection = Exclusive:AddSection("Exclusive", true, "Left")
    local AutoMineSection  = Exclusive:AddSection("Auto Mine", true, "Right")
    local AutoSaveSection  = Exclusive:AddSection("Auto Save", true, "Right")

    local AutosCollect      = AutosTab:AddSection("Auto Collect Chest", true, "Left")
    local AutosQuest        = AutosTab:AddSection("Auto Quest", true, "Left")
    local AutosJack         = AutosTab:AddSection("Auto Treasure", true, "Right")
    local AutosFavorit      = AutosTab:AddSection("Auto Fav Item/Fish", true, "Left")
    local AutosAppraise     = AutosTab:AddSection("Appraise Treasure", true, "Right")
    local AutoAppraise      = AutosTab:AddSection("Appraise", true, "Left")
    local AutoEnchant       = AutosTab:AddSection("Enchant", true, "Right")
    local Collect           = AutosTab:AddSection("Collect", true, "Left")
    local AutosSection      = AutosTab:AddSection("Auto Sell", true, "Right")
    local AuraSection       = AutosTab:AddSection("Totem", true, "Left")
    local AutoJetskiSection = AutosTab:AddSection('Auto Jetski', false, "Left")
    local FoodSection       = AutosTab:AddSection('Aquariums', false, "Right")

    local Main          = AreaTab:AddSection('Main', true, "Left")
    local SAVEPOSTION   = AreaTab:AddSection('Save Positon', true, "Right")
    local NPCSection    = AreaTab:AddSection('NPC Teleport', true, "Left")
    local BallonSection = AreaTab:AddSection('Ballon', false, "Right")

    local EspCharacterSection = EspTab:AddSection("ESP Character", true, "Left")
    local EspEventSection     = EspTab:AddSection("ESP Zone", true, "Right")
    local EspNpcSection       = EspTab:AddSection("ESP NPC", true, "Right")

    local MiscSection       = Misc:AddSection("Misc", true, "Left")
    local MiscPlayerSection = Misc:AddSection("Misc Player", true, "Right")

    local SettingsSection = SettingsTab:AddSection("Settings", true, "Left")
    local CreditsSection  = SettingsTab:AddSection("Credits", true, "Right")

        MainSection:AddDropdown({
        Title = "Reel Mode",
        Options = {"Super Instant", "Legit", "Manual"},
        Default = _G.Config.ReelMode,
        Callback = function(value)
            _G.Config.ReelMode = value
        end
    })

    MainSection:AddToggle({
        Title = "Instant Bobber",
        Default = _G.Config.InstantCast,
        Callback = function(value)
            if InstantBobber then InstantBobber(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Cast",
        Default = _G.Config.AutoCast,
        Callback = function(value)
            if AutoCast then AutoCast(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Reel",
        Default = _G.Config.AutoReel,
        Callback = function(value)
            if AutoReel then AutoReel(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Equip Rod",
        Default = _G.Config.isEquipRpd,
        Callback = function(value)
            if MiscFishing then MiscFishing.AutoEquipRod(value) end
        end
    })

        SettingFish:AddToggle({
        Title = "Auto Pasif Lullaby",
        Default = _G.Config.AutoMetronome,
        Callback = function(value)
            if MiscFishing then MiscFishing.AutoPasifLullaby(value) end
        end
    })

    SettingFish:AddToggle({
        Title = "Delete Fish Model",
        Default = _G.Config.DeleteFishModel,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteFishModel(value) end
        end
    })

    SettingFish:AddToggle({
        Title = "Delete All Map",
        Default = false,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteAllMap(value) end
        end
    })

    SettingFish:AddToggle({
        Title = "Delete All Characters",
        Default = _G.Config.DeletePlayer,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteAllCharacters(value) end
        end
    })

    SettingFish:AddSlider({
        Title = "Bar Size",
        Min = 1,
        Max = 20,
        Default = 1,
        Callback = function(value)
            if _G.__var then _G.__var.barSize = value end
        end
    })

    SettingFish:AddSlider({
        Title = "Perfect Catch %",
        Min = 0,
        Max = 100,
        Default = 0,
        Callback = function(value)
            if _G.__var then _G.__var.perfectCatchEnabled = value end
        end
    })

    SettingFish:AddSlider({
        Title = "Perfect Cast %",
        Min = 0,
        Max = 100,
        Default = 0,
        Callback = function(value)
            if _G.__var then _G.__var.perfectCastEnabled = value end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Shake",
        Default = _G.Config.AutoShake or false,
        Callback = function(value)
            if AutoShake then AutoShake(value) end
        end
    })

    AutosSection:AddToggle({
        Title = "Auto Sell",
        Default = _G.Config.AutoSell or false,
        Callback = function(value)
            if AutoSell then AutoSell(value) end
        end
    })

    getgenv().__var = {
        reelConnection = nil,
        autoReelEnabled = true,
        perfectCatchEnabled = 0,
        perfectCastEnabled = 100,
        DelayTimeFaster = 0.1,
        isReeling = false,
        AutoSnapEnabled = false,
        SnapRelics = {},
        SnapRarity = {},
        SnapTarget = "",
        SnapMutations = {},
        Hunting_Enabled = false,
        Hunting_Target = nil,
        SnapTargetManual = "",
        savedPosition = nil,
        barSize = 2,
        Notif5Counter = 0,
        lastSkipTime = os.time()
    }
    getgenv().configFolder = "ExclusiveConfigs/"
    getgenv().currentConfigFile = "Default"
    getgenv().savedConfigsList = {}
    getgenv().lastSaveTime = os.time()
    getgenv().totalSaves = 0
    getgenv().ConfigStatusParagraph = nil

    getgenv().teleportToSavedPosition = function(position)
        if not position or not position.X or not position.Y or not position.Z then
            return false
        end

        task.spawn(function()
            local player = game.Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                root.CFrame = CFrame.new(position.X, position.Y, position.Z)
                task.wait(0.5)
            end
        end)
        return true
    end

    getgenv().deepCopy = function(original)
        if type(original) ~= "table" then
            return original
        end
        local copy = {}
        for key, value in pairs(original) do
            local typeKey = type(key)
            local typeVal = type(value)

            if typeKey == "string" or typeKey == "number" then
                if typeKey == "string" and key:match("^<Function>") then
                else
                    if typeVal == "table" then
                        copy[key] = getgenv().deepCopy(value)
                    elseif typeVal == "string" or typeVal == "number" or typeVal == "boolean" then
                        copy[key] = value
                    end
                end
            end
        end
        return copy
    end

    getgenv().loadConfig = function(configName, autoTeleport)
        configName = configName or getgenv().currentConfigFile
        if autoTeleport == nil then 
            autoTeleport = _G.Config.AutoTeleportOnLoad 
        end

        local filePath = getgenv().configFolder .. configName .. ".json"
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
                        _G.Config[key] = value
                    else
                        _G.Config[key] = value
                    end
                end

                for key, value in pairs(loadedVar) do
                    if key ~= "reelConnection" and key ~= "isReeling" then
                        getgenv().__var[key] = value
                    end
                end

                getgenv().currentConfigFile = configName
                getgenv().lastSaveTime = os.time()

                if autoTeleport and _G.Config.SavedPosition then
                    getgenv().teleportToSavedPosition(_G.Config.SavedPosition)
                end

                return true
            end
        end

        warn("[Config] Load failed: " .. configName)
        return false
    end

    if isfolder and isfolder(getgenv().configFolder) and listfiles then
        local files = listfiles(getgenv().configFolder)
        local found = {}
        for _, file in pairs(files) do
            if type(file) == "string" and file:match("%.json$") then
                local fileName = file:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(found, fileName)
                end
            end
        end
        table.sort(found)
        if #found > 0 then
            getgenv().loadConfig(found[1], true)
        end
    end

    local InitExclusive = getMod("Exclusive")
    if not InitExclusive then
        pcall(function()
            InitExclusive = require(script.Parent.Modules.Exclusive)
        end)
    end
    if InitExclusive then
        local function patchUI(obj)
            if type(obj) ~= "table" then return obj end
            if not obj.AddSeperator then
                obj.AddSeperator = function() end
            end
            if not obj.AddSeparator then
                obj.AddSeparator = function() end
            end
            if obj.AddSection then
                local oldAddSection = obj.AddSection
                obj.AddSection = function(self, ...)
                    local newSec = oldAddSection(self, ...)
                    if newSec then patchUI(newSec) end
                    return newSec
                end
            end
            if obj.AddParagraph then
                local oldAddPara = obj.AddParagraph
                obj.AddParagraph = function(self, ...)
                    local para = oldAddPara(self, ...)
                    if para and not para.SetDesc then
                        para.SetDesc = function(s, text)
                            if s.Set then pcall(function() s:Set({Content = text}) end) end
                        end
                    end
                    return para
                end
            end
            return obj
        end

        getgenv().Info = patchUI(Info)
        getgenv().FishingTab = patchUI(FishingTab)
        getgenv().ShopTab = patchUI(ShopTab)
        getgenv().Exclusive = patchUI(Exclusive)
        getgenv().AutosTab = patchUI(AutosTab)
        getgenv().AreaTab = patchUI(AreaTab)
        getgenv().EspTab = patchUI(EspTab)
        getgenv().Misc = patchUI(Misc)
        getgenv().SettingsTab = patchUI(SettingsTab)

        patchUI(ExclusiveSection)
        patchUI(AutoMineSection)
        patchUI(AutoSaveSection)
        patchUI(NPCSection)
        patchUI(BallonSection)
        patchUI(EspCharacterSection)
        patchUI(EspEventSection)
        patchUI(EspNpcSection)

        getgenv().startAutoClaimMulti = function()
            task.spawn(function()
                while _G.Config.AutoClaimMulti do
                    local player = game.Players.LocalPlayer
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then task.wait(2) continue end
                    
                    local oldCFrame = hrp.CFrame
                    local itemsClaimed = false
                    local targetItems = {"Lunar Thread", "Starfall Totem", "Cosmic Relic", "Meteoric"}

                    local function searchForItems(parent, depth)
                        if depth > 10 then return false end

                        for _, child in ipairs(parent:GetChildren()) do
                            if not _G.Config.AutoClaimMulti then return false end
                            for _, itemName in ipairs(targetItems) do
                                if child.Name == itemName then
                                    local prompt = nil
                                    local targetPosition = nil
                                    local center = child:FindFirstChild("Center")
                                    if center then
                                        for _, centerChild in ipairs(center:GetChildren()) do
                                            if centerChild:IsA("ProximityPrompt") and centerChild.Enabled then
                                                prompt = centerChild
                                                break
                                            end
                                        end
                                    end
                                    if not prompt then
                                        for _, itemChild in ipairs(child:GetChildren()) do
                                            if itemChild:IsA("ProximityPrompt") and itemChild.Enabled then
                                                prompt = itemChild
                                                break
                                            end
                                        end
                                    end
                                    if child:IsA("BasePart") then
                                        targetPosition = child.CFrame
                                    elseif child:IsA("Model") and child.PrimaryPart then
                                        targetPosition = child.PrimaryPart.CFrame
                                    elseif child:IsA("Model") then
                                        for _, modelChild in ipairs(child:GetChildren()) do
                                            if modelChild:IsA("BasePart") then
                                                targetPosition = modelChild.CFrame
                                                break
                                            end
                                        end
                                    end
                                    if prompt and targetPosition then
                                        print("Teleporting to claim " .. itemName .. "...")
                                        hrp.CFrame = targetPosition + Vector3.new(0, 3, 0)
                                        task.wait(0.5)
                                        local claimAttempts = 0
                                        while _G.Config.AutoClaimMulti and prompt and prompt.Parent and prompt.Enabled and claimAttempts < 10 do
                                            pcall(function()
                                                fireproximityprompt(prompt)
                                            end)
                                            task.wait(0.2)
                                            claimAttempts = claimAttempts + 1
                                        end

                                        if not prompt.Enabled then
                                            print("Successfully claimed " .. itemName .. "!")
                                            itemsClaimed = true
                                        end

                                        task.wait(0.5)
                                    end
                                end
                            end
                            if child:IsA("Folder") or child:IsA("Model") or child.Name == "StarCrater" or child.Name == "Root" then
                                if searchForItems(child, depth + 1) then
                                    itemsClaimed = true
                                end
                            end
                        end
                        return itemsClaimed
                    end
                    
                    searchForItems(workspace, 0)
                    if _G.Config.AutoClaimMulti and itemsClaimed and hrp then
                        hrp.CFrame = oldCFrame
                        print("Returned to original position")
                    end
                    task.wait(2)
                end
            end)
        end

        InitExclusive(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
    end

    ExclusiveSection:AddButton({
        Title = "Save Config",
        Callback = function()
            local HttpService = game:GetService("HttpService")
            pcall(function()
                writefile("ShieldTeamConfig.json", HttpService:JSONEncode(_G.Config))
            end)
        end
    })

    ExclusiveSection:AddToggle({
        Title = "Auto Sell",
        Default = _G.Config.AutoSell or false,
        Callback = function(value)
            if AutoSell then AutoSell(value) end
        end
    })

    MiscPlayerSection:AddSlider({
        Title = "WalkSpeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            if WalkSpeed then WalkSpeed(value) end
        end
    })

    MiscSection:AddToggle({
        Title = "Disable Oxygen",
        Default = false,
        Callback = function(value)
            if DisableOxygen then DisableOxygen(value) end
        end
    })

    EspCharacterSection:AddToggle({
        Title = "ESP Player",
        Default = false,
        Callback = function(value)
            if ESP then ESP("Players", value) end
        end
    })
    
    CreditsSection:AddParagraph({
        Title = "ShieldTeam || NewFish5",
        Content = "Full GUI Layout Re-added.\nSemua Tab & Section sudah dibuatkan.\nSilahkan tambahkan Toggle lebih lanjut jika perlu!"
    })

end

setupGUI()
print("[NewFish5] GUI Loaded Successfully from ReplicatedStorage!")

task.spawn(function()
    task.wait(1)
    if _G.Config then
        if InstantBobber and _G.Config.InstantCast then InstantBobber(true) end
        if AutoCast and _G.Config.AutoCast then AutoCast(true) end
        if AutoReel and _G.Config.AutoReel then AutoReel(true) end
        if AutoShake and _G.Config.AutoShake then AutoShake(true) end
        if AutoSell and _G.Config.AutoSell then AutoSell(true) end
        if MiscFishing and MiscFishing.AutoEquipRod and _G.Config.isEquipRpd then MiscFishing.AutoEquipRod(true) end
    end
end)

