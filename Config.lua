local ConfigModule = {}

ConfigModule.ConfigFolder = "ExclusiveConfigs/"
ConfigModule.CurrentConfigFile = "Default"

_G.Config = {
    ['Farm Fish'] = false,
    AutoCast = false,
    InstantCast = false,
    AntiAFK = true,
    SelectedNightTotems = {},
    SelectedDayTotems = {},
    AutoReel = false,
    InstantReel = false,
    BobberDepth = 10,
    AutoPerfectCatch = false,
    perfectCatchEnabled = 0,
    PerfectCatchChance = 0,
    perfectCastEnabled = 0,
    selectedZone = "None",
    ShakeDelay = 0.26,
    AutoHopCosmic = false,
    selectedZoneADS = false,
    AutoSellOnHeld = false,
    isFishing = false,
    equipRod = false,
    playerDetectionEnabled = false,
    isEquipRpd = false,
    AutoSell = false,
    AutoClaimMulti = false,
    InfinityJump = false,
    FreezeCharacter = false,
    AutoShake = false,
    AutoFavorite = false,
    RemoveUIFisch = false,
    ReelMode = "Super Instant",
    AutoMineDripstone = false,
    InfSundial = false,
    SavedPosition = nil,
    AutoTeleportOnLoad = true,
    SelectedDayTotem = "",
    SelectedNightTotem = "",
    AutoTotemToggle = false,
    AutoTotemRunning = false,
    TotemSummoned = false,
    TotemLock = false,
    LastCycle = "",
    AutoPurchaseIfNone = false,
    AutoStorageRarities = {},
    AutoStorageInterval = 60,
    AutoStorageEnabled = false,
    AutoSellEvents = {},
    DeleteAnimation = false,
    DiscordWebhookURL = "",
    DiscordWebhookEnabled = false,
    FishNotificationEnabled = true,
    AutoPotionEnabled = false,
    SelectedPotions = {},
    AutoPurchasePotion = true,
    PotionCooldowns = {},
    AutoPotionRunning = false,
    AutoSellStorage = false,
    AutoBuyAllRods = false,
    AutoGetClover = false,
    AutoConsumeClover = false,
    CloverHopServer = false,
    SelectedFishFood = "Kelp",
    AutoBuyFood = false,
    AutoActivateFood = false,
    AutoBuySlot = false,
    SelectedFishesForAquarium = {},
    AutoAddFish = false,
    AutoHopUptime = false,
    SelectedEgg = "All",
    AutoCollectEgg = false,
    DeleteAnimation = false,
    AutoSellShady = false,
    AutoClaimAquarium = false,
    AutoQuestShady = false,
    AutoOpenBait = false,
    AutoExecute = true,
}

_G.__var = {
    reelConnection = nil,
    autoReelEnabled = true,
    perfectCatchEnabled = 0,
    perfectCastEnabled = 0,
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

function ConfigModule.DeepCopy(original)
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
                    copy[key] = ConfigModule.DeepCopy(value)
                elseif typeVal == "string" or typeVal == "number" or typeVal == "boolean" then
                    copy[key] = value
                end
            end
        end
    end
    return copy
end

function ConfigModule.SaveConfig(configName)
    configName = configName or ConfigModule.CurrentConfigFile
    local HttpService = game:GetService("HttpService")

    if not isfolder(ConfigModule.ConfigFolder) then
        makefolder(ConfigModule.ConfigFolder)
    end

    local data = {
        Config = _G.Config,
        Var = {}
    }

    for k, v in pairs(_G.__var) do
        if k ~= "reelConnection" and k ~= "isReeling" then
            data.Var[k] = v
        end
    end

    local success, result = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if success and writefile then
        writefile(ConfigModule.ConfigFolder .. configName .. ".json", result)
        print("[NewFish5] Config saved successfully to " .. configName)
        return true
    end
    return false
end

function ConfigModule.LoadConfig(configName)
    configName = configName or ConfigModule.CurrentConfigFile
    local filePath = ConfigModule.ConfigFolder .. configName .. ".json"

    if isfile and isfile(filePath) and readfile then
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(filePath))
        end)

        if success and result then
            local loadedConfig = result.Config or result
            local loadedVar = result.Var or {}

            for key, value in pairs(loadedConfig) do
                if type(value) == "table" then
                    _G.Config[key] = ConfigModule.DeepCopy(value)
                else
                    _G.Config[key] = value
                end
            end

            for key, value in pairs(loadedVar) do
                if type(value) == "table" then
                    _G.__var[key] = ConfigModule.DeepCopy(value)
                else
                    _G.__var[key] = value
                end
            end

            ConfigModule.CurrentConfigFile = configName
            print("[NewFish5] Config loaded successfully from " .. configName)
            return true
        end
    end
    return false
end

return ConfigModule