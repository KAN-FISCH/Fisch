local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local autoSellRunning = false
local autoSellStorageRunning = false
local _marcDuplicated = false
local _shadyDuplicated = false

local SHADY_MUTATIONS = {"Shady", "Sludge"}

local function clickYesPopup()
    pcall(function()
        local gui = LocalPlayer.PlayerGui
        for _, screen in ipairs(gui:GetChildren()) do
            if screen:IsA("ScreenGui") then
                for _, frame in ipairs(screen:GetDescendants()) do
                    if (frame:IsA("TextButton") or frame:IsA("ImageButton")) then
                        local t = frame.Text or ""
                        if t:lower():find("yes") or t:lower():find("ya") or t:lower():find("confirm") then
                            pcall(function()
                                if getconnections then
                                    for _, conn in pairs(getconnections(frame.MouseButton1Click)) do conn:Fire() end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

local function PrepareForTeleport()
    local prevAutoCast = _G.Config and _G.Config.AutoCast
    if _G.Config then _G.Config.AutoCast = false end
    return prevAutoCast
end

local function RestoreAfterTeleport(prevAutoCast)
    if _G.Config then _G.Config.AutoCast = prevAutoCast end
end

local function AutoSell()
    if autoSellRunning then return end
    autoSellRunning = true

    task.spawn(function()
        local needsMarc = not _marcDuplicated
        local needsShady = not _shadyDuplicated
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp then
            local prevAutoCast = PrepareForTeleport()
            local savedCF = hrp.CFrame

            if needsMarc then
                hrp.CFrame = CFrame.new(466, 151, 229)
                task.wait(2)
                local marc = workspace:FindFirstChild("world")
                    and workspace.world:FindFirstChild("npcs")
                    and workspace.world.npcs:FindFirstChild("Marc Merchant")
                if marc then
                    task.wait(1)
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
                    task.wait(1)
                    pcall(function()
                        shadyNpc.Archivable = true
                        local clone = shadyNpc:Clone()
                        if clone then
                            clone.Name = "Shady Merchant"
                            clone.Parent = shadyNpc.Parent or workspace
                        end
                    end)
                    _shadyDuplicated = true
                    task.wait(0.5)
                end
            end

            hrp.CFrame = savedCF
            task.wait(0.5)
            RestoreAfterTeleport(prevAutoCast)
        end

        -- Main sell loop
        local function getCachedMarcNpc()
            local npc = workspace:FindFirstChild("world")
                and workspace.world:FindFirstChild("npcs")
                and workspace.world.npcs:FindFirstChild("Marc Merchant")
            if not npc then return nil, nil end
            local desc = npc:FindFirstChild("description")
            local idle = desc and desc:FindFirstChild("idle")
            return npc, idle
        end

        local function getCachedShadyNpc()
            local npc = workspace:FindFirstChild("world")
                and workspace.world:FindFirstChild("npcs")
                and workspace.world.npcs:FindFirstChild("Shady Merchant")
            if not npc then npc = workspace:FindFirstChild("Shady Merchant") end
            if not npc then return nil, nil end
            local desc = npc:FindFirstChild("description")
            local idle = desc and desc:FindFirstChild("idle")
            return npc, idle
        end

        local function getInventory()
            local inv = {}
            local success, result = pcall(function()
                local RS = game:GetService("ReplicatedStorage")
                local DataController = require(RS:WaitForChild("client"):WaitForChild("controllers"):WaitForChild("DataController"))
                return DataController:Get("inventory") or {}
            end)
            if success and type(result) == "table" then
                for k, v in pairs(result) do
                    if type(v) == "table" and v.item then
                        table.insert(inv, v.item)
                    end
                end
            end
            return inv
        end

        local function isShadyMutation(mutation)
            if not mutation then return false end
            for _, m in ipairs(SHADY_MUTATIONS) do
                if mutation == m then return true end
            end
            return false
        end

        while _G.Config and _G.Config.AutoSell do
            task.wait(2)
            pcall(function()
                local events = game:GetService("ReplicatedStorage"):FindFirstChild("events")
                if not events then return end

                local inventory = getInventory()
                local marcNpc, marcIdle = getCachedMarcNpc()
                local shadyNpc, shadyIdle = getCachedShadyNpc()

                -- Sell to Marc
                if marcNpc and marcIdle then
                    local sellArgs = {{voice = 12, uid = "merchant_moosewood", npc = marcNpc, idle = marcIdle}}
                    local sellAll = events:FindFirstChild("SellAll")
                    if sellAll then
                        pcall(function() sellAll:InvokeServer(unpack(sellArgs)) end)
                        task.wait(1)
                        clickYesPopup()
                    end
                end

                -- Sell shady items to Shady Merchant
                if shadyNpc and shadyIdle then
                    local hasShady = false
                    for _, item in ipairs(inventory) do
                        if isShadyMutation(item.mutation) then
                            hasShady = true
                            break
                        end
                    end
                    if hasShady then
                        local sellShadyArgs = {{voice = 15, uid = "shady_merchant", npc = shadyNpc, idle = shadyIdle}}
                        local sellAll = events:FindFirstChild("SellAll")
                        if sellAll then
                            pcall(function() sellAll:InvokeServer(unpack(sellShadyArgs)) end)
                            task.wait(1)
                            clickYesPopup()
                        end
                    end
                end
            end)
        end

        autoSellRunning = false
    end)
end

local function AutoSellStorage()
    if autoSellStorageRunning then return end
    autoSellStorageRunning = true

    task.spawn(function()
        local useNpc, idle = nil, nil

        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local prevAutoCast = PrepareForTeleport()
                local oldCFrame = hrp.CFrame
                hrp.CFrame = CFrame.new(481, 151, 299)
                task.wait(1.5)
                local npcsFolder = workspace:WaitForChild("world"):WaitForChild("npcs")
                local originalNpc = npcsFolder:WaitForChild("Marc Merchant", 10)
                if originalNpc then
                    useNpc = originalNpc
                    idle = useNpc:WaitForChild("description"):WaitForChild("idle", 5)
                end
                hrp.CFrame = oldCFrame
                RestoreAfterTeleport(prevAutoCast)
            end
        end)

        if not (useNpc and idle) then
            autoSellStorageRunning = false
            return
        end

        local args = {{voice = 12, uid = "merchant_moosewood", npc = useNpc, idle = idle}}

        while _G.Config and _G.Config.AutoSellStorage do
            pcall(function()
                local events = game:GetService("ReplicatedStorage"):WaitForChild("events")
                local sellAllStorage = events:FindFirstChild("SellAllStorage")
                if sellAllStorage then
                    task.spawn(function()
                        pcall(function()
                            sellAllStorage:InvokeServer(unpack(args))
                        end)
                    end)
                    task.wait(1.5)
                    clickYesPopup()
                    task.wait(0.5)
                    clickYesPopup()
                end
            end)
            task.wait(1)
        end
        autoSellStorageRunning = false
    end)
end

local M = {
    AutoSell = AutoSell,
    AutoSellStorage = AutoSellStorage,
}

setmetatable(M, {
    __call = function(self, value)
        _G.Config.AutoSell = value
        if value then
            AutoSell()
        end
    end
})

return M
