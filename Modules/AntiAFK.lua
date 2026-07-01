-- AntiAFK.lua - Cegah kick AFK dengan simulasi input minimal
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local running = false
local conn = nil

local function start()
    if running then return end
    running = true
    -- Pakai IdleConnection Roblox untuk bypass AFK kick
    Players.LocalPlayer.Idled:Connect(function()
        if not running then return end
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end)
end

local function stop()
    running = false
end

local AntiAFK = {}
setmetatable(AntiAFK, {
    __call = function(_, value)
        _G.Config.AntiAFK = value
        if value then
            start()
        else
            stop()
        end
    end
})

return AntiAFK
