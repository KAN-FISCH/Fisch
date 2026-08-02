-- InstantBobber.lua - Custom Carrot Secret & Terrain Raycast Teleport
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local cachedWaterParts = nil
local lastCacheTime = 0
local CACHE_LIFETIME = 5 -- Turun dari 15s ke 5s untuk cegah stale cache setelah jam-jaman

local function getWaterParts()
    local now = tick()
    if cachedWaterParts and (now - lastCacheTime) < CACHE_LIFETIME then
        local active = {}
        for _, part in ipairs(cachedWaterParts) do
            if part and part.Parent then
                table.insert(active, part)
            end
        end
        -- Jika semua parts mati (streaming), force refresh
        if #active < 2 then
            cachedWaterParts = nil
        else
            return active
        end
    end

    cachedWaterParts = {workspace.Terrain}
    lastCacheTime = now

    local function scanParts(parent, depth)
        if depth > 3 then return end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:match("water") or n:match("pool") or n:match("ocean") or n:match("lake") or n:match("river") or n:match("sea") or parent.Name == "fishing" then
                    table.insert(cachedWaterParts, v)
                end
            elseif v:IsA("Model") or v:IsA("Folder") then
                scanParts(v, depth + 1)
            end
        end
    end

    local zones = workspace:FindFirstChild("zones")
    if zones then
        local fishing = zones:FindFirstChild("fishing")
        if fishing then
            pcall(scanParts, fishing, 0)
        end
    end

    return cachedWaterParts
end

local function GetTargetPosition(hrp)
    local pos = hrp.Position
    local depth = (_G.Config and type(_G.Config.BobberDepth) == "number") and _G.Config.BobberDepth or 10
    return CFrame.new(pos.X, pos.Y - depth, pos.Z)
end

local function InstantTeleportBobber(bobber, targetCF, hrp)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return targetCF end
    -- PENTING: finalCF SELALU dimulai dari targetCF, TIDAK PERNAH nil
    local finalCF = targetCF
    local ok = pcall(function()
        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        local dropDone = false
        local carrotSecretFolder = workspace:FindFirstChild("world")
            and workspace.world:FindFirstChild("map")
            and workspace.world.map:FindFirstChild("Carrot Secret")
        
        if carrotSecretFolder then
            local closestDist = math.huge
            local closestMesh = nil
            for _, model in ipairs(carrotSecretFolder:GetChildren()) do
                local mesh = model:FindFirstChild("Meshes/CarrotPool_Cube.001 (1)")
                if mesh and mesh:IsA("MeshPart") then
                    local dist = (humanoidRootPart.Position - mesh.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestMesh = mesh
                    end
                end
            end

            if closestMesh and closestDist < 50 then
                finalCF = CFrame.new(closestMesh.Position)
                bobber:PivotTo(finalCF)
                dropDone = true
            end
        end
        
        if not dropDone then
            local waterParts = getWaterParts()

            -- Coba 1: Raycast kebawah dari posisi lemparan asli bobber
            local Params = RaycastParams.new()
            Params.FilterType = Enum.RaycastFilterType.Include
            Params.FilterDescendantsInstances = waterParts

            local castOrigin = Vector3.new(bobber.Position.X, bobber.Position.Y + 25, bobber.Position.Z)
            local RaycastResult = workspace:Raycast(castOrigin, -Vector3.yAxis * 250, Params)
            if RaycastResult then
                finalCF = CFrame.new(RaycastResult.Position.X, RaycastResult.Position.Y - 1.5, RaycastResult.Position.Z)
                bobber:PivotTo(finalCF)
                dropDone = true
            end
            
            -- Coba 2: Fallback closest water part
            if not dropDone then
                local closestWater = nil
                local closestDist = math.huge
                
                for _, part in ipairs(waterParts) do
                    if part ~= workspace.Terrain then
                        local dist = (humanoidRootPart.Position - part.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestWater = part
                        end
                    end
                end

                if closestWater then
                    local targetHorizontal = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 18
                    local surfaceY = closestWater.Position.Y + (closestWater.Size.Y / 2) - 1.5
                    finalCF = CFrame.new(targetHorizontal.X, surfaceY, targetHorizontal.Z)
                    bobber:PivotTo(finalCF)
                    dropDone = true
                end
            end
        end

        -- TIDAK ada lagi finalCF = nil!
        -- Jika semua gagal, finalCF tetap targetCF (posisi default dari GetTargetPosition)
        -- Bobber akan di-PivotTo targetCF sebagai fallback
        if not dropDone then
            bobber:PivotTo(finalCF)
        end
        
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
    end)
    
    -- Jika seluruh pcall error, tetap return targetCF (bukan nil!)
    return finalCF or targetCF
end

local function LockBobberPhysics(bobber)
    if not bobber or not bobber:IsA("BasePart") or not bobber.Parent then return end
    pcall(function()
        bobber.AssemblyLinearVelocity = Vector3.zero
        bobber.AssemblyAngularVelocity = Vector3.zero
    end)
end

local InstantBobber = {
    GetTargetPosition     = GetTargetPosition,
    InstantTeleportBobber = InstantTeleportBobber,
}

setmetatable(InstantBobber, {
    __call = function(_, value)
        _G.Config.InstantCast = value
    end
})

return InstantBobber
