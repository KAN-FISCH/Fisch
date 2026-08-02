local HttpService = game:GetService("HttpService")
local configFolder = "ExclusiveConfigs/"

local function getConfigs()
    local list = {"Default"}
    if isfolder and isfolder(configFolder) and listfiles then
        for _, file in ipairs(listfiles(configFolder)) do
            local name = file:match("([^/\\%.]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    return list
end

local function saveConfig(name)
    if not isfolder(configFolder) then makefolder(configFolder) end
    writefile(configFolder .. name .. ".json", HttpService:JSONEncode(_G.Config))
end

local function loadConfig(name)
    local path = configFolder .. name .. ".json"
    if isfile(path) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                _G.Config[k] = v
            end
            print("Config loaded:", name)
            return true
        end
    end
    return false
end

local function deleteConfig(name)
    local path = configFolder .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

return {
    GetConfigs = getConfigs,
    SaveConfig = saveConfig,
    LoadConfig = loadConfig,
    DeleteConfig = deleteConfig,
}
