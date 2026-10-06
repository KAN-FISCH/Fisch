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
local function AutoPasifLullaby(value)
    if not _G.Config then _G.Config = {} end
    _G.Config.AutoMetronome = value
    _G.Config.AutoLullaby = value
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
        _G.Config.DeleteMap = value
        if value then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local spawnPos = hrp and hrp.Position or Vector3.new(0, 130, 0)
            local baseplate = workspace:FindFirstChild("AntiFallBaseplate")
            if not baseplate then
                baseplate = Instance.new("Part")
                baseplate.Name = "AntiFallBaseplate"
                baseplate.Size = Vector3.new(100000, 4, 100000)
                baseplate.Position = Vector3.new(spawnPos.X, spawnPos.Y - 3.2, spawnPos.Z)
                baseplate.Anchored = true
                baseplate.CanCollide = true
                baseplate.Transparency = 0.5
                baseplate.Material = Enum.Material.SmoothPlastic
                baseplate.BrickColor = BrickColor.new("Shamrock")
                baseplate.Parent = workspace
            end
            local world = workspace:FindFirstChild("world")
            if world then
                local mapFolder = world:FindFirstChild("map")
                if mapFolder then
                    for _, child in ipairs(mapFolder:GetChildren()) do
                        pcall(function() child:Destroy() end)
                    end
                end
                for _, folderName in ipairs({"nature", "props", "decorations", "structures", "islands"}) do
                    local f = world:FindFirstChild(folderName)
                    if f then
                        pcall(function() f:Destroy() end)
                    end
                end
            end
            if not _G.__antiVoidRunning then
                _G.__antiVoidRunning = true
                task.spawn(function()
                    while _G.Config.DeleteMap do
                        task.wait(1)
                        pcall(function()
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local bp = workspace:FindFirstChild("AntiFallBaseplate")
                            if root and bp and root.Position.Y < bp.Position.Y - 20 then
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.CFrame = CFrame.new(root.Position.X, bp.Position.Y + 4, root.Position.Z)
                            end
                        end)
                    end
                    _G.__antiVoidRunning = false
                end)
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
        end
    end)
end
task.spawn(function()
    local player = game.Players.LocalPlayer
    local function setupShadyCoinGui()
        local gui = player:WaitForChild("PlayerGui", 10)
        if not gui then return end
        local hud = gui:WaitForChild("hud", 10)
        if not hud then return end
        local safezone = hud:WaitForChild("safezone", 5)
        if not safezone then return end
        local coinsGui = safezone:WaitForChild("coins", 5)
        if not coinsGui then return end
        if safezone:FindFirstChild("ShadyCoinGui") then return end
        local shadyGui = coinsGui:Clone()
        shadyGui.Name = "ShadyCoinGui"
        for _, child in ipairs(shadyGui:GetDescendants()) do
            if child:IsA("LocalScript") or child:IsA("Script") then
                child:Destroy()
            end
        end
        if not safezone:FindFirstChildOfClass("UIListLayout") then
            shadyGui.Position = UDim2.new(
                coinsGui.Position.X.Scale, coinsGui.Position.X.Offset,
                coinsGui.Position.Y.Scale, coinsGui.Position.Y.Offset - 85
            )
        end
        shadyGui.Parent = safezone
        local icon = shadyGui:FindFirstChild("icon")
        if icon then icon:Destroy() end
        local fishBG = shadyGui:FindFirstChild("fishBG")
        if fishBG then fishBG:Destroy() end
        local textLabel = shadyGui:IsA("TextLabel") and shadyGui or (shadyGui:FindFirstChild("TextLabel") or shadyGui:FindFirstChildOfClass("TextLabel"))
        if not textLabel then return end
        if textLabel ~= shadyGui then
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.Size = UDim2.new(1, 0, 1, 0)
        end
        textLabel.TextXAlignment = Enum.TextXAlignment.Right
        textLabel.TextColor3 = Color3.fromRGB(185, 125, 130)
        local function updateShadyCoins()
            pcall(function()
                local stats = workspace:FindFirstChild("PlayerStats")
                if not stats then return end
                local pStats = stats:FindFirstChild(player.Name)
                if not pStats then return end
                local tFolder = pStats:FindFirstChild("T")
                if not tFolder then return end
                local pFolder = tFolder:FindFirstChild(player.Name)
                if not pFolder then return end
                local localCurr = pFolder:FindFirstChild("LocalCurrencies")
                if not localCurr then return end
                local shadyScrip = localCurr:FindFirstChild("Shady Scrip")
                if shadyScrip then
                    local formattedValue = tostring(shadyScrip.Value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
                    textLabel.Text = formattedValue .. " S$"
                else
                    textLabel.Text = "0 S$"
                end
            end)
        end
        task.spawn(function()
            while textLabel and textLabel.Parent do
                updateShadyCoins()
                task.wait(1)
            end
        end)
    end
    setupShadyCoinGui()
    player.CharacterAdded:Connect(function()
        task.wait(2)
        setupShadyCoinGui()
    end)
end)
return {
    AutoEquipRod = AutoEquipRod,
    AutoPasifLullaby = AutoPasifLullaby,
    DeleteFishModel = DeleteFishModel,
    DeleteAllMap = DeleteAllMap,
    DeleteAllCharacters = DeleteAllCharacters,
}