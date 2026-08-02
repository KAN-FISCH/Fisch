local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local activeQuestRunning = false

local function getActiveQuests()
    local quests = {}
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local client = RS:WaitForChild("client", 2)
        local controllers = client and client:WaitForChild("controllers", 2)
        local dc = controllers and controllers:WaitForChild("DataController", 2)
        if not dc then
            local legacy = client and client:WaitForChild("legacyControllers", 2)
            dc = legacy and legacy:WaitForChild("DataController", 2)
        end
        if dc then
            local DataController = require(dc)
            local data = {}
            if DataController.PlayerDataReplicator and DataController.PlayerDataReplicator.Index then
                pcall(function()
                    data = DataController.PlayerDataReplicator:Index({"quests"}) or {}
                end)
            else
                pcall(function()
                    data = DataController.Get and DataController:Get("quests") or DataController.fetch and DataController.fetch("quests") or {}
                end)
            end
            for k, v in pairs(data) do
                table.insert(quests, {id = k, data = v})
            end
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
    if activeQuestRunning then return end
    activeQuestRunning = true
    task.spawn(function()
        while _G.Config and _G.Config.AutoQuest do
            task.wait(5)
            pcall(function()
                local quests = getActiveQuests()
                for _, quest in ipairs(quests) do
                    local d = quest.data
                    if d and d.completed then
                        claimQuestReward(quest.id)
                        task.wait(0.5)
                    end
                end
            end)
        end
        activeQuestRunning = false
    end)
end

local AutoQuest = {
    GetActiveQuests = getActiveQuests,
    ClaimQuestReward = claimQuestReward,
    AcceptQuest = acceptQuest,
}

setmetatable(AutoQuest, {
    __call = function(self, value)
        _G.Config.AutoQuest = value
        if value then
            AutoQuestLoop()
        end
    end
})

return AutoQuest
