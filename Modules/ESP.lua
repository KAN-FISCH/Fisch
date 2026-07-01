local Players = game:GetService("Players")

local function init(espType, value)
    print(string.format("[NewFish5] ESP %s toggled: %s", espType, tostring(value)))
    if espType == "Players" then
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Players.LocalPlayer and v.Character then
                local hl = v.Character:FindFirstChild("Shield_ESP")
                if value and not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "Shield_ESP"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = v.Character
                elseif not value and hl then
                    hl:Destroy()
                end
            end
        end
    end
end

return init