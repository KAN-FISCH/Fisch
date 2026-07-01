local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoNukeEnabled = false
local dupeFischToggle = false

local function pressButton(button)
    if getconnections then
        for _, connection in pairs(getconnections(button.Activated)) do
            connection:Fire({
                UserInputType = Enum.UserInputType.Keyboard
            })
        end
    end
end

-- Initialize Loops
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoNukeEnabled then
            pcall(function()
                local nukeGui, pointer, leftBtn, rightBtn
                for _, desc in pairs(game:GetDescendants()) do
                    if desc.Name == "NukeMinigame" and desc:IsA("ScreenGui") then
                        nukeGui = desc
                        pointer = nukeGui.Center.Marker.Pointer.Frame
                        leftBtn = nukeGui.Center.Left
                        rightBtn = nukeGui.Center.Right
                        break
                    end
                end
                if nukeGui and pointer and leftBtn and rightBtn and nukeGui.Enabled then
                    local rot = pointer.AbsoluteRotation
                    if rot < -35 then
                        pressButton(rightBtn)
                    elseif rot > 35 then
                        pressButton(leftBtn)
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
