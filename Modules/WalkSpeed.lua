local function init(state)
    task.spawn(function()
                updateSpeed(state)
            end)
end

return init
