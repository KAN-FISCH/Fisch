
local function init(value)
    print("[NewFish5] Auto Quest Toggle:", value)
    if value then
        task.spawn(function()
            local npc = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") and workspace.world.npcs:FindFirstChild("Angler")
            if npc then
                local rf = game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/Quests/Claim")
                if rf then pcall(function() rf:InvokeServer("Angler") end) end
            end
        end)
    end
end
return init