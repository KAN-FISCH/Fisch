local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function AutoEquipRod()
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Rod") or tool.Name:find("Fishing") or tool.Name:find("rod")) then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum:EquipTool(tool) end
            break
        end
    end
end

local function AutoPasifLullaby()
    task.spawn(function()
        while task.wait(0.5) do
            if not _G.Config or not _G.Config.AutoLullaby then continue end
            local char = LocalPlayer.Character
            if not char then continue end
            local backpack = LocalPlayer.Backpack
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool.Name:lower():find("lullaby") then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        hum:EquipTool(tool)
                        task.wait(0.2)
                        local equippedTool = char:FindFirstChild(tool.Name)
                        if equippedTool and equippedTool.Activate then
                            equippedTool:Activate()
                        end
                    end
                    break
                end
            end
        end
    end)
end

local function DeleteFishModel()
    local worldFolder = workspace:FindFirstChild("world")
    if not worldFolder then return end
    local fishFolder = worldFolder:FindFirstChild("fish") or worldFolder:FindFirstChild("Fish")
    if fishFolder then
        for _, fish in ipairs(fishFolder:GetChildren()) do
            pcall(function() fish:Destroy() end)
        end
    end
    -- Also clear from workspace directly
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find("fish") and obj:IsA("Model") then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function DeleteAllMap()
    pcall(function()
        local world = workspace:FindFirstChild("world")
        if world then
            local map = world:FindFirstChild("map")
            if map then
                for _, child in ipairs(map:GetChildren()) do
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end)
end

local function DeleteAllCharacters()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            pcall(function()
                p.Character:Destroy()
            end)
        end
    end
end

return {
    AutoEquipRod = AutoEquipRod,
    AutoPasifLullaby = AutoPasifLullaby,
    DeleteFishModel = DeleteFishModel,
    DeleteAllMap = DeleteAllMap,
    DeleteAllCharacters = DeleteAllCharacters,
}
