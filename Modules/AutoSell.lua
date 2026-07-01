local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local autoSellRunning = false 
local _marcDuplicated = false
local _shadyDuplicated = false

local function sellNormal()
    pcall(function()
        local marc = workspace.world.npcs:FindFirstChild("Marc Merchant")
        if marc then
            local desc = marc:FindFirstChild("description")
            local idle = desc and desc:FindFirstChild("idle")
            if idle then
                local args = {
                    {
                        voice = 12,
                        uid = "merchant_moosewood",
                        npc = marc,
                        idle = idle
                    }
                }
                ReplicatedStorage.events.SellAll:InvokeServer(unpack(args))
            end
        end
    end)
end

local function sellShady()
    pcall(function()
        local shadyNpc = workspace.world.npcs:FindFirstChild("Shady Merchant") or workspace:FindFirstChild("Shady Merchant")
        if shadyNpc then
            local desc = shadyNpc:FindFirstChild("description")
            local idle = desc and desc:FindFirstChild("idle")
            if idle then
                local args = {
                    {
                        voice = 12,
                        uid = "Shady Merchant",
                        npc = shadyNpc,
                        idle = idle
                    }
                }
                ReplicatedStorage.events.ShadySellAll:InvokeServer(unpack(args))
            end
        end
    end)
end

local function AutoSell()
    if autoSellRunning then return end  
    autoSellRunning = true

    task.spawn(function()
        local needsMarc = not _marcDuplicated
        local needsShady = not _shadyDuplicated

        if needsMarc or needsShady then
            local char = Players.LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                local savedCF = hrp.CFrame

                if needsMarc then
                    hrp.CFrame = CFrame.new(466, 151, 229)
                    task.wait(2)

                    local marc = workspace:FindFirstChild("world")
                        and workspace.world:FindFirstChild("npcs")
                        and workspace.world.npcs:FindFirstChild("Marc Merchant")

                    if marc then
                        pcall(function()
                            marc.Archivable = true
                            local clone = marc:Clone()
                            if clone then
                                clone.Name = "Marc Merchant"
                                clone.Parent = workspace.world.npcs
                            end
                        end)
                        _marcDuplicated = true
                        task.wait(0.5)
                    end
                end

                if needsShady then
                    hrp.CFrame = CFrame.new(-2997, -1023, 6067)
                    task.wait(2)

                    local shadyNpc = workspace:FindFirstChild("world")
                        and workspace.world:FindFirstChild("npcs")
                        and workspace.world.npcs:FindFirstChild("Shady Merchant")

                    if not shadyNpc then
                        shadyNpc = workspace:FindFirstChild("Shady Merchant")
                    end

                    if shadyNpc then
                        pcall(function()
                            shadyNpc.Archivable = true
                            local clone = shadyNpc:Clone()
                            if clone then
                                clone.Name = "Shady Merchant"
                                if shadyNpc.Parent then
                                    clone.Parent = shadyNpc.Parent
                                else
                                    clone.Parent = workspace
                                end
                            end
                        end)
                        _shadyDuplicated = true
                        task.wait(0.5)
                    end
                end

                hrp.CFrame = savedCF
                task.wait(0.5)
            end
        end

        while _G.Config.AutoSell do  
            sellShady()
            task.wait(0.5)
            sellNormal()
            
            task.wait(3)  
        end
        autoSellRunning = false 
    end)
end

local function init(value)
    _G.Config.AutoSell = value
    if value then
        AutoSell()
    end
end

return init
