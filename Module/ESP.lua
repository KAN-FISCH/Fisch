local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EspPlayers = false
local EspZone = false
local EspNpc = false

local function AddEsp(target, name, color, offset)
    if not target then return end
    if target:FindFirstChild("BF_ESP") then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "BF_ESP"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.Adornee = target
    bill.StudsOffset = offset or Vector3.new(0, 3, 0)

    local text = Instance.new("TextLabel", bill)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = color
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.Text = name
    bill.Parent = target

    if target.Parent and target.Parent:IsA("Model") then
        local h = Instance.new("Highlight")
        h.Name = "BF_Highlight"
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.8
        h.Adornee = target.Parent
        h.Parent = target
    end
end

local function RemoveEsp(target)
    if target and target:FindFirstChild("BF_ESP") then
        target.BF_ESP:Destroy()
    end
    if target and target:FindFirstChild("BF_Highlight") then
        target.BF_Highlight:Destroy()
    end
end

-- Initialize Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if EspPlayers then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    AddEsp(hrp, p.Name, Color3.fromRGB(255, 0, 0))
                    if hrp:FindFirstChild("BF_ESP") then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local dist = (myRoot.Position - hrp.Position).Magnitude
                            hrp.BF_ESP.TextLabel.Text = p.Name .. " [" .. math.floor(dist) .. "m]"
                        end
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    RemoveEsp(p.Character.HumanoidRootPart)
                end
            end
        end

        if EspZone then
            local fishingFolder = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
            if fishingFolder then
                for _, zone in ipairs(fishingFolder:GetChildren()) do
                    local part = zone:IsA("BasePart") and zone or (zone:IsA("Model") and zone.PrimaryPart)
                    if part then
                        AddEsp(part, zone.Name, Color3.fromRGB(0, 255, 200))
                    end
                end
            end
        end

        if EspNpc then
            local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            if npcsFolder then
                for _, npc in ipairs(npcsFolder:GetChildren()) do
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        AddEsp(hrp, npc.Name, Color3.fromRGB(255, 255, 0))
                    end
                end
            end
        end
    end
end)

local ESP = {
    SetEspPlayers = function(state) EspPlayers = state end,
    SetEspZone = function(state) EspZone = state end,
    SetEspNpc = function(state) EspNpc = state end,
    AddEsp = AddEsp,
    RemoveEsp = RemoveEsp,
}

setmetatable(ESP, {
    __call = function(self, mode, value)
        if mode == "Players" then
            EspPlayers = value
        elseif mode == "Zone" or mode == "Zones" then
            EspZone = value
        elseif mode == "NPC" or mode == "NPCs" then
            EspNpc = value
        end
    end
})

return ESP
