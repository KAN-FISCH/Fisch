-- InstantBobber.lua - Simple, bobber di bawah kaki karakter
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Posisi target: langsung di bawah kaki karakter (Y - BobberDepth)
local function GetTargetPosition(hrp)
    local pos = hrp.Position
    local depth = (_G.Config and type(_G.Config.BobberDepth) == "number") and _G.Config.BobberDepth or 10
    return CFrame.new(pos.X, pos.Y - depth, pos.Z)
end

-- Teleport bobber ke posisi target + zero velocity
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

-- Zero velocity saja tanpa physics constraint
local function LockBobberPhysics(bobber)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    pcall(function()
        bobber.CanCollide = false
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
