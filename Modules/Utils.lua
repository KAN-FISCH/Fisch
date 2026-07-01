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

function Utils.SendWebhook(url, data)
    task.spawn(function()
        pcall(function()
            local payload = game:GetService("HttpService"):JSONEncode(data)
            if request then
                request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
            elseif http_request then
                http_request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
            end
        end)
    end)
end

function Utils.LoadScriptWithCache(url)
    local fileName = "ShieldCache_" .. url:match("([^/]+)$") .. ".lua"

    if isfile and isfile(fileName) and readfile then
        local cachedContent = readfile(fileName)
        if cachedContent and #cachedContent > 0 then
            local func = loadstring(cachedContent)
            if func then
                task.spawn(function()
                    pcall(function()
                        local fresh = game:HttpGet(url, true)
                        if fresh and #fresh > 0 and fresh ~= cachedContent and writefile then
                            writefile(fileName, fresh)
                        end
                    end)
                end)
                return func()
            end
        end
    end

    local freshContent = game:HttpGet(url, true)
    if writefile then
        pcall(function() writefile(fileName, freshContent) end)
    end
    return loadstring(freshContent)()
end

return Utils