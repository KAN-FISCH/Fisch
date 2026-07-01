local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local deleteFishConnection = nil

local function autoEquipRod()
    local rodName = workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
    if rodName and rodName ~= "" then
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local rod = backpack:FindFirstChild(rodName)
        if rod then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(rod)
            end
        end
    end
end

local function AutoEquipRod(value)
    _G.Config.isEquipRpd = value
    if value then
        task.spawn(function()
            while _G.Config.isEquipRpd do
                autoEquipRod()
                task.wait(0.1)
            end
        end)
    end
end

local function AutoPasifLullaby()
    task.spawn(function()
        while task.wait(0.5) do
            if _G.Config and _G.Config.AutoLullaby then
                local char = LocalPlayer.Character
                if char then
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
            end
        end
    end)
end

local function isException(name)
    local lower = name:lower()
    return lower:find("crate") or lower:find("chest") or lower:find("totem")
end

local function cleanItem(item)
    if not item then return end
    task.delay(0.01, function()
        if not item or not item.Parent then return end
        pcall(function()
            if not isException(item.Name) then
                item:Destroy()
            end
        end)
    end)
end

local function DeleteFishModel(value)
    _G.Config.DeleteFishModel = value
    local activeFolder = workspace:FindFirstChild("active")
    if value then
        if activeFolder then
            for _, item in ipairs(activeFolder:GetChildren()) do
                cleanItem(item)
            end
            if deleteFishConnection then deleteFishConnection:Disconnect() end
            deleteFishConnection = activeFolder.ChildAdded:Connect(cleanItem)
        end
    else
        if deleteFishConnection then
            deleteFishConnection:Disconnect()
            deleteFishConnection = nil
        end
    end
end

local function DeleteAllMap(value)
    task.spawn(function()
        if value then
            if workspace:FindFirstChild("world") and workspace.world:FindFirstChild("map") then
                pcall(function() workspace.world.map:Destroy() end)
            end
            if not workspace:FindFirstChild("AntiFallBaseplate") then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local spawnPos = hrp and hrp.Position or Vector3.new(0, 130, 0)

                local baseplate = Instance.new("Part")
                baseplate.Name = "AntiFallBaseplate"
                baseplate.Size = Vector3.new(100000, 50, 100000)
                baseplate.Position = Vector3.new(spawnPos.X, spawnPos.Y - 28, spawnPos.Z)
                baseplate.Anchored = true
                baseplate.CanCollide = true
                baseplate.Transparency = 0.5
                baseplate.Material = Enum.Material.SmoothPlastic
                baseplate.BrickColor = BrickColor.new("Shamrock")
                baseplate.Parent = workspace
            end
        else
            if workspace:FindFirstChild("AntiFallBaseplate") then
                pcall(function() workspace.AntiFallBaseplate:Destroy() end)
            end
        end
    end)
end

local function DeleteAllCharacters(value)
    task.spawn(function()
        _G.Config.DeletePlayer = value
        if value then
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                    pcall(function() obj:Destroy() end)
                end
            end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    pcall(function() plr.Character:Destroy() end)
                end
            end
        else
            -- We cannot call LoadCharacter ourselves easily if we are not the server, but let's let them respawn naturally or prompt
        end
    end)
end

return {
    AutoEquipRod = AutoEquipRod,
    AutoPasifLullaby = AutoPasifLullaby,
    DeleteFishModel = DeleteFishModel,
    DeleteAllMap = DeleteAllMap,
    DeleteAllCharacters = DeleteAllCharacters,
}
