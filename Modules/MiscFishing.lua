local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local MiscFishing = {}

function MiscFishing.NoActionSafe(value)
    _G.Config.NoActionSafe = value
    if value then
        task.spawn(function()
            local lastFishTick = tick()
            while _G.Config.NoActionSafe do
                task.wait(1)
                local char = Players.LocalPlayer.Character
                if not char then continue end
                local hum = char:FindFirstChildOfClass("Humanoid")
                local tool = char:FindFirstChildOfClass("Tool")
                
                local isRod = false
                if tool and (tool:FindFirstChild("events") or tool:FindFirstChild("rod/client")) then
                    isRod = true
                end
                
                if not isRod then
                    lastFishTick = tick()
                    continue
                end
                
                local isBobber = tool:FindFirstChild("bobber") ~= nil
                local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("reel")
                local isReeling = gui and gui.Enabled
                
                if isBobber or isReeling then
                    lastFishTick = tick()
                else
                    if tick() - lastFishTick >= 10 then
                        if hum then
                            local rodName = tool.Name
                            hum:UnequipTools()
                            task.wait(0.5)
                            local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
                            if backpack then
                                local backpackRod = backpack:FindFirstChild(rodName)
                                if backpackRod then
                                    hum:EquipTool(backpackRod)
                                end
                            end
                        end
                        lastFishTick = tick()
                    end
                end
            end
        end)
    end
end

function MiscFishing.AutoEquipRod(value)
    _G.Config.isEquipRpd = value
    if value then
        task.spawn(function()
            while _G.Config.isEquipRpd do
                task.wait(0.5)
                local char = Players.LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hasRod = false
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA("Tool") and (child:FindFirstChild("events") or child:FindFirstChild("rod/client")) then
                            hasRod = true
                            break
                        end
                    end
                    if not hasRod and hum then
                        local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
                        if backpack then
                            for _, item in ipairs(backpack:GetChildren()) do
                                if item:IsA("Tool") and (item:FindFirstChild("events") or item:FindFirstChild("rod/client")) then
                                    hum:EquipTool(item)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

function MiscFishing.AutoPasifLullaby(value)
    _G.Config.AutoMetronome = value
    if value then
        task.spawn(function()
            while _G.Config.AutoMetronome do
                task.wait(0.1)
                pcall(function()
                    local char = Players.LocalPlayer.Character
                    if char then
                        local rod = char:FindFirstChildOfClass("Tool")
                        if rod and rod:FindFirstChild("events") and rod.events:FindFirstChild("lullaby") then
                            rod.events.lullaby:FireServer()
                        end
                    end
                end)
            end
        end)
    end
end

function MiscFishing.DeleteFishModel(value)
    _G.Config.DeleteFishModel = value
    if value then
        task.spawn(function()
            while _G.Config.DeleteFishModel do
                task.wait(2)
                pcall(function()
                    local activeFolder = workspace:FindFirstChild("active")
                    if activeFolder then
                        for _, item in ipairs(activeFolder:GetChildren()) do
                            local ownerId = item:GetAttribute("OwnerId")
                            if ownerId == Players.LocalPlayer.UserId then
                                item:Destroy()
                            end
                        end
                    end
                end)
            end
        end)
    end
end

function MiscFishing.DeleteAllMap(value)
    if value then
        pcall(function()
            if workspace:FindFirstChild("world") and workspace.world:FindFirstChild("map") then
                workspace.world.map:Destroy()
            end
            if not workspace:FindFirstChild("AntiFallBaseplate") then
                local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local spawnPos = hrp and hrp.Position or Vector3.new(0, 130, 0)
                
                local baseplate = Instance.new("Part")
                baseplate.Name = "AntiFallBaseplate"
                baseplate.Size = Vector3.new(100000, 50, 100000)
                baseplate.Position = Vector3.new(spawnPos.X, spawnPos.Y - 28, spawnPos.Z)
                baseplate.Anchored = true
                baseplate.CanCollide = true
                baseplate.Transparency = 0.5
                baseplate.Material = Enum.Material.SmoothPlastic
                baseplate.Parent = workspace
            end
        end)
    end
end

function MiscFishing.DeleteAllCharacters(value)
    _G.Config.DeletePlayer = value
    if value then
        task.spawn(function()
            while _G.Config.DeletePlayer do
                task.wait(1)
                pcall(function()
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= Players.LocalPlayer and plr.Character then
                            plr.Character:Destroy()
                        end
                    end
                end)
            end
        end)
    else
        pcall(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer then
                    plr:LoadCharacter()
                end
            end
        end)
    end
end

return MiscFishing
