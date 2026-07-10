-- AntiAFK.lua - Cegah kick AFK dengan mematikan koneksi Idled
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local running = false
local disabledConnections = {}

local function start()
    if running then return end
    running = true

    -- Metode Utama: Mematikan koneksi event Idled (UNC/getconnections)
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
    else
        warn("[NewFish5] Executor tidak mendukung 'getconnections'. Anti-AFK gagal diaktifkan.")
    end
end

local function stop()
    running = false
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


