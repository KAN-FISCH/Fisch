local Utils = {}

function Utils.DetectExecutor()
    local exec = "Unknown"
    if identifyexecutor then
        exec = identifyexecutor()
    elseif getexecutorname and type(getexecutorname) == "function" then
        exec = getexecutorname()
    elseif syn and syn.executor and type(syn.executor) == "string" then
        exec = syn.executor
    elseif is_sirhurt_closure then
        exec = "SirHurt"
    elseif is_protosmasher_closure then
        exec = "ProtoSmasher"
    elseif KRNL_LOADED then
        exec = "KRNL"
    elseif SENTINEL_LOADED then
        exec = "Sentinel"
    elseif is_synapse_function then
        exec = "Synapse X"
    elseif debug and debug.getregistry then
        for _, v in ipairs(debug.getregistry()) do
            if type(v) == "table" and rawget(v, "luadecomp") then
                exec = "Luna"
            end
        end
    end
    if exec == "NX" or string.find(exec:lower(), "nx") then
        exec = "Luna"
    end
    return exec
end

function Utils.DeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
    end
    return setmetatable(copy, getmetatable(original))
end

function Utils.FormatSeconds(secs)
    local ok, num = pcall(function() return tonumber(secs) end)
    if not ok or not num or num <= 0 then return "Expired" end
    num = math.floor(num)
    local years  = math.floor(num / (365 * 86400))
    local months = math.floor((num % (365 * 86400)) / (30 * 86400))
    local days   = math.floor((num % (30 * 86400)) / 86400)
    local hours  = math.floor((num % 86400) / 3600)
    local mins   = math.floor((num % 3600) / 60)
    if years > 0 then
        if months > 0 then return years .. " Tahun " .. months .. " Bulan" end
        return years .. " Tahun"
    elseif months > 0 then
        return months .. " Bulan " .. days .. " Hari"
    elseif days > 0 then
        return days .. " Hari " .. hours .. " Jam " .. mins .. " Mnt"
    elseif hours > 0 then
        return hours .. " Jam " .. mins .. " Mnt"
    else
        return mins .. " Mnt"
    end
end

return Utils
