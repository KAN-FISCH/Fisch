-- AntiAFK.lua - Cegah kick AFK secara aman menggunakan input OS-level executor murni (No VirtualUser, No VIM, No Idled hook)
local Players = game:GetService("Players")

local running = false

local function simulateInput()
    -- Menggunakan fungsi input bawaan executor (OS-level simulation)
    -- Ini sepenuhnya tidak terdeteksi karena tidak menggunakan Roblox Service (VirtualUser/VirtualInputManager)
    pcall(function()
        if keyclick then
            keyclick(17) -- VK_CONTROL (Ctrl)
        elseif keypress and keyrelease then
            keypress(17)
            task.wait(0.05)
            keyrelease(17)
        elseif keydown and keyup then
            keydown(17)
            task.wait(0.05)
            keyup(17)
        elseif presskey and releasekey then
            presskey(17)
            task.wait(0.05)
            releasekey(17)
        end
    end)
    
    pcall(function()
        if mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end
    end)
end

local function start()
    if running then return end
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        task.spawn(function()
            while not Players.LocalPlayer do
                task.wait(0.5)
            end
            start()
        end)
        return
    end

    running = true

    -- Loop berkala dengan waktu acak (50-70 detik) untuk menghindari deteksi pola
    task.spawn(function()
        while running do
            task.wait(math.random(50, 70))
            if not running then break end
            simulateInput()
        end
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
