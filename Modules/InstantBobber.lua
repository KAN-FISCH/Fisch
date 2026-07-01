-- InstantBobber.lua - Water detection via Terrain material
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Tembak ray dari ATAS (Y+100) ke bawah jauh, cari permukaan air
-- Mulai dari atas supaya tidak nabrak lantai dok/jembatan duluan
local function findWaterY(worldPos)
    local char = LocalPlayer.Character
    if char then rayParams.FilterDescendantsInstances = {char} end

    local startY = worldPos.Y + 100
    local origin  = Vector3.new(worldPos.X, startY, worldPos.Z)
    local dir     = Vector3.new(0, -300, 0)

    local hit = workspace:Raycast(origin, dir, rayParams)
    if hit then
        -- Cek Terrain → material Air
        if hit.Instance:IsA("Terrain") then
            -- Material.Water = air di Roblox
            if hit.Material == Enum.Material.Water then
                return hit.Position.Y - 1.5
            end
        end
        -- Cek BasePart bernama air
        local n = hit.Instance.Name:lower()
        if n:find("water") or n:find("ocean") or n:find("sea") or n:find("lake") or n:find("river") then
            return hit.Position.Y - 1.5
        end
        -- Kena lantai/dok → coba raycast lagi dari bawah lantai itu
        local belowOrigin = Vector3.new(worldPos.X, hit.Position.Y - 0.5, worldPos.Z)
        local hit2 = workspace:Raycast(belowOrigin, Vector3.new(0, -200, 0), rayParams)
        if hit2 then
            if hit2.Instance:IsA("Terrain") and hit2.Material == Enum.Material.Water then
                return hit2.Position.Y - 1.5
            end
            local n2 = hit2.Instance.Name:lower()
            if n2:find("water") or n2:find("ocean") or n2:find("sea") or n2:find("lake") then
                return hit2.Position.Y - 1.5
            end
        end
    end
    return nil
end

-- Cari posisi air di sekitar karakter (bawah kaki + arah depan/kiri/kanan)
local function GetTargetPosition(hrp)
    local pos   = hrp.Position
    local look  = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector

    -- Coba beberapa titik: langsung bawah kaki, depan, kiri, kanan
    local tries = {
        pos,                             -- bawah kaki
        pos + look * 5,                  -- 5 depan
        pos + look * 10,                 -- 10 depan
        pos + look * 3 + right * 3,      -- diagonal kanan
        pos + look * 3 - right * 3,      -- diagonal kiri
        pos - look * 3,                  -- belakang sedikit
    }

    for _, t in ipairs(tries) do
        local waterY = findWaterY(t)
        if waterY then
            return CFrame.new(t.X, waterY, t.Z)
        end
    end

    -- Fallback: di bawah kaki aja
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
