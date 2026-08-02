local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local running = false
local AutoQuestShady = {
    StatusCallback    = nil,
    BazaarCallback    = nil,   -- callback update UI bazaar status
    ForceOpenHatch    = nil,   -- dipasang setelah fungsi terdefinisi
    GetBazaarStatus   = nil,   -- dipasang setelah fungsi terdefinisi
}

-- ─────────────────────────────────────────────────────────
-- Koordinat mancing area Shady (Moosewood Bazaar area)
-- ─────────────────────────────────────────────────────────
local SHADY_FISHING_POS     = Vector3.new(-1067.4, 130.8, -1163.3)
local MOOSEWOOD_FISHING_POS = Vector3.new(388, 135, 245)

-- ─────────────────────────────────────────────────────────
-- Threshold koin untuk beli Shady Rod
-- Shady Rod harganya ~4k shady coin (bukan gold coin)
-- Kita detect via getCoins() / shady bazaar currency
-- ─────────────────────────────────────────────────────────
local SHADY_ROD_PRICE   = 4000   -- 4k shady coins
local SUNDIAL_PRICE     = 2000   -- 2k gold untuk sundial totem

local function formatAmount(val)
    if val >= 1000000 then
        local m = val / 1000000
        return (m % 1 == 0 and string.format("%dM", m) or string.format("%.1fM", m))
    elseif val >= 1000 then
        local k = val / 1000
        return (k % 1 == 0 and string.format("%dk", k) or string.format("%.1fk", k))
    end
    return tostring(val)
end

local function getDataController()
    local dc = nil
    pcall(function()
        dc = require(ReplicatedStorage:WaitForChild("client"):WaitForChild("legacyControllers"):WaitForChild("DataController"))
    end)
    if not dc then
        pcall(function()
            dc = require(ReplicatedStorage:WaitForChild("client"):WaitForChild("controllers"):WaitForChild("DataController"))
        end)
    end
    return dc
end

local function getLevel()
    local success, val = pcall(function()
        local stats = workspace:FindFirstChild("PlayerStats")
        local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
        local tFolder = pFolder and pFolder:FindFirstChild("T")
        local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
        local statsSub = subFolder and subFolder:FindFirstChild("Stats")
        local levelObj = statsSub and statsSub:FindFirstChild("level")
        return levelObj and levelObj.Value
    end)
    if success and val then return val end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local levelObj = leaderstats and leaderstats:FindFirstChild("Level")
    return levelObj and levelObj.Value or 0
end

local function getCoins()
    local success, val = pcall(function()
        local stats = workspace:FindFirstChild("PlayerStats")
        local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
        local tFolder = pFolder and pFolder:FindFirstChild("T")
        local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
        local statsSub = subFolder and subFolder:FindFirstChild("Stats")
        local coinsObj = statsSub and statsSub:FindFirstChild("coins")
        return coinsObj and coinsObj.Value
    end)
    if success and val then return val end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cashObj = leaderstats and (leaderstats:FindFirstChild("C$") or leaderstats:FindFirstChild("E$"))
    return cashObj and cashObj.Value or 0
end

-- ─────────────────────────────────────────────────────────
-- Ambil shady coins (mata uang Bazaar, tampil sebagai "S$" di game)
-- Path: PlayerGui.hud.safezone.ShadyCoinGui
-- ─────────────────────────────────────────────────────────
local function getShadyCoins()
    local val = 0

    -- ── 1. Baca dari ShadyCoinGui di HUD (sumber utama) ────
    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pGui and pGui:FindFirstChild("hud")
        local safezone = hud and hud:FindFirstChild("safezone")
        local shadyCoinGui = safezone and safezone:FindFirstChild("ShadyCoinGui")
        if shadyCoinGui then
            -- Cari TextLabel di dalam (bisa langsung atau child)
            local label = shadyCoinGui:IsA("TextLabel") and shadyCoinGui
                or shadyCoinGui:FindFirstChildWhichIsA("TextLabel")
                or shadyCoinGui:FindFirstChildWhichIsA("TextButton")
            local text = label and label.Text or (shadyCoinGui:IsA("TextLabel") and shadyCoinGui.Text)
            if text then
                -- Format: "4,372 S$" → hapus koma, hapus " S$", parse angka
                local cleaned = text:gsub(",", ""):gsub("%s*S%$.*", ""):gsub("[^%d]", "")
                val = tonumber(cleaned) or 0
            end
        end
    end)
    if val > 0 then return val end

    -- ── 2. Cek leaderstats ("S$" atau variasi) ─────────────
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local obj = ls:FindFirstChild("S$")
                or ls:FindFirstChild("sc")
                or ls:FindFirstChild("ShadyCoins")
                or ls:FindFirstChild("Shady")
                or ls:FindFirstChild("Bazaar")
            if obj then
                val = tonumber(obj.Value) or 0
            end
        end
    end)
    if val > 0 then return val end

    -- ── 3. Cek PlayerStats → Stats ──────────────────────────
    pcall(function()
        local stats = workspace:FindFirstChild("PlayerStats")
        local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
        local tFolder = pFolder and pFolder:FindFirstChild("T")
        local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
        local statsSub = subFolder and subFolder:FindFirstChild("Stats")
        if statsSub then
            local obj = statsSub:FindFirstChild("sc")
                or statsSub:FindFirstChild("S$")
                or statsSub:FindFirstChild("shadyCoins")
                or statsSub:FindFirstChild("ShadyCoins")
                or statsSub:FindFirstChild("bazaarCoins")
                or statsSub:FindFirstChild("Bazaar_Coins")
            if obj then
                val = tonumber(obj.Value) or 0
            end
        end
    end)

    return val
end

-- ─────────────────────────────────────────────────────────
-- Helper: set transparansi semua part dalam model
-- (mirror dari ShadyHatchController.setModelTransparency)
-- ─────────────────────────────────────────────────────────
local function setModelTransparency(model, transparency)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = transparency
            if descendant:IsA("BasePart") then
                descendant.CanCollide = (transparency == 0)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────
-- Cek status Bazaar quest via legacyLocalPlayerData
-- (mirror dari ShadyHatchController.Start)
-- ─────────────────────────────────────────────────────────
local function getBazaarQuestStatus()
    local status = {
        FindFiguresDone  = false,
        LighthouseDone   = false,
        BazaarUnlocked   = false,
        -- per-figur
        FoundLantern     = false,
        FoundDiver       = false,
        FoundWatchman    = false,
    }
    -- Cara utama: legacyLocalPlayerData (sama persis dgn controller)
    pcall(function()
        local legacyLocalPlayerData = require(ReplicatedStorage.client.modules.legacyLocalPlayerData)
        local playerData = legacyLocalPlayerData.fetch()
        if not playerData then return end
        local Cache = playerData:FindFirstChild("Cache")
        if not Cache then return end
        local lantern    = Cache:FindFirstChild("Bazaar_FoundLantern")
        local diver      = Cache:FindFirstChild("Bazaar_FoundDiver")
        local watchman   = Cache:FindFirstChild("Bazaar_FoundWatchman")
        local lighthouse = Cache:FindFirstChild("Bazaar_LighthousePassed")
        status.FoundLantern   = lantern   and lantern.Value   == true
        status.FoundDiver     = diver     and diver.Value     == true
        status.FoundWatchman  = watchman  and watchman.Value  == true
        status.FindFiguresDone = status.FoundLantern and status.FoundDiver and status.FoundWatchman
        status.LighthouseDone  = lighthouse and lighthouse.Value == true
    end)
    -- Fallback: workspace PlayerStats/Cache
    if not status.FindFiguresDone and not status.LighthouseDone then
        pcall(function()
            local stats = workspace:FindFirstChild("PlayerStats")
            local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
            local tFolder = pFolder and pFolder:FindFirstChild("T")
            local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
            local cacheFolder = subFolder and subFolder:FindFirstChild("Cache")
            if cacheFolder then
                local lantern    = cacheFolder:FindFirstChild("Bazaar_FoundLantern")
                local diver      = cacheFolder:FindFirstChild("Bazaar_FoundDiver")
                local watchman   = cacheFolder:FindFirstChild("Bazaar_FoundWatchman")
                local lighthouse = cacheFolder:FindFirstChild("Bazaar_LighthousePassed")
                status.FoundLantern   = lantern   and lantern.Value   == true
                status.FoundDiver     = diver     and diver.Value     == true
                status.FoundWatchman  = watchman  and watchman.Value  == true
                status.FindFiguresDone = status.FoundLantern and status.FoundDiver and status.FoundWatchman
                status.LighthouseDone  = lighthouse and lighthouse.Value == true
            end
        end)
    end

    -- Check if we have talked to the guard in this session, or if we have Shady Coins (meaning it's open)
    local gateOpen = (_G.BazaarGuardTalked == true)
    if not gateOpen then
        pcall(function()
            local sCoins = getShadyCoins()
            if sCoins > 0 then
                gateOpen = true
                _G.BazaarGuardTalked = true
            end
        end)
    end

    status.BazaarUnlocked = status.FindFiguresDone and status.LighthouseDone and gateOpen
    return status
end

-- ─────────────────────────────────────────────────────────
-- Helper: interact dengan satu NPC/model via ProximityPrompt
-- ─────────────────────────────────────────────────────────
local function fireProximityOn(model)
    if not model then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Teleport ke dekat model secara aman
    local modelCF = nil
    pcall(function()
        if model:IsA("BasePart") then
            modelCF = model.CFrame
        elseif model:IsA("Model") then
            if model.PrimaryPart then
                modelCF = model.PrimaryPart.CFrame
            else
                local cf, size = model:GetBoundingBox()
                modelCF = cf
            end
        end
    end)

    if modelCF then
        hrp.CFrame = modelCF * CFrame.new(0, 0, 4)  -- 4 studs di depan
        task.wait(1.0)
        -- Point camera to the model so the prompt shows up
        pcall(function()
            local camera = workspace.CurrentCamera
            if camera then
                camera.CFrame = CFrame.new(camera.CFrame.Position, modelCF.Position)
            end
        end)
        task.wait(0.2)
    end

    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            if prompt.Enabled then
                prompt:InputHoldBegin()
                prompt.HoldDuration = 0
                prompt:InputHoldEnd()
            end
        end)
        task.wait(1.0) -- Tunggu dialog inisialisasi di client agar tidak tabrakan/hilang

        -- Dialog interact agar figure-nya terdaftar di-save
        pcall(function()
            local rf = ReplicatedStorage:FindFirstChild("packages")
                and ReplicatedStorage.packages:FindFirstChild("Net")
                and ReplicatedStorage.packages.Net:FindFirstChild("RF/DialogInteract")
            if rf then
                rf:InvokeServer(2, 1)
            end
        end)
        task.wait(1.0)
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────────────
-- Auto temukan 3 figur Shady di Moosewood (malam hari)
-- Pakai CollectionService tag "ShadyFigure" (dari quest data)
-- ─────────────────────────────────────────────────────────
local function autoFindFigures()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origCF = hrp.CFrame
    local oldAutoCast = _G.Config and _G.Config.AutoCast
    if _G.Config then _G.Config.AutoCast = false end
    task.wait(0.3)

    -- Teleport ke Moosewood spot terlebih dahulu agar model NPC dimuat (stream in)
    hrp.CFrame = CFrame.new(MOOSEWOOD_FISHING_POS)
    task.wait(1.5)

    -- Ambil semua model dengan tag ShadyFigure
    local rawFigures = CollectionService:GetTagged("ShadyFigure")
    if #rawFigures == 0 then
        -- Tag tidak ada, coba cari manual di workspace
        pcall(function()
            local world = workspace:FindFirstChild("world")
            local npcs  = world and world:FindFirstChild("npcs")
            if npcs then
                for _, npc in ipairs(npcs:GetChildren()) do
                    local n = npc.Name:lower()
                    if n:find("shady") or n:find("lantern") or n:find("diver") or n:find("watchman") or n:find("figure") or n:find("fisher") or n:find("bobber") then
                        rawFigures[#rawFigures + 1] = npc
                    end
                end
            end
        end)
    end

    -- Saring hanya figur yang aktif: memiliki ProximityPrompt dan berada di ketinggian wajar (Y < 220)
    local figures = {}
    for _, npc in ipairs(rawFigures) do
        local hasPrompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        local cf = nil
        pcall(function()
            cf = npc:IsA("BasePart") and npc.CFrame
                or (npc.PrimaryPart and npc.PrimaryPart.CFrame)
                or cf
        end)
        if hasPrompt and cf then
            local y = cf.Position.Y
            -- Moosewood docks Y adalah ~135, kita batasi Y antara 100 s/d 220
            if y > 100 and y < 220 then
                table.insert(figures, npc)
            end
        end
    end

    if #figures == 0 then
        -- Belum spawn (mungkin siang) — tidak ada yang dilakukan
        if _G.Config then _G.Config.AutoCast = oldAutoCast end
        return false
    end

    -- Re-cek status per figur sebelum jalan
    local bs = getBazaarQuestStatus()

    for _, figure in ipairs(figures) do
        -- Skip figur yang sudah ditemukan berdasarkan nama
        local figName = figure.Name:lower()
        local skip = false
        if (figName:find("fisher") or figName:find("lantern")) and bs.FoundLantern then
            skip = true
        elseif (figName:find("bobber") or figName:find("diver")) and bs.FoundDiver then
            skip = true
        elseif figName:find("watchman") and bs.FoundWatchman then
            skip = true
        end

        if not skip then
            fireProximityOn(figure)
            -- Update status setelah interact
            bs = getBazaarQuestStatus()
            if bs.FindFiguresDone then break end
        end
    end

    -- Kalau masih belum semua, coba interact semua figur yang ada
    if not getBazaarQuestStatus().FindFiguresDone then
        for _, figure in ipairs(figures) do
            fireProximityOn(figure)
            task.wait(0.5)
        end
    end

    hrp.CFrame = origCF
    task.wait(0.5)
    if _G.Config then _G.Config.AutoCast = oldAutoCast end
    return getBazaarQuestStatus().FindFiguresDone
end

-- ─────────────────────────────────────────────────────────
-- Force-open hatch client-side
-- (mirror persis dari ShadyHatchController.openHatch)
-- ─────────────────────────────────────────────────────────
local function forceOpenHatch()
    -- Ambil model bertag "LighthouseHatch" (sama persis dgn controller)
    local hatchModel = CollectionService:GetTagged("LighthouseHatch")[1]
    if hatchModel then
        local ShadyHatch     = hatchModel:FindFirstChild("ShadyHatch")
        local ShadyHatchOpen = hatchModel:FindFirstChild("ShadyHatchOpen")
        if ShadyHatch and ShadyHatchOpen then
            setModelTransparency(ShadyHatch, 1)     -- sembunyikan hatch tertutup
            setModelTransparency(ShadyHatchOpen, 0) -- tampilkan hatch terbuka
            return true
        end
    end
    return false
end

-- ─────────────────────────────────────────────────────────
-- Teleport ke titik mancing shady
-- ─────────────────────────────────────────────────────────
local function teleportToShadyFishingSpot()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if (hrp.Position - SHADY_FISHING_POS).Magnitude > 15 then
        hrp.CFrame = CFrame.new(SHADY_FISHING_POS)
        task.wait(0.8)
    end
end

local function teleportToMoosewoodFishingSpot()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if (hrp.Position - SHADY_FISHING_POS).Magnitude > 15 then
        hrp.CFrame = CFrame.new(SHADY_FISHING_POS)
        task.wait(0.8)
    end
end

-- ─────────────────────────────────────────────────────────
-- Open Bazaar: force-open hatch + fallback FireServer
-- ─────────────────────────────────────────────────────────
local function tryOpenBazaar()
    -- 1. Force-open hatch client-side (visual) seperti ShadyHatchController
    local hatchOpened = forceOpenHatch()

    -- 2. Jika bazaar_LighthousePassed sudah true, listener sudah handle — done
    if hatchOpened then return end

    -- 3. Fallback: coba FireServer event jika ada
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        if events then
            local openBazaar = events:FindFirstChild("openBazaar")
                or events:FindFirstChild("OpenBazaar")
                or events:FindFirstChild("bazaarOpen")
            if openBazaar then
                openBazaar:FireServer()
                return
            end
        end
        -- via packages/Net
        local Net = ReplicatedStorage:FindFirstChild("packages") and ReplicatedStorage.packages:FindFirstChild("Net")
        if Net then
            local rf = Net:FindFirstChild("RF/OpenBazaar") or Net:FindFirstChild("RE/OpenBazaar")
            if rf then
                if rf:IsA("RemoteFunction") then rf:InvokeServer()
                else rf:FireServer() end
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────
-- Interaksi NPC / proximity prompt Bazaar
-- ─────────────────────────────────────────────────────────
local function interactBazaarNPC()
    -- Todd (accept indicator) & Shady Lighthouse Figure
    local npcNames = {"Todd", "ShadyLighthouseFigure", "ShadyFigure", "Shady Figure", "Lighthouse Figure"}
    for _, npcName in ipairs(npcNames) do
        pcall(function()
            local npc = workspace:FindFirstChild(npcName, true)
            if npc then
                local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    pcall(function()
                        prompt:InputHoldBegin()
                        prompt.HoldDuration = 0
                        prompt:InputHoldEnd()
                    end)
                    task.wait(0.5)
                end
            end
        end)
    end
end

local function hasSundialTotem()
    if LocalPlayer.Backpack:FindFirstChild("Sundial Totem") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Sundial Totem")) then
        return true
    end
    
    local inventory = nil
    local DataController = getDataController()
    if DataController then
        pcall(function()
            if DataController.InventoryReplicator then
                inventory = DataController.InventoryReplicator:Index({"Inventory"})
            else
                inventory = DataController.fetch("Inventory")
            end
        end)
    end
    
    if inventory then
        for _, itemData in pairs(inventory) do
            if type(itemData) == "table" and itemData.name == "Sundial Totem" then
                return true
            end
        end
    end
    return false
end

local function ownsRod(rodName)
    local cleanName = rodName:gsub("%s*Rod%s*$", "") -- "Fortune Rod" -> "Fortune"
    local nameWithRod = cleanName .. " Rod"          -- "Fortune" -> "Fortune Rod"

    -- 1. Check via PlayerGui Equipment list (highly reliable client-side state)
    local successGui, owned = pcall(function()
        local scroll = LocalPlayer.PlayerGui.hud.safezone.equipment.rods.scroll.safezone
        return scroll:FindFirstChild(cleanName) ~= nil or scroll:FindFirstChild(nameWithRod) ~= nil
    end)
    if successGui and owned then return true end

    -- 2. Check via active rod Stats value
    local success, equipped = pcall(function()
        local current = workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
        return current == cleanName or current == nameWithRod
    end)
    if success and equipped then return true end
    
    -- 3. Check via Backpack / Character
    if LocalPlayer.Backpack:FindFirstChild(cleanName) or LocalPlayer.Backpack:FindFirstChild(nameWithRod) then
        return true
    end
    if LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild(cleanName) or LocalPlayer.Character:FindFirstChild(nameWithRod)) then
        return true
    end
    
    -- 4. Check via DataController inventory
    local inventory = nil
    local DataController = getDataController()
    if DataController then
        pcall(function()
            if DataController.InventoryReplicator then
                inventory = DataController.InventoryReplicator:Index({"Inventory"})
            else
                inventory = DataController.fetch("Inventory")
            end
        end)
    end
    if inventory then
        for _, itemData in pairs(inventory) do
            if type(itemData) == "table" and (itemData.name == cleanName or itemData.name == nameWithRod) then
                return true
            end
        end
    end
    return false
end

local function ownsShadyRod()
    return ownsRod("Shady Rod")
end

local function buyRodByName(rodName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origCF = hrp.CFrame
    local oldAutoCast = _G.Config.AutoCast
    _G.Config.AutoCast = false
    task.wait(0.2)

    -- If buying Fortune Rod, teleport to the shop coordinate first
    if rodName == "Fortune Rod" then
        hrp.CFrame = CFrame.new(-1508, 141, 750)
        task.wait(1.5)
    end

    local events = ReplicatedStorage:FindFirstChild("events")
    local purchase = events and events:FindFirstChild("purchase")
    if purchase then
        pcall(function()
            purchase:FireServer(rodName, "Rod", nil, 1)
        end)
    end
    task.wait(1.5)

    hrp.CFrame = origCF
    task.wait(0.5)
    _G.Config.AutoCast = oldAutoCast
end

local function equipRodByName(rodName)
    local cleanName = rodName:gsub("%s*Rod%s*$", "")
    local nameWithRod = cleanName .. " Rod"

    pcall(function()
        local equipRF = ReplicatedStorage:WaitForChild("packages")
            and ReplicatedStorage.packages:WaitForChild("Net")
            and ReplicatedStorage.packages.Net:FindFirstChild("RF/Rod/Equip")
        if equipRF then
            local success = equipRF:InvokeServer(nameWithRod)
            if not success then
                equipRF:InvokeServer(cleanName)
            end
        end
    end)
    task.wait(0.2)
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local rod = (backpack and (backpack:FindFirstChild(cleanName) or backpack:FindFirstChild(nameWithRod))) or (char and (char:FindFirstChild(cleanName) or char:FindFirstChild(nameWithRod)))
    if rod then
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- Perform unequip/equip cycle to force instant bobber initialization
            pcall(function()
                hum:UnequipTools()
            end)
            task.wait(0.3)
            pcall(function()
                hum:EquipTool(rod)
            end)
            task.wait(0.3)
            pcall(function()
                hum:UnequipTools()
            end)
            task.wait(0.3)
            pcall(function()
                hum:EquipTool(rod)
            end)
        end
    end
end

local function buySundialTotem()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local origCF = hrp.CFrame
    local oldAutoCast = _G.Config.AutoCast
    _G.Config.AutoCast = false
    task.wait(0.2)
    
    hrp.CFrame = CFrame.new(-1215, 195.3, -1040)
    task.wait(1.5)
    
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        local purchase = events and events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer("Sundial Totem", "Item", nil, 1)
        end
    end)
    task.wait(1.0)
    
    hrp.CFrame = origCF
    task.wait(0.5)
    _G.Config.AutoCast = oldAutoCast
end

local function useSundialTotem()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local totem = LocalPlayer.Backpack:FindFirstChild("Sundial Totem")
    if not totem then return end
    
    local oldAutoCast = _G.Config.AutoCast
    _G.Config.AutoCast = false
    task.wait(0.2)
    
    totem.Parent = char
    task.wait(0.5)
    
    pcall(function()
        totem:Activate()
    end)
    task.wait(4.0)
    
    if totem.Parent == char then
        totem.Parent = LocalPlayer.Backpack
    end
    
    _G.Config.AutoCast = oldAutoCast
end

-- ─────────────────────────────────────────────────────────
-- Beli Shady Rod via Bazaar (4k shady coins)
-- ─────────────────────────────────────────────────────────
local function buyShadyRodBazaar()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origCF = hrp.CFrame
    local oldAutoCast = _G.Config.AutoCast
    _G.Config.AutoCast = false
    task.wait(0.2)

    -- Teleport ke area bazaar (bawah lighthouse Moosewood)
    hrp.CFrame = CFrame.new(-1067.4, 130.8, -1163.3)
    task.wait(1.5)

    -- Coba beli lewat event purchase dengan currency ShadyCoins
    local bought = false
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("events")
        local purchase = events and events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer("Shady Rod", "Rod", "ShadyCoins", 1)
            bought = true
        end
    end)

    if not bought then
        -- Fallback: direct purchase tanpa currency hint
        pcall(function()
            local purchase = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("purchase")
            if purchase then
                purchase:FireServer("Shady Rod", "Rod", nil, 1)
            end
        end)
    end

    task.wait(1.5)
    hrp.CFrame = origCF
    task.wait(0.5)
    _G.Config.AutoCast = oldAutoCast
end

-- ─────────────────────────────────────────────────────────
-- Beli Shady Rod via Shady Merchant (lama, fallback)
-- ─────────────────────────────────────────────────────────
local function buyShadyRod()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local origCF = hrp.CFrame
    local oldAutoCast = _G.Config.AutoCast
    _G.Config.AutoCast = false
    task.wait(0.2)
    
    hrp.CFrame = CFrame.new(-2997, -1023, 6067)
    task.wait(1.5)
    
    pcall(function()
        local shadyMerchant = workspace:FindFirstChild("world")
            and workspace.world:FindFirstChild("npcs")
            and (workspace.world.npcs:FindFirstChild("Shady Merchant") or workspace:FindFirstChild("Shady Merchant"))
        if not shadyMerchant then
            shadyMerchant = workspace:FindFirstChild("Shady Merchant")
        end
        if shadyMerchant then
            local prompt = shadyMerchant:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                pcall(function()
                    prompt:InputHoldBegin()
                    prompt.HoldDuration = 0
                    prompt:InputHoldEnd()
                end)
            end
        end
    end)
    task.wait(0.5)
    
    pcall(function()
        local dialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
        if dialogInteract then
            dialogInteract:InvokeServer(1, 1)
        end
    end)
    task.wait(0.2)
    
    pcall(function()
        local purchase = ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("purchase")
        if purchase then
            purchase:FireServer("Shady Rod", "Rod", nil, 1)
        end
    end)
    task.wait(1.5)
    
    hrp.CFrame = origCF
    task.wait(0.5)
    _G.Config.AutoCast = oldAutoCast
end

-- ─────────────────────────────────────────────────────────
-- Update status UI
-- ─────────────────────────────────────────────────────────
local function updateStatusUI(currentActionText)
    if not AutoQuestShady.StatusCallback then return end
    
    pcall(function()
        local lvl = getLevel()
        local coins = getCoins()
        local shadyCoins = getShadyCoins()
        local hasTotem = hasSundialTotem()
        local bazaarStatus = getBazaarQuestStatus()
        
        local isDay = false
        pcall(function()
            isDay = (ReplicatedStorage.world.cycle.Value == "Day")
        end)
        
        local reqCoins = hasTotem and 150000 or 152000
        
        local bazaarStr = ""
        if bazaarStatus.BazaarUnlocked then
            bazaarStr = "Terbuka ✓"
        elseif bazaarStatus.FindFiguresDone then
            bazaarStr = "Quest 1 ✓ | Quest 2 ✗"
        else
            bazaarStr = "Belum terbuka"
        end

        local statusString = string.format(
            "• Level: %d/50 [%s]\n" ..
            "• Gold Coins: %s/%s [%s]\n" ..
            "• Shady Coins: %s/%s [%s]\n" ..
            "• Totem Sundial: %s\n" ..
            "• Bazaar: %s\n" ..
            "• Waktu: %s\n\n" ..
            "Status: %s",
            lvl, lvl >= 50 and "OK" or "BELUM",
            formatAmount(coins), formatAmount(reqCoins), coins >= reqCoins and "OK" or "BELUM",
            formatAmount(shadyCoins), formatAmount(SHADY_ROD_PRICE), shadyCoins >= SHADY_ROD_PRICE and "OK" or "BELUM",
            hasTotem and "Ada" or "Tidak Ada (Butuh 2k C$)",
            bazaarStr,
            isDay and "Siang" or "Malam",
            currentActionText or "Checking..."
        )
        
        AutoQuestShady.StatusCallback(statusString)
    end)
end

-- ─────────────────────────────────────────────────────────
-- Paksa fishing di koordinat shady
-- ─────────────────────────────────────────────────────────
local function setFishingAtShadySpot()
    if _G.Config then
        _G.Config.AutoCast         = true
        _G.Config.AutoReel         = true
        _G.Config.InstantReel      = true
        _G.Config.InstantCast      = true
        _G.Config.AutoShake        = true
        _G.Config.AutoPerfectCatch = true
        _G.Config.AutoSell         = true
        _G.Config.isEquipRpd       = true
        
        -- Override TeleportArea / fishing spot ke koordinat shady
        if _G.Config.FishingPosition ~= nil then
            _G.Config.FishingPosition = SHADY_FISHING_POS
        end
        -- Kalau pakai override position
        if _G.Config.OverridePosition ~= nil then
            _G.Config.OverridePosition = SHADY_FISHING_POS
        end
        -- Set custom cast position
        if _G.Config.CastPosition ~= nil then
            _G.Config.CastPosition = SHADY_FISHING_POS
        end
    end
    -- Teleport ke spot
    teleportToShadyFishingSpot()
end

local function getMod(name)
    if _G.getMod then return _G.getMod(name) end
    local core = game:GetService("ReplicatedStorage"):FindFirstChild("Shield_Core")
    if core then
        local folder = core:FindFirstChild(name)
        if folder then
            local src = ""
            if folder:IsA("Folder") then
                for i = 1, #folder:GetChildren() do
                    local chunk = folder:FindFirstChild(tostring(i))
                    if chunk then src = src .. chunk.Value end
                end
            else
                src = folder.Value
            end
            local fn, err = loadstring(src)
            if not fn then return nil end
            local success, res = pcall(fn)
            if not success then return nil end
            return res
        end
    end
    return nil
end

local function setFishingAtMoosewood()
    if _G.Config then
        _G.Config.AutoCast         = true
        _G.Config.AutoReel         = true
        _G.Config.InstantReel      = true
        _G.Config.InstantCast      = true
        _G.Config.AutoShake        = true
        _G.Config.AutoPerfectCatch = true
        _G.Config.AutoSell         = true
        _G.Config.isEquipRpd       = true
        
        pcall(function()
            local autoSellMod = getMod("AutoSell")
            if autoSellMod then
                task.spawn(function()
                    autoSellMod.AutoSell()
                end)
            end
        end)
        
        pcall(function()
            local miscFishing = getMod("MiscFishing")
            if miscFishing then
                task.spawn(function()
                    miscFishing.AutoEquipRod(true)
                end)
            end
        end)
        
        -- Override TeleportArea / fishing spot ke koordinat Moosewood
        if _G.Config.FishingPosition ~= nil then
            _G.Config.FishingPosition = MOOSEWOOD_FISHING_POS
        end
        -- Kalau pakai override position
        if _G.Config.OverridePosition ~= nil then
            _G.Config.OverridePosition = MOOSEWOOD_FISHING_POS
        end
        -- Set custom cast position
        if _G.Config.CastPosition ~= nil then
            _G.Config.CastPosition = MOOSEWOOD_FISHING_POS
        end
    end
    
    -- Tunggu sebentar agar thread AutoSell yang di-spawn sempat mengatur flag
    task.wait(0.1)
    if _G.AutoSellTeleporting then
        return
    end

    -- Teleport ke spot Moosewood
    teleportToMoosewoodFishingSpot()
end

-- ─────────────────────────────────────────────────────────
-- Quest Helper Functions
-- ─────────────────────────────────────────────────────────
local function findNPC(name)
    local world = workspace:FindFirstChild("world")
    local npcs = world and world:FindFirstChild("npcs")
    if npcs then
        local npc = npcs:FindFirstChild(name)
        if npc then return npc end
    end
    return workspace:FindFirstChild(name, true)
end

local function teleportToNPC(npcName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local npc = nil
    if npcName == "Todd" then
        hrp.CFrame = CFrame.new(499, 159, 218)
        task.wait(1.0)
        npc = findNPC("Todd")
    else
        npc = findNPC(npcName)
    end
    if not npc then return nil end
    
    local npcCF = nil
    if npc:IsA("BasePart") then
        npcCF = npc.CFrame
    elseif npc:IsA("Model") then
        npcCF = npc:GetPivot()
    end
    
    if npcCF then
        if npcName ~= "Todd" then
            hrp.CFrame = npcCF * CFrame.new(0, 0, 3)
        end
        task.wait(1.0)
        -- Point camera to the NPC so prompt becomes visible
        pcall(function()
            local camera = workspace.CurrentCamera
            if camera then
                camera.CFrame = CFrame.new(camera.CFrame.Position, npcCF.Position)
            end
        end)
        task.wait(0.2)
    end
    return npc
end

local function isQuestActive()
    local success, val = pcall(function()
        local stats = workspace:FindFirstChild("PlayerStats")
        local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
        local tFolder = pFolder and pFolder:FindFirstChild("T")
        local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
        local questActive = subFolder and subFolder:FindFirstChild("QuestActive")
        return questActive and questActive:FindFirstChild("Bazaar_FindFigures") ~= nil
    end)
    return success and val
end

local function startToddQuest()
    local npc = teleportToNPC("Todd")
    if not npc then return false end
    
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            prompt:InputHoldBegin()
            prompt.HoldDuration = 0
            prompt:InputHoldEnd()
        end)
        task.wait(1.0)
        
        pcall(function()
            local Event = game:GetService("ReplicatedStorage").packages.Net["RF/DialogInteract"]
            local Result = table.pack(Event:InvokeServer(
                5,
                1
            ))

            local ExpectedResult = table.unpack({
                "figures_accept"
            })
        end)
        return true
    end
    return false
end

local function handInToddQuest()
    local npc = teleportToNPC("Todd")
    if not npc then return false end
    
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            prompt:InputHoldBegin()
            prompt.HoldDuration = 0
            prompt:InputHoldEnd()
        end)
        task.wait(1.0)
        
        local dialogInteract = ReplicatedStorage:FindFirstChild("packages")
            and ReplicatedStorage.packages:FindFirstChild("Net")
            and ReplicatedStorage.packages.Net:FindFirstChild("RF/DialogInteract")
        if dialogInteract then
            pcall(function() dialogInteract:InvokeServer(1, 7) end)
            task.wait(0.5)
            pcall(function() dialogInteract:InvokeServer(1, 8) end)
            task.wait(0.5)
        end
        return true
    end
    return false
end

local function talkToNPC(npcName, optionIndex)
    local npc = teleportToNPC(npcName)
    if not npc then return false end
    
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            prompt:InputHoldBegin()
            prompt.HoldDuration = 0
            prompt:InputHoldEnd()
        end)
        task.wait(1.0)
        
        local chosenOption = optionIndex
        if npcName == "Todd" then
            chosenOption = 5
        end
        
        if chosenOption then
            pcall(function()
                local dialogInteract = ReplicatedStorage:FindFirstChild("packages")
                    and ReplicatedStorage.packages:FindFirstChild("Net")
                    and ReplicatedStorage.packages.Net:FindFirstChild("RF/DialogInteract")
                if dialogInteract then
                    dialogInteract:InvokeServer(chosenOption, 1)
                end
            end)
            task.wait(0.5)
        end
        return true
    end
    return false
end

local function findFigureNPC(type)
    -- 1. Cari dari tagged ShadyFigure
    local rawFigures = game:GetService("CollectionService"):GetTagged("ShadyFigure")
    for _, npc in ipairs(rawFigures) do
        local name = npc.Name:lower()
        if type == "Fisher" and (name == "lantern figure" or name == "fisher") then
            return npc
        elseif type == "Diver" and (name == "diver" or name == "diver figure") then
            return npc
        elseif type == "Watchman" and (name == "watchman" or name == "watchman figure") then
            return npc
        end
    end
    
    -- 2. Cari dari world npcs
    local world = workspace:FindFirstChild("world")
    local npcs = world and world:FindFirstChild("npcs")
    if npcs then
        for _, npc in ipairs(npcs:GetChildren()) do
            local name = npc.Name:lower()
            if type == "Fisher" and (name == "lantern figure" or name == "fisher") then
                return npc
            elseif type == "Diver" and (name == "diver" or name == "diver figure") then
                return npc
            elseif type == "Watchman" and (name == "watchman" or name == "watchman figure") then
                return npc
            end
        end
    end
    
    -- 3. Cari dari workspace root (hanya Model)
    for _, npc in ipairs(workspace:GetChildren()) do
        if npc:IsA("Model") then
            local name = npc.Name:lower()
            if type == "Fisher" and (name == "lantern figure" or name == "fisher") then
                return npc
            elseif type == "Diver" and (name == "diver" or name == "diver figure") then
                return npc
            elseif type == "Watchman" and (name == "watchman" or name == "watchman figure") then
                return npc
            end
        end
    end
    
    return nil
end

local function equipQuestItem(name)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local item = backpack:FindFirstChild(name)
        if item and item:FindFirstChild("link") then
            pcall(function()
                local equipRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Backpack/Equip")
                if equipRemote then
                    equipRemote:FireServer(item.link.Value)
                end
            end)
            task.wait(0.2)
        end
    end
end

local function forceEquipTool(name)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if hum and backpack then
        local tool = backpack:FindFirstChild(name)
        if tool then
            hum:EquipTool(tool)
            task.wait(0.2)
        end
    end
end

local function solveLighthouseRiddle()
    local npcNames = {"..?", "Some Shady Guy", "ShadyLighthouseFigure", "Lighthouse Figure"}
    local npc = nil
    for _, name in ipairs(npcNames) do
        npc = workspace:FindFirstChild(name, true)
        if npc then break end
    end
    if not npc then return false end
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = npc:GetPivot() * CFrame.new(0, 0, 3)
    task.wait(1.0)
    -- Point camera to the lighthouse guy so the prompt shows up
    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CFrame = CFrame.new(camera.CFrame.Position, npc:GetPivot().Position)
        end
    end)
    task.wait(0.2)
    
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            prompt:InputHoldBegin()
            prompt.HoldDuration = 0
            prompt:InputHoldEnd()
        end)
        task.wait(1.5)
        
        pcall(function()
            local Event = game:GetService("ReplicatedStorage").packages.Net["RF/DialogInteract"]
            local Result = table.pack(Event:InvokeServer(
                7,
                1
            ))

            local ExpectedResult = table.unpack({
                "challenge_done"
            })
        end)
        task.wait(1.0)
        return true
    end
    return false
end

local function talkToBazaarGuard()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Teleport directly to the Bazaar Guard coordinates
    hrp.CFrame = CFrame.new(686, 139, 321)
    task.wait(1.5) -- Wait for streaming
    
    local npcNames = {"Bazaar Guard", "Bazaar guard", "Guard"}
    local npc = nil
    for _, name in ipairs(npcNames) do
        npc = workspace:FindFirstChild(name, true)
        if npc then break end
    end
    if not npc then 
        _G.BazaarGuardTalked = true -- Set true if guard not found at location to prevent stuck loops
        return false 
    end

    -- Point camera to the guard so the prompt shows up
    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CFrame = CFrame.new(camera.CFrame.Position, npc:GetPivot().Position)
        end
    end)
    task.wait(0.2)
    
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        pcall(function()
            prompt:InputHoldBegin()
            prompt.HoldDuration = 0
            prompt:InputHoldEnd()
        end)
        task.wait(1.0)
        
        pcall(function()
            local Event = game:GetService("ReplicatedStorage").packages.Net["RF/DialogInteract"]
            Event:InvokeServer(1, 1)
        end)
        task.wait(1.0)
        _G.BazaarGuardTalked = true
        return true
    else
        -- If prompt is not enabled or not found, it means the guard is already talked to/unlocked
        _G.BazaarGuardTalked = true
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────────────
-- Main loop
-- ─────────────────────────────────────────────────────────
local function AutoQuestShadyLoop()
    if running then return end
    running = true
    
    task.spawn(function()
        while _G.Config and _G.Config.AutoQuestShady do
            task.wait(1.0)
            pcall(function()
                if _G.AutoSellTeleporting then
                    updateStatusUI("Menunggu AutoSell menduplikasi Merchant...")
                    return
                end

                if ownsShadyRod() then
                    updateStatusUI("Sudah memiliki Shady Rod! ✓")
                    _G.Config.AutoQuestShady = false
                    return
                end

                -- Auto buy and equip Fortune Rod when gold coins >= 11000
                if getCoins() >= 11000 and not ownsRod("Fortune Rod") then
                    updateStatusUI("Membeli Fortune Rod...")
                    buyRodByName("Fortune Rod")
                    task.wait(1.5)
                end

                if ownsRod("Fortune Rod") then
                    local currentRod = ""
                    pcall(function()
                        currentRod = workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name].Stats.rod.Value
                    end)
                    if currentRod ~= "Fortune Rod" and currentRod ~= "Shady Rod" then
                        updateStatusUI("Meng-equip Fortune Rod...")
                        equipRodByName("Fortune Rod")
                        task.wait(1.0)
                    end
                end

                local lvl      = getLevel()
                local coins    = getCoins()
                local shadyCoins = getShadyCoins()
                local hasTotem = hasSundialTotem()
                local bazaarStatus = getBazaarQuestStatus()

                -- ── FASE 1: Selesaikan Questline ─────────
                if not bazaarStatus.BazaarUnlocked then
                    local stats = getBazaarQuestStatus()
                    local foundAllFigures = stats.FoundLantern and stats.FoundDiver and stats.FoundWatchman

                    if not foundAllFigures then
                        -- Quest belum dimulai atau item belum lengkap -> ajak bicara Todd dulu jika belum aktif
                        if not isQuestActive() then
                            updateStatusUI("Memulai quest: Bicara dengan NPC Todd...")
                            startToddQuest()
                            task.wait(2.0)
                            return
                        end

                        -- Cek siang/malam
                        local isDay = false
                        pcall(function()
                            isDay = (ReplicatedStorage.world.cycle.Value == "Day")
                        end)

                        if isDay then
                            if hasSundialTotem() then
                                updateStatusUI("Siang -> Mengaktifkan Sundial Totem untuk malam...")
                                useSundialTotem()
                                task.wait(3.0)
                                return
                            else
                                updateStatusUI("Siang: Menunggu malam tiba untuk mencari figur...")
                                task.wait(2.0)
                                return
                            end
                        end

                        -- Malam hari -> cari figur yang belum didapatkan (non-sekuensial)
                        updateStatusUI("Mencari figur quest malam...")
                        
                        -- Cari siapa saja yang spawn terlebih dahulu dan belum diketemukan
                        local figFisher = findFigureNPC("Fisher")
                        local figDiver = findFigureNPC("Diver")
                        local figWatchman = findFigureNPC("Watchman")
                        
                        if figFisher and not stats.FoundLantern then
                            updateStatusUI("Menemukan Fisher! Mendekat...")
                            fireProximityOn(figFisher)
                            task.wait(2.0)
                            return
                        elseif figDiver and not stats.FoundDiver then
                            updateStatusUI("Menemukan Diver! Mendekat...")
                            fireProximityOn(figDiver)
                            task.wait(2.0)
                            return
                        elseif figWatchman and not stats.FoundWatchman then
                            updateStatusUI("Menemukan Watchman! Mendekat...")
                            fireProximityOn(figWatchman)
                            task.wait(2.0)
                            return
                        end
                        return
                    else
                        -- Sudah menemukan semua figur
                        if isQuestActive() then
                            -- Quest Bazaar_FindFigures masih aktif -> lakukan serah-terima ke Todd
                            updateStatusUI("Menemukan semua figur! Meng-equip item...")
                            pcall(function()
                                local net = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
                                net["RF/Lanterns/SetEquipped"]:InvokeServer("Tarnished Lantern")
                                task.wait(0.2)
                                net["RF/AccessoryService/ToggleAccessory"]:InvokeServer("Crow Feather Charm")
                                task.wait(0.2)
                                net["RE/Bobber/Equip"]:FireServer("Barnacled Hook")
                            end)
                            task.wait(1.5)

                            updateStatusUI("Bicara dengan NPC Todd setelah equip item...")
                            handInToddQuest()
                            task.wait(2.0)
                            return
                        end

                        -- Solve riddle mercusuar
                        if not bazaarStatus.LighthouseDone then
                            updateStatusUI("Menuju mercusuar untuk memecahkan riddle...")
                            solveLighthouseRiddle()
                            task.wait(2.0)
                            return
                        end

                        -- Cek level 50 dan koin sebelum Bazaar Guard
                        local reqCoins = hasTotem and 150000 or 152000
                        if lvl < 50 or coins < reqCoins then
                            updateStatusUI(string.format("Leveling/Farming di Moosewood (%d/50, %d/%d C$)...", lvl, coins, reqCoins))
                            setFishingAtMoosewood()
                            return
                        end

                        -- Talk ke Bazaar Guard
                        updateStatusUI("Bicara ke Bazaar Guard...")
                        talkToBazaarGuard()
                        task.wait(2.0)
                        return
                    end
                end

                -- Jika LighthouseDone sudah true tetapi Bazaar belum sepenuhnya terbuka
                if bazaarStatus.LighthouseDone and not bazaarStatus.BazaarUnlocked then
                    local reqCoins = hasTotem and 150000 or 152000
                    if lvl < 50 or coins < reqCoins then
                        updateStatusUI(string.format("Leveling/Farming di Moosewood (%d/50, %d/%d C$)...", lvl, coins, reqCoins))
                        setFishingAtMoosewood()
                        return
                    end

                    updateStatusUI("Bicara ke Bazaar Guard...")
                    talkToBazaarGuard()
                    task.wait(2.0)
                    return
                end

                -- ── FASE 2: Beli Shady Rod jika sudah terbuka dan cukup koin ─
                if shadyCoins >= SHADY_ROD_PRICE then
                    updateStatusUI("Membeli Shady Rod di Bazaar...")
                    buyShadyRodBazaar()
                    task.wait(2.0)
                    if ownsShadyRod() then
                        updateStatusUI("Sukses memiliki Shady Rod! ✓")
                        _G.Config.AutoQuestShady = false
                    end
                    return
                end

                -- ── FASE 3: Koin tidak cukup -> farming shady coins ────────────
                -- Shady Coins farming disabled by user request -> Just farm level & S$ at Moosewood
                local reqCoins = hasTotem and 150000 or 152000
                updateStatusUI(string.format("Leveling/Farming di Moosewood (%d/50, %d/%d C$)...", lvl, coins, reqCoins))
                setFishingAtMoosewood()
                _G.Config.AutoCast         = true
                _G.Config.AutoReel         = true
                _G.Config.InstantReel      = true
                _G.Config.InstantCast      = true
                _G.Config.AutoShake        = true
                _G.Config.AutoPerfectCatch = true
                _G.Config.AutoSell         = true
            end)
        end
        running = false
    end)
end

-- Wire up public API setelah semua fungsi terdefinisi
AutoQuestShady.ForceOpenHatch  = forceOpenHatch
AutoQuestShady.GetBazaarStatus = getBazaarQuestStatus
AutoQuestShady.RefreshStatus   = function(msg)
    updateStatusUI(msg or "Siap (aktifkan toggle untuk mulai)")
end

-- Debug: print semua kemungkinan path untuk S$ shady coins
AutoQuestShady.DebugShadyCoins = function()
    print("=== DEBUG SHADY COINS ===")
    -- Leaderstats
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            print("[leaderstats]", v.Name, "=", v.Value)
        end
    end
    -- PlayerStats Stats
    pcall(function()
        local sub = workspace.PlayerStats[LocalPlayer.Name].T[LocalPlayer.Name]
        local statsSub = sub:FindFirstChild("Stats")
        if statsSub then
            for _, v in ipairs(statsSub:GetChildren()) do
                print("[PlayerStats/Stats]", v.Name, "=", (pcall(function() return v.Value end)))
            end
        end
        local cacheFolder = sub:FindFirstChild("Cache")
        if cacheFolder then
            for _, v in ipairs(cacheFolder:GetChildren()) do
                if v.Name:lower():find("coin") or v.Name:lower():find("shady") or v.Name:lower():find("bazaar") or v.Name == "sc" or v.Name == "S$" then
                    print("[PlayerStats/Cache]", v.Name, "=", (pcall(function() return v.Value end)))
                end
            end
        end
    end)
    print("getShadyCoins() =", getShadyCoins())
    print("=========================")
end

setmetatable(AutoQuestShady, {
    __call = function(self, value)
        _G.Config.AutoQuestShady = value
        if value then
            AutoQuestShadyLoop()
        else
            updateStatusUI("Inactive")
        end
    end
})

return AutoQuestShady
