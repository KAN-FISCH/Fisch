local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PerfectCatch = {}
setmetatable(PerfectCatch, {
    __call = function(self, value)
        _G.Config.AutoPerfectCatch = value
    end
})
return PerfectCatch