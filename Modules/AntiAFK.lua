-- AntiAFK.lua - Cegah kick AFK dengan mematikan koneksi Idled dan simulasi input UNC
local Players = game:GetService("Players")

local running = false
local disabledConnections = {}
local idledConnection = nil

local function simulateInput()
    -- Simulasikan input menggunakan fungsi UNC executor (bukan VirtualUser/VirtualInputManager)
    pcall(function()
        if keypress and keyrelease then
            keypress(0x11) -- VK_CONTROL
            task.wait(0.1)
            keyrelease(0x11)
        end
    end)
    pcall(function()
        if mousemoveby then
            mousemoveby(1, 1)
            mousemoveby(-1, -1)
        elseif mousemoverel then
            mousemoverel(1, 1)
            mousemoverel(-1, -1)
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

    -- 1. Coba matikan koneksi default Idled
    if getconnections then
        pcall(function()
            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then
                    conn:Disable()
                    table.insert(disabledConnections, conn)
                elseif conn.Disconnect then
                    conn:Disconnect()
                    table.insert(disabledConnections, conn)
                end
            end
        end)
    end

    -- 2. Hubungkan event Idled milik kita sendiri
    -- Jika getconnections gagal atau tidak lengkap mematikan koneksi CoreScript,
    -- event ini akan terpicu setelah 2 menit idle, lalu kita simulasikan input untuk reset timer.
    pcall(function()
        if idledConnection then
            idledConnection:Disconnect()
            idledConnection = nil
        end
        idledConnection = LocalPlayer.Idled:Connect(function()
            if not running then return end
            simulateInput()
        end)
    end)
end

local function stop()
    running = false
    
    -- Kembalikan koneksi default
    for _, conn in pairs(disabledConnections) do
        pcall(function()
            if type(conn) == "table" or typeof(conn) == "Connection" or type(conn) == "userdata" then
                if conn.Enable then
                    conn:Enable()
                end
            end
        end)
    end
    table.clear(disabledConnections)

    -- Putuskan koneksi Idled kita
    if idledConnection then
        idledConnection:Disconnect()
        idledConnection = nil
    end
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



