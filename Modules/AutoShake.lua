local function PureAutoShake()
    task.spawn(function()
        local lastButtonCount = 0
        local cachedButtons = {}
        local cacheTimer = 0

        while task.wait(0.1) do
            if not _G.Config or not _G.Config.AutoShake then continue end

            local player = game.Players.LocalPlayer
            local PlayerGui = player:FindFirstChild("PlayerGui")
            if not PlayerGui then continue end

            local shakeui = PlayerGui:FindFirstChild("shakeui")
            if not shakeui then continue end

            if shakeui:IsA("ScreenGui") and shakeui.Enabled then
                shakeui.Enabled = false
            end

            local safezone = shakeui:FindFirstChild("safezone")
            if not safezone then continue end

            if safezone.Visible then
                safezone.Visible = false
            end

            cacheTimer = cacheTimer + 0.1
            local children = safezone:GetChildren()
            if cacheTimer >= 0.5 or #children ~= lastButtonCount then
                cacheTimer = 0
                lastButtonCount = #children
                cachedButtons = {}
                for _, btn in pairs(children) do
                    if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                        table.insert(cachedButtons, btn)
                    end
                end
            end

            for _, button in pairs(cachedButtons) do
                if button.Visible then
                    pcall(function()
                        if getconnections then
                            for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                                conn:Fire()
                            end
                            for _, conn in pairs(getconnections(button.Activated)) do
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
    end)
end

local function init(value)
    task.spawn(function()
                    _G.Config.AutoShake = value
                    if _G.Config.AutoShake then
                        PureAutoShake()
                    end
                end)
end

return init
