local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function DisableOxygenScript()
    local char = LocalPlayer.Character
    if not char then return end
    local resources = char:FindFirstChild("Resources")
    if not resources then return end

    local scriptNames = {"oxygen", "oxygen(peaks)", "snow", "gas", "temperature", "temperature(heat)"}
    for _, name in ipairs(scriptNames) do
        local script = resources:FindFirstChild(name)
        if script and script:IsA("LocalScript") then
            script.Disabled = true
        end
    end
end

-- Initialize Loop
task.spawn(function()
    while true do
        task.wait(1)
        if _G.Config and _G.Config.DisableOxygen then
            DisableOxygenScript()
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if _G.Config and _G.Config.DisableOxygen then
        DisableOxygenScript()
    end
end)

local DisableOxygen = {}
setmetatable(DisableOxygen, {
    __call = function(self, value)
        _G.Config.DisableOxygen = value
        if value then DisableOxygenScript() end
    end
})

return DisableOxygen
