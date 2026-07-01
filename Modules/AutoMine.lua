
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local mineConn = nil
local lastMine = 0

local function init(value)
    print("[NewFish5] Auto Mine Dripstone Enabled:", value)
    if value then
        mineConn = RunService.Heartbeat:Connect(function()
            if tick() - lastMine < 0.5 then return end
            lastMine = tick()
            pcall(function()
                local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, v in pairs(workspace.world.interactables:GetChildren()) do
                        if v.Name == "Dripstone" and v:FindFirstChild("Pickaxe") then
                            if (v.WorldPivot.Position - hrp.Position).Magnitude <= 15 then
                                local re = game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Dripstone/Hit")
                                if re then re:FireServer(v) end
                            end
                        end
                    end
                end
            end)
        end)
    else
        if mineConn then
            mineConn:Disconnect()
            mineConn = nil
        end
    end
end
return init