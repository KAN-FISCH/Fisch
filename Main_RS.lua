local ReplicatedStorage = game:GetService("ReplicatedStorage")
local storageFolder = ReplicatedStorage:WaitForChild("Shield_Core", 10)

if not storageFolder then
    warn("[NewFish5] Core folder not found in ReplicatedStorage!")
    return
end

local function getMod(name)
    local val = storageFolder:FindFirstChild(name)
    if val then
        return loadstring(val.Value)()
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

        MainSection:AddDropdown({
        Title = "Reel Mode",
        Values = {"Super Instant", "Instant", "Legit", "5 Notif", "Manual"},
        Default = _G.Config.ReelMode or "Super Instant",
        Callback = function(value)
            _G.Config.ReelMode = value
        end
    })

    MainSection:AddToggle({
        Title = "Instant Bobber",
        Default = _G.Config.InstantCast or false,
        Callback = function(value)
            if InstantBobber then InstantBobber(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Cast",
        Default = _G.Config.AutoCast or false,
        Callback = function(value)
            if AutoCast then AutoCast(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Reel",
        Default = _G.Config.AutoReel or false,
        Callback = function(value)
            if AutoReel then AutoReel(value) end
        end
    })

        MainSection:AddToggle({
        Title = "No Action Safe",
        Default = _G.Config.NoActionSafe or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.NoActionSafe(value) end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Equip Rod",
        Default = _G.Config.isEquipRpd or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.AutoEquipRod(value) end
        end
    })

        SettingFish:AddToggle({
        Title = "Auto Pasif Lullaby",
        Default = _G.Config.AutoMetronome or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.AutoPasifLullaby(value) end
        end
    })

    SettingFish:AddToggle({
        Title = "Delete Fish Model",
        Default = _G.Config.DeleteFishModel or false,
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
        Default = _G.Config.DeletePlayer or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteAllCharacters(value) end
        end
    })

    SettingFish:AddSlider({
        Title = "Bar Size",
        Min = 1,
        Max = 20,
        Default = 5,
        Callback = function(value)
            if _G.__var then _G.__var.barSize = value end
        end
    })

    SettingFish:AddToggle({
        Title = "Auto Perfect Catch",
        Default = _G.Config.AutoPerfectCatch or false,
        Callback = function(value)
            if PerfectCatch then PerfectCatch(value) end
        end
    })

    SettingFish:AddToggle({
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

    AutoMineSection:AddToggle({
        Title = "Auto Mine Dripstone",
        Default = _G.Config.AutoMineDripstone or false,
        Callback = function(value)
            if AutoMine then AutoMine(value) end
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

