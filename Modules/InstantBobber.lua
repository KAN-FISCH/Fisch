local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lastTargetHrpPos = nil
local lastCalculatedCF = nil
local function GetTargetPosition(hrp, bobberPart)
    if not hrp then
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    if not hrp then return nil end
    local hrpPos = hrp.Position
    if lastTargetHrpPos and lastCalculatedCF and (hrpPos - lastTargetHrpPos).Magnitude < 2 then
        return lastCalculatedCF
    end
    local carrotSecretFolder = workspace:FindFirstChild("world")
        and workspace.world:FindFirstChild("map")
        and workspace.world.map:FindFirstChild("Carrot Secret")
    if carrotSecretFolder then
        local closestDist = math.huge
        local closestMesh = nil
        for _, model in ipairs(carrotSecretFolder:GetChildren()) do
            local mesh = model:FindFirstChild("Meshes/CarrotPool_Cube.001 (1)")
            if mesh and mesh:IsA("MeshPart") then
                local dist = (hrpPos - mesh.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestMesh = mesh
                end
            end
        end
        if closestMesh and closestDist < 50 then
            return CFrame.new(closestMesh.Position - Vector3.new(0, 3, 0))
        end
    end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Include
    Params.FilterDescendantsInstances = {workspace.Terrain}
    Params.IgnoreWater = false
    local scanY = hrpPos.Y + 50
    local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
    local lookVec = hrp.CFrame.LookVector
    local distances = {10, 15, 20, 25, 30, 35, 45}
    for _, dist in ipairs(distances) do
        local testPos = hrpPos + (lookVec * dist)
        local origin = Vector3.new(testPos.X, scanY, testPos.Z)
        local RaycastResult = workspace:Raycast(origin, Vector3.new(0, -300, 0), Params)
        if RaycastResult and RaycastResult.Instance:IsA("Terrain") and RaycastResult.Material == Enum.Material.Water then
            return CFrame.new(RaycastResult.Position - Vector3.new(0, 3, 0))
        end
    end
    local bestPos = nil
    local bestDist = math.huge
    for i = 0, 23 do
        local angle = (i / 24) * (math.pi * 2)
        local cosA = math.cos(angle)
        local sinA = math.sin(angle)
        for _, radius in ipairs({8, 12, 16, 22, 30, 40}) do
            local sx = hrpPos.X + cosA * radius
            local sz = hrpPos.Z + sinA * radius
            local result = workspace:Raycast(Vector3.new(sx, scanY, sz), Vector3.new(0, -300, 0), Params)
            if result and result.Instance:IsA("Terrain") and result.Material == Enum.Material.Water then
                if radius < bestDist then
                    bestDist = radius
                    bestPos = result.Position
                end
                break
            end
        end
    end
    local finalPos = nil
    if closestMesh and closestDist < 50 then
        finalPos = closestMesh.Position - Vector3.new(0, 3, 0)
    elseif bestPos then
        finalPos = bestPos - Vector3.new(0, 3, 0)
    else
        local basePos = head and head.Position or hrpPos
        finalPos = basePos + (lookVec * 10) - Vector3.new(0, 11, 0)
    end
    lastTargetHrpPos = hrpPos
    lastCalculatedCF = CFrame.new(finalPos)
    return lastCalculatedCF
end
local function InstantTeleportBobber(bobber, targetCF, hrp)
    if not bobber or not bobber.Parent then return targetCF end
    local humanoidRootPart = hrp or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
    local finalCF = targetCF or GetTargetPosition(humanoidRootPart, bobber)
    if not finalCF then return targetCF end
    pcall(function()
        if bobber:IsA("BasePart") then
            bobber.CFrame = finalCF
            bobber.AssemblyLinearVelocity = Vector3.zero
        else
            bobber:PivotTo(finalCF)
            if bobber.PrimaryPart then
                bobber.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
    return finalCF
end
local InstantBobber = {
    GetTargetPosition     = GetTargetPosition,
    InstantTeleportBobber = InstantTeleportBobber,
}
setmetatable(InstantBobber, {
    __call = function(_, value)
        _G.Config = _G.Config or {}
        _G.Config.InstantCast = value
    end
})
_G.InstantBobber = InstantBobber
_G.InstantTeleportBobber = InstantTeleportBobber
return InstantBobber