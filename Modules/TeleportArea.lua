local Players = game:GetService("Players")

local function init(areaCFrame)
    if not areaCFrame then return end

    local char = Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if _G.__var then
            _G.__var.savedPosition = char.HumanoidRootPart.CFrame
        end

        char.HumanoidRootPart.CFrame = areaCFrame
        task.wait(0.5)
    end
end

return init