local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local lastBvTo = Vector3.new()
local activeVolleyRunning = false

local function AutoVolleyLoop()
    if activeVolleyRunning then return end
    activeVolleyRunning = true
    task.spawn(function()
        while _G.Config and _G.Config.AutoVolley do
            task.wait(0.1)
            pcall(function()
                local player = LocalPlayer
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart

                local vbGui = player.PlayerGui:FindFirstChild("volleyball")
                local isPlaying = vbGui and vbGui.Enabled

                local courts = CollectionService:GetTagged("BeachVolleyballCourt")
                if #courts == 0 then return end

                local closestCourt, minDistance = nil, math.huge
                for _, court in ipairs(courts) do
                    if court:FindFirstChild("Side1") then
                        local dist = (hrp.Position - court.Side1.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closestCourt = court
                        end
                    end
                end
                if not closestCourt then return end

                if not isPlaying and _G.Config.AutoJoinVolley then
                    local targetSideStr = _G.Config.VolleySide or "Side 1"
                    local targetSideName = (targetSideStr == "Side 1") and "Side1" or "Side2"
                    local sidePart = closestCourt:FindFirstChild(targetSideName)
                    if sidePart then
                        local prompt = sidePart:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            hrp.CFrame = sidePart.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.3)
                            if fireproximityprompt then
                                fireproximityprompt(prompt, 1, true)
                            end
                            task.wait(1.5)
                        end
                    end
                    return
                end

                if isPlaying then
                    local volleyMode = _G.Config.VolleyMode or "Win"
                    if volleyMode == "Lose" then return end

                    local distance = (hrp.Position - closestCourt.Side1.Position).Magnitude
                    if distance < 200 then
                        local ball = closestCourt:FindFirstChild("Ball")
                        if ball and ball:GetAttribute("BV_Active") then
                            local bvTo = ball:GetAttribute("BV_To")
                            if bvTo and typeof(bvTo) == "Vector3" then
                                if (bvTo - lastBvTo).Magnitude > 0.5 then
                                    local side1 = closestCourt:FindFirstChild("Side1")
                                    local side2 = closestCourt:FindFirstChild("Side2")
                                    local isOurSide = true
                                    if side1 and side2 then
                                        local mySide = side1
                                        if (hrp.Position - side2.Position).Magnitude < (hrp.Position - side1.Position).Magnitude then
                                            mySide = side2
                                        end
                                        local otherSide = (mySide == side1) and side2 or side1
                                        if (bvTo - mySide.Position).Magnitude > (bvTo - otherSide.Position).Magnitude then
                                            isOurSide = false
                                        end
                                    end
                                    if isOurSide then
                                        lastBvTo = bvTo
                                        hrp.CFrame = CFrame.new(bvTo.X, bvTo.Y + 1, bvTo.Z)
                                        local net = closestCourt:FindFirstChild("Net")
                                        if net then
                                            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(net.Position.X, hrp.Position.Y, net.Position.Z))
                                        end
                                    end
                                end
                            end
                        else
                            lastBvTo = Vector3.new()
                        end
                    end
                end
            end)
        end
        activeVolleyRunning = false
    end)
end

local AutoMine = {}
setmetatable(AutoMine, {
    __call = function(self, value)
        _G.Config.AutoVolley = value
        if value then
            AutoVolleyLoop()
        end
    end
})

return AutoMine
