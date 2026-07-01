local function Init(ExclusiveSection, AutoMineSection, AutoSaveSection, NPCSection, BallonSection, EspCharacterSection, EspEventSection, EspNpcSection)
                ExclusiveSection:AddSeperator({
                    Title = 'Server Hop Uptime'
                })

                _G.Config.AutoHopUptime = _G.Config.AutoHopUptime or false
                _searchingNotified = false

                local function isServerInTargetWindow(total_mins)
                    if total_mins < 50 then return false end
                    return (total_mins - 50) % 70 < 10
                end

                local function HopToLowUptimeServer()
                    while _G.Config.AutoHopUptime do
                        task.wait(10)
                        local currentUptimeSeconds = workspace.DistributedGameTime
                        local currentMinutes = math.floor(currentUptimeSeconds / 60)

                        if not isServerInTargetWindow(currentMinutes) then
                            if not _searchingNotified then
                                pcall(function()
                                    game.StarterGui:SetCore("SendNotification", {
                                        Title = "Uptime Server Hop",
                                        Text = "Server ini belum mendekati Event. Mencari server dari Webhook...",
                                        Duration = 5
                                    })
                                end)
                                _searchingNotified = true
                            end

                            local HttpService = game:GetService("HttpService")
                            local TeleportService = game:GetService("TeleportService")

                            local success, result = pcall(function()
                                return HttpService:JSONDecode(
                                    game:HttpGet("https://key.shieldteam.asia/api/key/weebhooks")
                                )
                            end)

                            if success and result and result.success and result.rows then
                                local hasTeleported = false
                                for _, row in ipairs(result.rows) do
                                    if not _G.Config.AutoHopUptime then break end
                                    local payload = row.payload
                                    if payload and payload.embeds and payload.embeds[1] and payload.embeds[1].fields then
                                        local fields = payload.embeds[1].fields
                                        local serverDesc = payload.embeds[1].description

                                        local uptimeVal = ""
                                        local playerCount = 0

                                        for _, field in ipairs(fields) do
                                            if field.name == "⏰ Uptime" then
                                                uptimeVal = field.value
                                            elseif field.name == "👥 Players" then
                                                local pStr = string.match(field.value, "%d+")
                                                if pStr then playerCount = tonumber(pStr) end
                                            end
                                        end

                                        local serverId = string.match(serverDesc, "`([%w%-]+)`")

                                        if serverId and serverId ~= game.JobId and playerCount < 20 then
                                            local d, h, m = string.match(uptimeVal, "(%d+)D%s+(%d+)H%s+(%d+)M")
                                            if not d then
                                                d, h, m = 0, 0, string.match(uptimeVal, "(%d+)M")
                                            end

                                            if m then
                                                local hari = tonumber(d) or 0
                                                local jam = tonumber(h) or 0
                                                local menit = tonumber(m) or 0

                                                local total_server_mins = (hari * 24 * 60) + (jam * 60) + menit

                                                if isServerInTargetWindow(total_server_mins) then
                                                    pcall(function()
                                                        game.StarterGui:SetCore("SendNotification", {
                                                            Title = "Uptime Server Hop",
                                                            Text = "Menemukan server pas (" .. tostring(total_server_mins) .. " Menit). Teleporting!",
                                                            Duration = 5
                                                        })
                                                    end)
                                                    hasTeleported = true
                                                    task.wait(1)
                                                    pcall(function()
                                                        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, game.Players.LocalPlayer)
                                                    end)
                                                    task.wait(5)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if hasTeleported then
                                    task.wait(10)
                                end
                            end
                        else
                            if _searchingNotified then
                                pcall(function()
                                    game.StarterGui:SetCore("SendNotification", {
                                        Title = "Uptime Server Hop",
                                        Text = "Siap-siap! Server ini akan segera menjatuhkan Sunken Chest.",
                                        Duration = 5
                                    })
                                end)
                                _searchingNotified = false
                            end
                        end
                    end
                end
                StatusUptimeParagraph = ExclusiveSection:AddParagraph({
                    Title = "Server Uptime Status",
                    Content = "Checking realtime status..."
                })

                ExclusiveSection:AddToggle({
                    Title = "Auto Hop (Sunken Chest Timers)",
                    Description = "Pindah ketika server mendekati menit 60, 130, 200 dst (-10 Mnt)",
                    Default = _G.Config.AutoHopUptime or false,
                    Callback = function(state)
                        _G.Config.AutoHopUptime = state

                        pcall(function()
                            game.StarterGui:SetCore("SendNotification", {
                                Title = "Uptime Server Hop",
                                Text = state and "Auto Hop (Uptime) Diaktifkan!" or "Auto Hop (Uptime) Dimatikan!",
                                Duration = 3
                            })
                        end)

                        if state then
                            task.spawn(HopToLowUptimeServer)
                        end
                    end
                })

                task.spawn(function()
                    while task.wait(1) do
                        pcall(function()
                            local uptimeText = "0D 0H 0M"
                            local foundUptime = false

                            pcall(function()
                                local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("serverInfo")
                                if gui and gui:FindFirstChild("serverInfo") and gui.serverInfo:FindFirstChild("uptime") then
                                    uptimeText = string.gsub(gui.serverInfo.uptime.Text, "Uptime: ", "")
                                    foundUptime = true
                                end
                            end)

                            local currentMinutes = 0
                            if foundUptime then
                                local d = tonumber(string.match(uptimeText, "(%d+)D")) or 0
                                local h = tonumber(string.match(uptimeText, "(%d+)H")) or 0
                                local m = tonumber(string.match(uptimeText, "(%d+)M")) or 0
                                currentMinutes = (d * 1440) + (h * 60) + m
                            else
                                currentMinutes = math.floor(workspace.DistributedGameTime / 60)
                                local d = math.floor(currentMinutes / 1440)
                                local h = math.floor((currentMinutes % 1440) / 60)
                                local m = currentMinutes % 60
                                uptimeText = tostring(d) .. "D " .. tostring(h) .. "H " .. tostring(m) .. "M"
                            end

                            local n = math.floor((currentMinutes + 10) / 70)
                            local nextTarget = 60 + (70 * n)
                            local minsTogo = nextTarget - currentMinutes

                            local tHari = math.floor(nextTarget / 1440)
                            local tJam = math.floor((nextTarget % 1440) / 60)
                            local tMenit = nextTarget % 60
                            local targetUptimeStr = tostring(tHari) .. "D " .. tostring(tJam) .. "H " .. tostring(tMenit) .. "M"

                            local sJam = math.floor(minsTogo / 60)
                            local sMenit = minsTogo % 60
                            local sisaWaktuStr = (sJam > 0 and tostring(sJam) .. "H " or "") .. tostring(sMenit) .. "M"

                            if StatusUptimeParagraph then
                                local contentText = "Uptime Server: " .. uptimeText .. "\nNext Drop Uptime: " .. targetUptimeStr .. " (In: " .. sisaWaktuStr .. ")"

                                if StatusUptimeParagraph.Set then
                                    StatusUptimeParagraph:Set({
                                        Title = "Server Uptime Status",
                                        Content = contentText
                                    })
                                elseif StatusUptimeParagraph.SetDesc then
                                    StatusUptimeParagraph:SetDesc(contentText)
                                end
                            end
                        end)
                    end
                end)
                if _G.Config.AutoHopUptime then
                    autoHopUptimeEnabled = true
                    task.spawn(HopToLowUptimeServer)
                end

                ExclusiveSection:AddSeperator({
                    Title = 'Auto Hop Event'
                })
                ExclusiveSection:AddDropdown({
                    Title = "Select Target Event",
                    Description = "Auto Hop will search for these events",
                    Options = {
                        'Baby Bloop Fish', 
                        'Bloop Fish',
                        'Whales Pool',
                        'Lovestorm', 
                        "Plesiosaur Hunt", "Pliosaur Hunt", "Goldwraith Hunt", "Reef Titan Hunt", "Sunken Reliquary", "Omnithal Hunt",
                        'Orcas Pool',
                        'The Kraken Pool',
                        'Animal Pool',
                        'Animal Pool - Second Sea',
                        'Octophant Pool Without Elephant',
                        'Sea Leviathan Pool',
                        'Isonade',
                        'Forsaken Veil - Scylla',
                        'Blue Moon - Second Sea',
                        'Blue Moon - First Sea',
                        'LEGO',
                        'LEGO - Studolodon',
                        'Mosslurker',
                        'Narwhal',
                        'Whale Shark',
                        'Birthday Megalodon',
                        'Colossal Blue Dragon',
                        'Colossal Ancient Dragon',
                        'Colossal Ethereal Dragon',
                        'MossjawHunt',
                        'BrineStorm',
                        'KrakenHunt',
                        'MegHunt',
                        'MoonlitMirage',
                        'ScyllaHunt',
                        'ReefTitan',
                        'FrostwyrmHunt',
                        'The Sanctum Hunt',
                        'The Sanctum Profane Hunt',
                        'DepthsAbsoluteDarkness',
                        'SkeletalLeviathanHunt',
                        'WyvernHunt',
                        'NectarBloom',
                        'RotbloomHunt',
                        'FlowerGuardianHunt'
                    },
                    Multi = true,
                    Default = _G.Config.AutoHopEvents or {},
                    Callback = function(val)
                        targetHopEvents = val
                        _G.Config.AutoHopEvents = val
                    end
                })

                ExclusiveSection:AddToggle({
                    Title = "Enable Auto Hop",
                    Description = "Will keep hopping until target event is found in server list or current server",
                    Default = _G.Config.AutoHopEnabled or false,
                    Callback = function(state)
                        autoHopEnabled = state
                        _G.Config.AutoHopEnabled = state
                        if state then
                            task.spawn(StartAutoHop)
                        end
                    end
                })

                if _G.Config.AutoHopEnabled then
                    autoHopEnabled = true
                    task.spawn(StartAutoHop)
                end
end
return Init
