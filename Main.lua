-- Guard: Cegah double execute / double UI
if getgenv().__NewFish5_Loaded then
    warn("[NewFish5] Already loaded! Skipping re-execution.")
    return
end
getgenv().__NewFish5_Loaded = true

local Config = loadstring(readfile("ShielDTeam/NewFish5_Source/Config.lua"))()
local Utils = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/Utils.lua"))()
local InstantBobber = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/InstantBobber.lua"))()
local AutoCast = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoCast.lua"))()
local AutoReel = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoReel.lua"))()
local PerfectCatch = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/PerfectCatch.lua"))()
local AutoShake = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoShake.lua"))()
local AutoBuyBait = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoBuyBait.lua"))()
local AutoBuyRod = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoBuyRod.lua"))()
local AutoSell = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoSell.lua"))()
local TeleportArea = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/TeleportArea.lua"))()
local TeleportNPC = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/TeleportNPC.lua"))()
local TeleportZone = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/TeleportZone.lua"))()
local ESP = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/ESP.lua"))()
local AutoMine = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoMine.lua"))()
local AutoQuest = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AutoQuest.lua"))()
local WalkSpeed = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/WalkSpeed.lua"))()
local DisableOxygen = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/DisableOxygen.lua"))()
local Exclusive = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/Exclusive.lua"))()
local Shop = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/Shop.lua"))()
local Autos = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/Autos.lua"))()
local AreaTP = loadstring(readfile("ShielDTeam/NewFish5_Source/Modules/AreaTP.lua"))()
local executorName = Utils.DetectExecutor()

local GUI_URL = "https://key.shieldteam.asia/raw/Fisch/tester26.txt"
local Fallback_GUI_URL = "https://raw.githubusercontent.com/KAN-FISCH/Fisch/refs/heads/main/tester26.txt"

local function httpGetWithTimeout(url, timeout)
    local result = nil
    local success = false
    local completed = false
    
    local thread = coroutine.running()
    
    task.spawn(function()
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if not completed then
            completed = true
            success = ok
            result = res
            task.spawn(thread)
        end
    end)
    
    task.delay(timeout or 5, function()
        if not completed then
            completed = true
            success = false
            result = "Timeout"
            task.spawn(thread)
        end
    end)
    
    coroutine.yield()
    return success, result
end

local _guiOk, Speed_Library = false, nil
for attempt = 1, 5 do
    local targetURL = (attempt % 2 == 1) and GUI_URL or Fallback_GUI_URL
    local success, res = httpGetWithTimeout(targetURL, 5)
    local isHtml = success and res and (res:sub(1, 15):lower():match("<!doctype html") or res:sub(1, 10):lower():match("<html"))
    if success and res and not isHtml then
        local fn, err = loadstring(res)
        if fn then
            local runSuccess, runRes = pcall(fn)
            if runSuccess then
                _guiOk = true
                Speed_Library = runRes
                break
            end
        end
    end
    task.wait(1)
end

if not (_guiOk and Speed_Library) then
    warn("[NewFish5] Gagal load Speed_Library!")
    return
end

local autoExecQueued = false
local function autoExecute()
    if not _G.Config.AutoExecute then return end
    if autoExecQueued then return end

    pcall(function()
        local queueonteleport = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not queueonteleport then return end

        local currentAutoCast = _G.Config.AutoCast
        local currentInstantCast = _G.Config.InstantCast
        local currentAutoReel = _G.Config.AutoReel
        local currentInstantReel = _G.Config.InstantReel
        local currentFarmFish = _G.Config['Farm Fish']
        local currentAutoClaimMulti = _G.Config.AutoClaimMulti
        local currentAutoHopCosmic = _G.Config.AutoHopCosmic
        local currentKey = getgenv().Key or script_key or _G.Key or ""

        if currentKey == "" then return end

        local scriptUrl = "https://raw.githubusercontent.com/KAN-FISCH/tesss/refs/heads/main/UITES"
        local scriptToExecute = string.format([[
            task.wait(5)
            pcall(function()
                getgenv().Key = %q
                if not _G.Config then _G.Config = {} end
                _G.Config.AutoCast = %s
                _G.Config.InstantCast = %s
                _G.Config.AutoReel = %s
                _G.Config.InstantReel = %s
                _G.Config['Farm Fish'] = %s
                _G.Config.AutoClaimMulti = %s
                _G.Config.AutoHopCosmic = %s
                _G.Config.AutoExecute = true
                loadstring(game:HttpGet(%q))()
            end)
        ]], currentKey, tostring(currentAutoCast), tostring(currentInstantCast), tostring(currentAutoReel), tostring(currentInstantReel), tostring(currentFarmFish), tostring(currentAutoClaimMulti), tostring(currentAutoHopCosmic), scriptUrl)

        queueonteleport(scriptToExecute)
        autoExecQueued = true
    end)
end

if game.Players.LocalPlayer.Character then
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(autoExecute)
    end
end
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(autoExecute)
    end
end)

task.spawn(function()
    task.wait(1)
    autoExecute()
end)

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
    local PrivateServerTab = GrpMain:CreateTab({ "VIP Server", "", "Private Server List" })

    local Exclusive   = GrpMore:CreateTab({ "Exclusive", "", "Fitur Eksklusif", Locked = true })
    local AutosTab    = GrpMore:CreateTab({ "Autos",     "", "Auto Features", Locked = true })
    local AreaTab     = GrpMore:CreateTab({ "Area/TP",   "", "Area & Teleport"})
    local EspTab      = GrpMore:CreateTab({ "ESP",       "", "ESP & Visuals", Locked = true })

    local Misc        = GrpSettings:CreateTab({ "Misc",    "", "Misc & Utils", Locked = true })
    local SettingsTab = GrpSettings:CreateTab({ "Setting", "", "Pengaturan", Locked = true })

    local Infr = Info:AddSection('Info Event', true, "Left")

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

    MainSection:AddToggle({
        Title = "Instant Bobber",
        Default = _G.Config.InstantCast or false,
        Callback = function(value)
            InstantBobber(value)
        end
    })

    MainSection:AddToggle({
        Title = "Auto Cast",
        Default = _G.Config.AutoCast or false,
        Callback = function(value)
            AutoCast(value)
        end
    })

    MainSection:AddToggle({
        Title = "Auto Reel",
        Default = _G.Config.AutoReel or false,
        Callback = function(value)
            AutoReel(value)
        end
    })

    SettingFish:AddToggle({
        Title = "Auto Perfect Catch",
        Default = _G.Config.AutoPerfectCatch or false,
        Callback = function(value)
            PerfectCatch(value)
        end
    })

    SettingFish:AddToggle({
        Title = "Auto Shake",
        Default = _G.Config.AutoShake or false,
        Callback = function(value)
            AutoShake(value)
        end
    })

    SettingFish:AddToggle({
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
    })

    SettingFish:AddToggle({
        Title = "Auto Execute",
        Default = _G.Config.AutoExecute or false,
        Callback = function(value)
            _G.Config.AutoExecute = value
            if value then
                autoExecute()
            end
        end
    })

    AutosSection:AddToggle({
        Title = "Auto Sell",
        Default = _G.Config.AutoSell or false,
        Callback = function(value)
            AutoSell(value)
        end
    })

    AutoMineSection:AddToggle({
        Title = "Auto Mine Dripstone",
        Default = _G.Config.AutoMineDripstone or false,
        Callback = function(value)
            AutoMine(value)
        end
    })

    MiscPlayerSection:AddSlider({
        Title = "WalkSpeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            WalkSpeed(value)
        end
    })

    MiscSection:AddToggle({
        Title = "Disable Oxygen",
        Default = false,
        Callback = function(value)
            DisableOxygen(value)
        end
    })

    EspCharacterSection:AddToggle({
        Title = "ESP Player",
        Default = false,
        Callback = function(value)
            ESP("Players", value)
        end
    })    
    local VipSectionLeft = PrivateServerTab:AddSection("VIP Servers", true, "Left")
    local VipSectionRight = PrivateServerTab:AddSection("VIP Servers", true, "Right")
    
    local function loadPrivateServers()
        local success, res = pcall(function()
            return game:HttpGet("https://key.shieldteam.asia/api/private-servers")
        end)
        
        if success and res then
            local HttpService = game:GetService("HttpService")
            local decodeSuccess, servers = pcall(function()
                return HttpService:JSONDecode(res)
            end)
            
            if not decodeSuccess then
                warn("[NewFish5] JSON Decode Error: " .. tostring(servers))
                warn("[NewFish5] Response: " .. tostring(res):sub(1, 300))
            end
            
            if decodeSuccess and type(servers) == "table" then
                VipSectionLeft:AddParagraph({
                    Title = "Total VIP Servers: " .. tostring(#servers),
                    Content = "Salin tautan server di bawah untuk bergabung."
                })
                VipSectionRight:AddParagraph({
                    Title = "Total VIP Servers: " .. tostring(#servers),
                    Content = "Salin tautan server di bawah untuk bergabung."
                })
                
                if #servers == 0 then
                    VipSectionLeft:AddParagraph({
                        Title = "No Servers Available",
                        Content = "Belum ada server VIP yang terdaftar saat ini."
                    })
                else
                    for idx, server in ipairs(servers) do
                        if server.id and server.link then
                            local section = (idx % 2 == 1) and VipSectionLeft or VipSectionRight
                            
                            section:AddParagraph({
                                Title = "Server ID: " .. tostring(server.id),
                                Content = "Klik tombol di bawah untuk menyalin tautan."
                            })
                            
                            section:AddButton({
                                Title = "Copy Link",
                                Description = "Salin tautan server VIP ke clipboard",
                                Callback = function()
                                    local setClp = setclipboard or toclipboard or (syn and syn.write_clipboard)
                                    if setClp then
                                        setClp(server.link)
                                        Speed_Library:SetNotification({
                                            Title = "Private Server",
                                            Content = "Tautan server VIP berhasil disalin!",
                                            Time = 0.5,
                                            Delay = 3
                                        })
                                    else
                                        Speed_Library:SetNotification({
                                            Title = "Error",
                                            Content = "Executor Anda tidak mendukung setclipboard.",
                                            Time = 0.5,
                                            Delay = 3
                                        })
                                    end
                                end
                            })
                        end
                    end
                end
            else
                VipSectionLeft:AddParagraph({
                    Title = "Error Parsing Data",
                    Content = "Gagal memproses data server dari VPS."
                })
            end
        else
            VipSectionLeft:AddParagraph({
                Title = "Error Connection",
                Content = "Gagal mengambil daftar server VIP dari VPS."
            })
        end
    end
    
    task.spawn(loadPrivateServers)

    pcall(function()
        Exclusive(ExclusiveSection, AutoMineSection, AutoSaveSection, EspCharacterSection, EspEventSection, EspNpcSection)
    end)
    pcall(function()
        Shop(ShopBait, ShopItem, ShopRod, Merlin)
    end)
    pcall(function()
        Autos(AutosCollect, AutosQuest, AutosJack, AutosFavorit, AutosAppraise, AutoAppraise, AutoEnchant, Collect, AutosSection, AuraSection, AutoJetskiSection, FoodSection)
    end)

    pcall(function()
        AreaTP(Main, SAVEPOSTION, NPCSection, BallonSection)
    end)

    CreditsSection:AddParagraph({
        Title = "ShieldTeam || NewFish5",
        Content = "Template sudah disamakan dengan NewFish4Prem.\nSemua Tab & Section sudah dibuatkan.\nSilahkan tambahkan Toggle dan fungsionalitasnya di bawah section ini!"
    })
end

setupGUI()
print("[NewFish5] GUI Loaded Successfully!")