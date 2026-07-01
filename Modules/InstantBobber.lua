-- InstantBobber.lua - Simple version, bobber di bawah kaki player
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Posisi bobber: langsung di bawah karakter (Y - 3 stud)
-- Tidak perlu raycast / scan zona air
local function GetTargetPosition(hrp)
    local pos = hrp.Position
    return CFrame.new(pos.X, pos.Y - 3, pos.Z)
end

-- Teleport instan bobber ke posisi target
local function InstantTeleportBobber(bobber, targetCF)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    if not targetCF then return end
    pcall(function()
        bobber.CFrame = targetCF
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
