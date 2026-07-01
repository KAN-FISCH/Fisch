
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local oxyConn = nil

local function init(value)
    print("[NewFish5] Disable Oxygen Toggle:", value)
    if value then
        oxyConn = RunService.Heartbeat:Connect(function()
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("client") and char.client:FindFirstChild("oxygen") then
                char.client.oxygen:Destroy()
            end
        end)
    else
        if oxyConn then
            oxyConn:Disconnect()
            oxyConn = nil
        end
    end
end
return init