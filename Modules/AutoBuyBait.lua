local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Auto Buy Bait Loop
local function AutoBuyBaitLoop()
    task.spawn(function()
        while task.wait(1) do
            if _G.Config and _G.Config.AutoBuyBait then
                pcall(function()
                    local baitName = _G.Config.SelectedBait or "Worm"
                    local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
                    local purchase = events and events:FindFirstChild("purchase")
                    if purchase then
                        local rem = _G.Config.BuyBaitAmount or 1
                        task.spawn(function()
                            pcall(function()
                                while rem > 0 do
                                    if not (_G.Config and _G.Config.AutoBuyBait) then break end
                                    local buyBatch = rem > 50 and 50 or rem
                                    purchase:FireServer(baitName, "Bait", nil, buyBatch)
                                    rem = rem - buyBatch
                                end
                            end)
                        end)
                    end
                end)
            end
        end
    end)
end

AutoBuyBaitLoop()

local function Init()
    -- Loop already started automatically
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
