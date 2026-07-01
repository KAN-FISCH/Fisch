-- InstantBobber.lua - Optimized lightweight version
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Cache zona air - di-scan SEKALI saja, tidak tiap heartbeat
local waterParts = {}
local cacheBuilt = false

local MIN_DIST  = 8
local MAX_DIST  = 60
local DEPTH     = 1.5

-- Scan workspace satu kali, hanya cari BasePart yang namanya mengandung kata air
-- Tidak rekursif deep scan - cukup 3 level saja agar ringan
local function buildCache()
    if cacheBuilt then return end
    cacheBuilt = true
    waterParts = {}

    local function scanLevel(parent, depth)
        if depth > 3 then return end
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("water") or n:find("ocean") or n:find("lake") or n:find("sea") or n:find("pond") then
                    waterParts[#waterParts + 1] = obj
                end
            elseif obj:IsA("Model") or obj:IsA("Folder") then
                scanLevel(obj, depth + 1)
            end
        end
    end

    -- Prioritas: zona fishing di workspace.world
    local world = workspace:FindFirstChild("world")
    if world then
        local zones = world:FindFirstChild("zones")
        if zones then
            local fishing = zones:FindFirstChild("fishing")
            if fishing then
                for _, part in ipairs(fishing:GetDescendants()) do
                    if part:IsA("BasePart") then
                        waterParts[#waterParts + 1] = part
                    end
                end
            end
        end
        -- Juga scan world langsung (kedalaman 2)
        scanLevel(world, 0)
    end

    -- Fallback: scan workspace level atas saja
    if #waterParts == 0 then
        scanLevel(workspace, 0)
    end
end

-- Bersihkan cache saat pindah zona/server
workspace.ChildAdded:Connect(function() cacheBuilt = false; waterParts = {} end)
workspace.ChildRemoved:Connect(function() cacheBuilt = false; waterParts = {} end)

-- Cari permukaan air via raycast sederhana dari titik di depan karakter
local function findWater(origin, hrpPos)
    local rayStart = Vector3.new(origin.X, math.max(hrpPos.Y, origin.Y) + 20, origin.Z)
    local rayDir   = Vector3.new(0, -200, 0)

    -- Coba raycast ke zona air spesifik
    if #waterParts > 0 then
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Include
        p.FilterDescendantsInstances = waterParts
        local hit = workspace:Raycast(rayStart, rayDir, p)
        if hit then
            return CFrame.new(origin.X, hit.Position.Y - DEPTH, origin.Z)
        end
    end

    -- Fallback raycast umum (abaikan karakter sendiri)
    local p2 = RaycastParams.new()
    p2.FilterType = Enum.RaycastFilterType.Exclude
    p2.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit2 = workspace:Raycast(rayStart, rayDir, p2)
    if hit2 then
        return CFrame.new(origin.X, hit2.Position.Y - DEPTH, origin.Z)
    end
    return nil
end

-- Posisi target bobber di depan karakter
local function GetTargetPosition(hrp)
    buildCache() -- no-op setelah pertama kali
    local pos = hrp.Position
    local look = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector

    -- Coba beberapa titik di depan karakter (dari dekat ke jauh)
    local tries = {
        pos + look * MIN_DIST,
        pos + look * 12,
        pos + look * 18,
        pos + look * 12 + right * 2,
        pos + look * 12 - right * 2,
    }

    for _, t in ipairs(tries) do
        local cf = findWater(t, pos)
        if cf and (pos - cf.Position).Magnitude <= MAX_DIST then
            return cf
        end
    end

    -- Fallback: titik 8 studs di depan, turunkan ke bawah karakter
    local fb = pos + look * MIN_DIST
    return CFrame.new(fb.X, pos.Y - 8, fb.Z)
end

-- Zero velocity bobber agar tidak terbawa fisik
local function LockBobberPhysics(bobber)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    pcall(function()
        bobber.CanCollide = false
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
    end)
end

-- Teleport instan bobber ke posisi target
local function InstantTeleportBobber(bobber, targetCF)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    if not targetCF then return end
    pcall(function()
        bobber.CanCollide = false
        bobber.CFrame = targetCF
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
    end)
end

local InstantBobber = {
    GetTargetPosition     = GetTargetPosition,
    InstantTeleportBobber = InstantTeleportBobber,
    LockBobberPhysics     = LockBobberPhysics,
    InvalidateCache       = function() cacheBuilt = false; waterParts = {} end,
}

setmetatable(InstantBobber, {
    __call = function(_, value)
        _G.Config.InstantCast = value
    end
})

return InstantBobber
