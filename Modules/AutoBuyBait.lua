local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Auto Buy Bait Loop
local function AutoBuyBaitLoop()
    task.spawn(function()
        while task.wait(1) do
            if not _G.Config or not _G.Config.AutoBuyBait then continue end
            pcall(function()
                local baitName = _G.Config.SelectedBait or "Worm"
                local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
                local purchase = events and events:FindFirstChild("purchase")
                if purchase then
                    purchase:FireServer(baitName, "Bait", nil, _G.Config.BuyBaitAmount or 1)
                end
            end)
        end
    end)
end

local function Init()
    AutoBuyBaitLoop()
end

-- Available baits list
local BAIT_LIST = {
    "Worm", "Cricket", "Leech", "Minnow", "Firefly",
    "Shrimp", "Squid", "Sand Dollar", "Pearl",
    "Phantom Worm", "Enchanted Bait", "Seaside Sardine",
}

return {
    Init = Init,
    GetBaitList = function() return BAIT_LIST end,
}
