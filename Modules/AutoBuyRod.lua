local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rodsTable = {}
local rodNames = {}

local success, rodsModule = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("rods"))
end)

if success and rodsModule then
    rodsTable = rodsModule.Rods or rodsModule
    if typeof(rodsTable) == "table" then
        for rodName in pairs(rodsTable) do
            table.insert(rodNames, rodName)
        end
        table.sort(rodNames)
    end
end

local function buyRod(rodName)
    local events = ReplicatedStorage:FindFirstChild("events")
    local purchase = events and events:FindFirstChild("purchase")
    if purchase then
        pcall(function()
            purchase:FireServer(rodName, "Rod", nil, 1)
        end)
    end
end

local function startAutoBuyAllLoop()
    task.spawn(function()
        while _G.Config and _G.Config.AutoBuyAllRods do
            pcall(function()
                for _, rodName in ipairs(rodNames) do
                    if not (_G.Config and _G.Config.AutoBuyAllRods) then break end
                    buyRod(rodName)
                    task.wait(0.1)
                end
            end)
            task.wait(1)
        end
    end)
end

return {
    BuyRod = buyRod,
    StartLoop = startAutoBuyAllLoop,
    GetRodList = function() return rodNames end,
}
