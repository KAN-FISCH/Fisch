local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local LENSES = {
    {
        Name = "Deep Lens",
        Anomaly = "Abyssal Alignment",
        Buff = "+25% Catch Weight",
        Recipe = "1 Hardened Glass, 1 Abyssal Comb Jelly, 1 Abyssal Resin",
        HowToGet = "Crafted at Astronomer Vega (The Laboratory)"
    },
    {
        Name = "Seasonal Lens",
        Anomaly = "Evershifting Eclipse",
        Buff = "+25% XP",
        Recipe = "1 Seasonal Glass, 1 Seasonal Everturn Sturgeon, 1 Rotting Glass Diamond",
        HowToGet = "Crafted at Astronomer Vega (The Laboratory)"
    },
    {
        Name = "Experimental Lens",
        Anomaly = "Meteoric Outburst",
        Buff = "4-6 items per meteor & increased Gem odds",
        Recipe = "1 Quartz Glass, 1 Chaotic Golden Trout, 1 Fallen Resin",
        HowToGet = "Crafted at Astronomer Vega (The Laboratory)"
    },
    {
        Name = "Moonlit Lens",
        Anomaly = "Lunar Eclipse",
        Buff = "5% mutation chance for Aurora, Lunar, Celestial, & Nova",
        Recipe = "1 Frozen Glass, 1 Aurora Boreal Man O' War, 1 Frozen Resin",
        HowToGet = "Crafted at Astronomer Vega (The Laboratory)"
    },
    {
        Name = "Stellar Lens",
        Anomaly = "Celestial Congregation",
        Buff = "+25% Luck",
        Recipe = "6 Broken Stars (Scattered across the map)",
        HowToGet = "Brayden Quest at Boreal Pines"
    }
}

local LENS_NAMES = {
    "Deep Lens",
    "Seasonal Lens",
    "Experimental Lens",
    "Moonlit Lens",
    "Stellar Lens"
}

local function isNight()
    local clock = Lighting.ClockTime
    return clock >= 18 or clock <= 6
end

local function FireProximity(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif prompt.InputHoldBegin then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.05)
            prompt:InputHoldEnd()
        end
    end)
end

local function SafeTP(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
        char:PivotTo(targetCFrame)
        task.wait(0.05)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

local cachedTelescopePart = nil
local cachedTelescopePrompt = nil

local function findTelescope()
    if cachedTelescopePart and cachedTelescopePart.Parent then
        local p = cachedTelescopePrompt and cachedTelescopePrompt.Parent and cachedTelescopePrompt
        if not p then
            p = cachedTelescopePart:FindFirstChildWhichIsA("ProximityPrompt", true)
        end
        return cachedTelescopePart, p
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower():find("telescope") and not obj.Name:lower():find("fish") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if part then
                cachedTelescopePart = part
                cachedTelescopePrompt = prompt
                return part, prompt
            end
        end
    end
    return nil, nil
end

local function findAstronomerVega()
    local npcsFolder = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
    if npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local n = npc.Name:lower()
            if n:find("vega") or n:find("astronomer") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChild("Head")
                if hrp then return npc, hrp end
            end
        end
    end
    for _, npc in ipairs(CollectionService:GetTagged("NewNpc")) do
        local n = npc.Name:lower()
        if n:find("vega") or n:find("astronomer") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChild("Head")
            if hrp then return npc, hrp end
        end
    end
    return nil, nil
end

local function equipItem(itemName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- Check character first
    if char:FindFirstChild(itemName) then return true end

    -- Check backpack
    local tool = backpack and backpack:FindFirstChild(itemName)
    if not tool then
        -- Partial search
        local itemLower = itemName:lower()
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(itemLower, 1, true) then
                tool = t
                break
            end
        end
    end

    if tool then
        hum:EquipTool(tool)
        task.wait(0.3)
        return true
    end
    return false
end

local function activateTelescope(selectedLens)
    selectedLens = selectedLens or (_G.Config and _G.Config.SelectedLens) or "Stellar Lens"
    local tPart, tPrompt = findTelescope()
    if not tPart then
        warn("[NewFish5] Telescope model not found in workspace!")
        return false
    end

    -- Teleport to telescope
    SafeTP(tPart.CFrame + Vector3.new(0, 3, 3))
    task.wait(0.5)

    -- Try to equip battery if available
    equipItem("Battery")
    equipItem("Telescope Battery")
    task.wait(0.2)

    -- If there's a battery prompt, trigger it
    if tPrompt then
        FireProximity(tPrompt)
        task.wait(0.5)
    end

    -- Equip the chosen lens
    local lensEquipped = equipItem(selectedLens)
    task.wait(0.3)

    -- Re-find prompt and trigger
    local _, freshPrompt = findTelescope()
    if freshPrompt then
        FireProximity(freshPrompt)
        task.wait(0.5)
    end

    return true
end

local autoTelescopeRunning = false
local function StartAutoTelescopeLoop()
    if autoTelescopeRunning then return end
    autoTelescopeRunning = true

    task.spawn(function()
        local lastActivatedNight = -1
        while _G.Config and _G.Config.AutoTelescope do
            task.wait(2)
            pcall(function()
                if isNight() then
                    local currentDay = math.floor(workspace:GetServerTimeNow() / 86400)
                    if lastActivatedNight ~= currentDay then
                        local selected = (_G.Config and _G.Config.SelectedLens) or "Stellar Lens"
                        local ok = activateTelescope(selected)
                        if ok then
                            lastActivatedNight = currentDay
                        end
                    end
                end
            end)
        end
        autoTelescopeRunning = false
    end)
end

local function StopAutoTelescopeLoop()
    if _G.Config then
        _G.Config.AutoTelescope = false
    end
    autoTelescopeRunning = false
end

local function TeleportToTelescope()
    local tPart = findTelescope()
    if tPart then
        SafeTP(tPart.CFrame + Vector3.new(0, 3, 3))
        return true
    else
        warn("[NewFish5] Telescope not located!")
        return false
    end
end

local function TeleportToAstronomerVega()
    local npc, hrp = findAstronomerVega()
    if hrp then
        SafeTP(hrp.CFrame + Vector3.new(0, 2, 3))
        return true
    else
        warn("[NewFish5] Astronomer Vega not located!")
        return false
    end
end

local function GetLensList()
    return LENS_NAMES
end

local function GetLensDetails(lensName)
    for _, info in ipairs(LENSES) do
        if info.Name == lensName then
            return info
        end
    end
    return nil
end

return {
    Lenses = LENSES,
    LensNames = LENS_NAMES,
    GetLensList = GetLensList,
    GetLensDetails = GetLensDetails,
    ActivateTelescope = activateTelescope,
    StartLoop = StartAutoTelescopeLoop,
    StopLoop = StopAutoTelescopeLoop,
    TeleportToTelescope = TeleportToTelescope,
    TeleportToAstronomerVega = TeleportToAstronomerVega,
    IsNight = isNight,
    FindTelescope = findTelescope,
    FindAstronomerVega = findAstronomerVega,
}
