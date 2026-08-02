local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- PerfectCatch sekarang tidak memasang hook sendiri ke controller.StartReel
-- Semua logika Snap + InstantReel + PerfectCatch ditangani di AutoReel.lua
-- Modul ini hanya mengekspos fungsi setter untuk Config flag

local PerfectCatch = {}
setmetatable(PerfectCatch, {
    __call = function(self, value)
        _G.Config.AutoPerfectCatch = value
    end
})
return PerfectCatch
