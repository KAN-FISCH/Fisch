local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local AutoNukeEnabled = false
local dupeFischToggle = false

local function pressButton(button)
    if not button then return end
    pcall(function()
        local mockInput = { UserInputType = Enum.UserInputType.MouseButton1 }
        if firesignal then
            pcall(function() firesignal(button.Activated, mockInput) end)
            pcall(function() firesignal(button.Activated) end)
            pcall(function() firesignal(button.MouseButton1Click) end)
        end
        if getconnections then
            for _, c in pairs(getconnections(button.Activated)) do
                pcall(function() c:Fire(mockInput) end)
            end
            for _, c in pairs(getconnections(button.MouseButton1Click)) do
                pcall(function() c:Fire() end)
            end
        end
    end)
end

-- GC upvalue hook task for AutoNuke
task.spawn(function()
    while true do
        task.wait(1)
        if AutoNukeEnabled then
            if getgc and debug and debug.info and debug.setupvalue then
                pcall(function()
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "function" then
                            local name = debug.info(v, "n")
                            if name == "LoopMinigame" then
                                while AutoNukeEnabled do
                                    local ok = pcall(function()
                                        debug.setupvalue(v, 13, workspace:GetServerTimeNow() - 10)
                                    end)
                                    if not ok then break end
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- Initialize Loops
task.spawn(function()
    while true do
        task.wait()
        if AutoNukeEnabled then
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local nukeGui = playerGui and playerGui:FindFirstChild("NukeMinigame")
                if nukeGui and nukeGui.Enabled then
                    local center = nukeGui:FindFirstChild("Center")
                    local marker = center and center:FindFirstChild("Marker")
                    local pointer = marker and marker:FindFirstChild("Pointer")
                    local frame = pointer and (pointer:FindFirstChild("Frame") or pointer)
                    local leftBtn = center and center:FindFirstChild("Left")
                    local rightBtn = center and center:FindFirstChild("Right")
                    
                    if pointer then
                        local rot = pointer.Rotation
                        if rot == 0 and frame then
                            rot = frame.AbsoluteRotation
                        end

                        if rot < -5 then
                            pressButton(rightBtn)
                        elseif rot > 5 then
                            pressButton(leftBtn)
                        end
                    end
                end
            end)
        end
    end
end)

local function startSpearExploits()
    task.spawn(function()
        local remote = ReplicatedStorage:WaitForChild('packages')
            :WaitForChild('Net')
            :WaitForChild('RE/SpearFishing/Minigame')

        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild('HumanoidRootPart')

        local oldCF = hrp.CFrame
        local locations = {
            CFrame.new(-2831, 129, -2146),
            CFrame.new(2602, -1112, 837),
            CFrame.new(3077, -1116, 794),
            CFrame.new(3076, -1144, 1718),
            CFrame.new(3069, -1144, 2108)
        }

        if _G.ClonedSpearStorage then _G.ClonedSpearStorage:Destroy() end
        _G.ClonedSpearStorage = Instance.new("Folder")
        _G.ClonedSpearStorage.Name = "ClonedSpearStorage"
        _G.ClonedSpearStorage.Parent = ReplicatedStorage

        for _, loc in ipairs(locations) do
            if not dupeFischToggle then break end
            hrp.CFrame = loc
            task.wait(4)

            local targetFolder = nil
            for i = 1, 10 do 
                for _, v in ipairs(workspace:GetChildren()) do
                    if v.Name == 'Spearfishing Water' then
                        if #v:GetChildren() > 0 then
                            targetFolder = v
                            break
                        end
                    end
                end
                if targetFolder then break end
                task.wait(0.5)
            end

            if targetFolder then
                for _, zone in ipairs(targetFolder:GetChildren()) do
                    if zone:FindFirstChild("ZoneFish") and #zone.ZoneFish:GetChildren() > 0 then
                        local zoneClone = zone:Clone()
                        zoneClone.Parent = _G.ClonedSpearStorage
                    end
                end
            end
        end

        hrp.CFrame = oldCF

        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == 'Spearfishing Water' and #v:GetChildren() == 0 then
                v:Destroy()
            end
        end

        while dupeFischToggle do
            if not _G.ClonedSpearStorage or #_G.ClonedSpearStorage:GetChildren() == 0 then break end

            for _, zone in ipairs(_G.ClonedSpearStorage:GetChildren()) do
                local zoneFish = zone:FindFirstChild('ZoneFish')
                if zoneFish then
                    for _, fish in ipairs(zoneFish:GetChildren()) do
                        local uid = fish:GetAttribute('UID')
                        if uid then
                            remote:FireServer(uid)
                            task.wait()
                            remote:FireServer(uid, true)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local AutoMinigames = {
    SetNukeEnabled = function(state)
        AutoNukeEnabled = state
    end,
    SetSpearEnabled = function(state)
        dupeFischToggle = state
        if state then
            startSpearExploits()
        end
    end
}

setmetatable(AutoMinigames, {
    __call = function(self, value)
        AutoNukeEnabled = value
    end
})

return AutoMinigames
