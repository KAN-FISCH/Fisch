local function init(value)
    print("[NewFish5] PerfectCatch toggled:", value)
    _G.Config.AutoPerfectCatch = value

    if value then
        if not __var then _G.__var = {} end
        __var.perfectCatchEnabled = 100
        __var.perfectCastEnabled = 100
    else
        if __var then
            __var.perfectCatchEnabled = 0
            __var.perfectCastEnabled = 0
        end
    end
end

return init