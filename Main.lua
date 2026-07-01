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

local executorName = Utils.DetectExecutor()

local GUI_URL = "https://raw.githubusercontent.com/KAN-FISCH/tesss/refs/heads/main/tester26"
local _guiOk, Speed_Library = pcall(function()
    return loadstring(game:HttpGet(GUI_URL))()
end)

if not (_guiOk and Speed_Library) then
    warn("[NewFish5] Gagal load Speed_Library!")
    return
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
    CreditsSection:AddParagraph({
        Title = "ShieldTeam || NewFish5",
        Content = "Template sudah disamakan dengan NewFish4Prem.\nSemua Tab & Section sudah dibuatkan.\nSilahkan tambahkan Toggle dan fungsionalitasnya di bawah section ini!"
    })

end

setupGUI()
print("[NewFish5] GUI Loaded Successfully!")