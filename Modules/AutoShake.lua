local Players = game:GetService("Players")
local player = Players.LocalPlayer
task.spawn(function()
    while true do
        if _G.Config and _G.Config.AutoShake then
            local PlayerGui = player:FindFirstChild("PlayerGui")
            local shakeui = PlayerGui and PlayerGui:FindFirstChild("shakeui")
            if shakeui and shakeui.Enabled then
                local safezone = shakeui:FindFirstChild("safezone")
                if safezone then
                    for _, button in ipairs(safezone:GetChildren()) do
                        if (button:IsA("ImageButton") or button:IsA("TextButton")) and button.Visible then
                            pcall(function()
                                if getconnections then
                                    for _, conn in ipairs(getconnections(button.MouseButton1Click)) do
                                        conn:Fire()
                                    end
                                    for _, conn in ipairs(getconnections(button.Activated)) do
                                        conn:Fire()
                                    end
                                elseif firesignal then
                                    firesignal(button.MouseButton1Click)
                                    firesignal(button.Activated)
                                end
                            end)
                        end
                    end
                end
                task.wait(0.02)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
end)
local AutoShake = function(value)
    _G.Config.AutoShake = value
end
return AutoShake