
local Players = game:GetService("Players")

local function init(npcName)
    print("[NewFish5] Teleporting to NPC:", npcName)
    local char = Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local npc = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs") and workspace.world.npcs:FindFirstChild(npcName)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame
        task.wait(0.5)
    end
end
return init