local function init()
    task.spawn(function()
                    TeleportFishingZoneNoFrezeandNoBoat(_G.Config.selectedZone)
                end)
end

return init
