local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local cachedFishingParts = {}
local cachedCarrotMeshes = {}
local cacheValid = false
local lastCacheTime = 0
local CACHE_LIFETIME = 30

local MIN_DISTANCE = 8
local SAFE_DISTANCE = 18
local MAX_BOBBER_DISTANCE = 60

local function rebuildCache()
    cachedFishingParts = {}
    cachedCarrotMeshes = {}
    local function scanParts(parent, depth)
        if depth > 6 then return end
        for _, part in ipairs(parent:GetChildren()) do
            if part:IsA("BasePart") then
                local name = part.Name:lower()
                if name:find("water") or name:find("ocean") or name:find("lake") or name:find("sea") then
                    table.insert(cachedFishingParts, part)
                elseif name:find("carrot") then
                    table.insert(cachedCarrotMeshes, part)
                end
            elseif part:IsA("Folder") or part:IsA("Model") then
                scanParts(part, depth + 1)
            end
        end
    end
    scanParts(workspace, 0)
    cacheValid = true
    lastCacheTime = tick()
end

local function ensureCache()
    local now = tick()
    if not cacheValid or (now - lastCacheTime) > CACHE_LIFETIME then
        rebuildCache()
    end
end

local function lockBobberPhysics(bobber)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    pcall(function()
        bobber.CanCollide = false
        bobber.Anchored = false
        bobber.Massless = true
        bobber.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0, 0, 0.5, 0.5)
        local bp = bobber:FindFirstChild("HoldPos")
        if not bp then
            bp = Instance.new("BodyPosition")
            bp.Name = "HoldPos"
            bp.Parent = bobber
        end
        bp.MaxForce = Vector3.new(50000, 50000, 50000)
        bp.Position = bobber.Position
        bp.P = 5000
        bp.D = 200
        local bg = bobber:FindFirstChild("HoldRot")
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.Name = "HoldRot"
            bg.Parent = bobber
        end
        bg.MaxTorque = Vector3.new(50000, 50000, 50000)
        bg.CFrame = bobber.CFrame
        bg.P = 5000
        bg.D = 200
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
        for _, part in ipairs(bobber:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent then
                part.CanCollide = false
                part.Massless = true
            end
        end
    end)
end

local function findWaterSurface(horizontalPos, hrpPos, maxDistance)
    local startHeight = math.max(hrpPos.Y, horizontalPos.Y) + 20
    local rayOrigin = Vector3.new(horizontalPos.X, startHeight, horizontalPos.Z)
    local rayDirection = Vector3.new(0, -200, 0)
    local BOBBER_DEPTH = 1.5

    local filterType = Enum.RaycastFilterType.Exclude

    if #cachedFishingParts > 0 then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Include
        raycastParams.FilterDescendantsInstances = cachedFishingParts
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if result and result.Instance then
            local finalPos = Vector3.new(horizontalPos.X, result.Position.Y - BOBBER_DEPTH, horizontalPos.Z)
            if (hrpPos - finalPos).Magnitude <= maxDistance then
                return CFrame.new(finalPos)
            end
        end
    end

    local raycastParams2 = RaycastParams.new()
    raycastParams2.FilterType = filterType
    raycastParams2.FilterDescendantsInstances = {LocalPlayer.Character}
    local result2 = workspace:Raycast(rayOrigin, rayDirection, raycastParams2)
    if result2 and result2.Instance then
        local finalPos = Vector3.new(horizontalPos.X, result2.Position.Y - BOBBER_DEPTH, horizontalPos.Z)
        if (hrpPos - finalPos).Magnitude <= maxDistance then
            return CFrame.new(finalPos)
        end
    end
    return nil
end

local function getTargetPosition(hrp)
    ensureCache()
    local hrpPos = hrp.Position
    local lookVector = hrp.CFrame.LookVector

    -- Prioritize carrot meshes
    if #cachedCarrotMeshes > 0 then
        local closestMesh, closestDist = nil, math.huge
        for i = 1, #cachedCarrotMeshes do
            local mesh = cachedCarrotMeshes[i]
            if mesh and mesh.Parent then
                local dist = (hrpPos - mesh.Position).Magnitude
                if dist < closestDist and dist <= MAX_BOBBER_DISTANCE then
                    closestDist = dist
                    closestMesh = mesh
                end
            end
        end
        if closestMesh and closestDist <= SAFE_DISTANCE then
            return CFrame.new(closestMesh.Position)
        end
    end

    -- Try positions in front of character
    if #cachedFishingParts > 0 then
        local rightVector = hrp.CFrame.RightVector
        local testPositions = {
            hrpPos + lookVector * MIN_DISTANCE,
            hrpPos + lookVector * 12,
            hrpPos + lookVector * SAFE_DISTANCE,
            hrpPos + lookVector * 12 + rightVector * 2,
            hrpPos + lookVector * 12 - rightVector * 2,
        }
        for _, testPos in ipairs(testPositions) do
            local waterCFrame = findWaterSurface(testPos, hrpPos, MAX_BOBBER_DISTANCE)
            if waterCFrame then return waterCFrame end
        end
    end

    -- Fallback
    local fallbackPos = hrpPos + lookVector * MIN_DISTANCE
    local startHeight = math.max(hrpPos.Y, fallbackPos.Y) + 20
    local rayOrigin = Vector3.new(fallbackPos.X, startHeight, fallbackPos.Z)
    local rayDirection = Vector3.new(0, -200, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return CFrame.new(fallbackPos.X, result.Position.Y - 1.5, fallbackPos.Z)
    end

    return CFrame.new(fallbackPos.X, hrpPos.Y - 10, fallbackPos.Z)
end

local function instantTeleportBobber(bobber, targetCFrame, hrp)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    if not targetCFrame or not hrp or not hrp.Parent then return end
    pcall(function()
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * 0.5, 0, (math.random() - 0.5) * 0.5
        )
        bobber.CFrame = targetCFrame + randomOffset
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
    end)
    lockBobberPhysics(bobber)
    task.defer(function()
        pcall(function()
            if bobber and bobber.Parent then
                bobber.CFrame = targetCFrame
                bobber.AssemblyLinearVelocity = Vector3.zero
                bobber.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end)
end

local InstantBobber = {
    GetTargetPosition = getTargetPosition,
    InstantTeleportBobber = instantTeleportBobber,
    LockBobberPhysics = lockBobberPhysics,
    EnsureCache = ensureCache,
}

setmetatable(InstantBobber, {
    __call = function(self, value)
        _G.Config.InstantCast = value
    end
})

return InstantBobber
