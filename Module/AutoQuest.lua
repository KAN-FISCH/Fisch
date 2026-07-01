local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getActiveQuests()
    local quests = {}
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local DataController = require(RS:WaitForChild("client"):WaitForChild("controllers"):WaitForChild("DataController"))
        local data = DataController:Get("quests") or {}
        for k, v in pairs(data) do
            table.insert(quests, {id = k, data = v})
        end
    end)
    return quests
end

local function claimQuestReward(questId)
    pcall(function()
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
        local claimQuest = events and events:FindFirstChild("claimQuest")
        if claimQuest then
            claimQuest:FireServer(questId)
        end
    end)
end

local function acceptQuest(questId)
    pcall(function()
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
        local acceptQuest = events and events:FindFirstChild("acceptQuest")
        if acceptQuest then
            acceptQuest:FireServer(questId)
        end
    end)
end

local function AutoQuestLoop()
    task.spawn(function()
        while task.wait(5) do
            if not _G.Config or not _G.Config.AutoQuest then continue end
            pcall(function()
                local quests = getActiveQuests()
                for _, quest in ipairs(quests) do
                    local d = quest.data
                    -- If quest is completed, claim it
                    if d and d.completed then
                        claimQuestReward(quest.id)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end)
end

local function Init()
    AutoQuestLoop()
end

return {
    Init = Init,
    GetActiveQuests = getActiveQuests,
    ClaimQuestReward = claimQuestReward,
    AcceptQuest = acceptQuest,
}
