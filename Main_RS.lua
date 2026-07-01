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
    local FishingTab  = GrpMain:CreateTab({ "Fishing",  "", "Auto Fishing & Cast" })
    local MainSection = FishingTab:AddSection("Fishing", true, "Left")

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
end

setupGUI()
print("[NewFish5] GUI Loaded Successfully from ReplicatedStorage!")
