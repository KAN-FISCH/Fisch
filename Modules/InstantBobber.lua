-- InstantBobber.lua - Deteksi permukaan air via raycast
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Cari posisi di bawah permukaan air via raycast ke bawah dari posisi karakter
local function GetTargetPosition(hrp)
    local pos = hrp.Position
    local char = LocalPlayer.Character
    if char then
        rayParams.FilterDescendantsInstances = {char}
    end

    -- Tembak ray ke bawah dari posisi karakter
    local hit = workspace:Raycast(pos, Vector3.new(0, -50, 0), rayParams)
    if hit and hit.Instance then
        local hitName = hit.Instance.Name:lower()
        -- Kena air/terrain/laut → Y permukaan - 1.5 (sedikit di bawah air)
        if hit.Instance:IsA("Terrain")
            or hitName:find("water") or hitName:find("ocean")
            or hitName:find("lake") or hitName:find("sea")
            or hitName:find("river") or hitName:find("pond") then
            return CFrame.new(pos.X, hit.Position.Y - 1.5, pos.Z)
        end
    end

    -- Fallback: langsung di bawah kaki
    return CFrame.new(pos.X, pos.Y - 3, pos.Z)
end

-- Zero velocity bobber
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
}

setmetatable(InstantBobber, {
    __call = function(_, value)
        _G.Config.InstantCast = value
    end
})

return InstantBobber
