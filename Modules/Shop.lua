local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Helper getMod loader (no script dependency)
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
            if not fn then
                warn("[NewFish5] Failed to load module '" .. tostring(name) .. "': " .. tostring(err))
                return nil
            end
            local success, res = pcall(fn)
            if not success then
                warn("[NewFish5] Error executing module '" .. tostring(name) .. "': " .. tostring(res))
                return nil
            end
            return res
        end
    end
    return nil
end

local function Init(ShopBait, ShopItem, ShopRod, Merlin)
    local purchase = ReplicatedStorage:WaitForChild("events"):WaitForChild("purchase")
    local fire = purchase.FireServer

    ---------------------------------------------------------
    -- 1. ShopBait Section
    ---------------------------------------------------------
    local selectedBait = nil
    local baitBuyAmount = 1

    ShopBait:AddParagraph({
        Title = "Purchase System",
        Content = "• Max 50 per transaction\n• Auto-loops for larger amounts\n• 0.5s delay between purchases\n• Stops after 3 consecutive failures\n• Use 'Stop Purchase' to cancel"
    })

    ShopBait:AddDropdown({
        Title = "Select Bait",
        Content = "Choose a Bait to Purchase",
        Multi = false,
        Options = {
            "Common Crate",
            "Tropical Bait Crate",
            "Carbon Crate",
            "Bait Crate",
            "Quality Bait Crate",
            "Coral Geode",
            "Volcanic Geode",
            "Festive Bait Crate"
        },
        Callback = function(v)
            selectedBait = v
        end
    })

    ShopBait:AddInput({
        Title = "Buy Amount",
        Content = "Amount To Buy Bait",
        Value = "1",
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                baitBuyAmount = amount
            end
        end
    })

    ShopBait:AddButton({
        Title = "Buy Bait Crate",
        Content = "Theoretical maximum",
        Callback = function()
            if not selectedBait then return end
                local item = selectedBait
                local rem = tonumber(baitBuyAmount) or 1
                task.spawn(function()
                    pcall(function()
                        while rem > 0 do
                            local buyBatch = rem > 50 and 50 or rem
                            purchase:FireServer(item, "Fish", nil, buyBatch)
                            rem = rem - buyBatch
                        end
                    end)
                end)
        end
    })

    ShopBait:AddSeperator({
        Title = "Auto Buy Bait (NPC)"
    })

    ShopBait:AddToggle({
        Title = "Enable Auto Buy Bait",
        Default = _G.Config.AutoBuyBait or false,
        Callback = function(state)
            _G.Config.AutoBuyBait = state
        end
    })

    local BAIT_LIST = {
        "Worm", "Cricket", "Leech", "Minnow", "Firefly",
        "Shrimp", "Squid", "Sand Dollar", "Pearl",
        "Phantom Worm", "Enchanted Bait", "Seaside Sardine"
    }

    ShopBait:AddDropdown({
        Title = "Auto Buy Bait Type",
        Content = "Select individual bait to buy automatically",
        Options = BAIT_LIST,
        Default = _G.Config.SelectedBait or "Worm",
        Callback = function(v)
            _G.Config.SelectedBait = v
        end
    })

    ShopBait:AddInput({
        Title = "Auto Buy Quantity",
        Content = "Quantity of bait to purchase automatically",
        Value = tostring(_G.Config.BuyBaitAmount or 1),
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                _G.Config.BuyBaitAmount = amount
            end
        end
    })

    ---------------------------------------------------------
    -- 2. ShopItem Section
    ---------------------------------------------------------
    -- Retrieve Item list dynamically
    local itemNames = {}
    local successItems, itemsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("items"))
    end)
    if successItems and itemsModule and itemsModule.Items then
        for itemName in pairs(itemsModule.Items) do
            table.insert(itemNames, itemName)
        end
        table.sort(itemNames)
    else
        itemNames = {"Common Crate", "Carbon Crate"} -- Fallback
    end

    local PurchaseQuantity = 1
    local ItemDropdown = nil

    ShopItem:AddInput({
        Title = "Purchase Quantity",
        Content = "Amount To Buy Item",
        Value = "1",
        Callback = function(value)
            local num = tonumber(value)
            if num then
                PurchaseQuantity = num
            end
        end
    })

    ShopItem:AddDropdown({
        Title = "Select an Item",
        Content = "Choose an item from the shop to purchase.",
        Options = itemNames,
        Multi = false,
        Default = nil,
        Callback = function(value)
            ItemDropdown = value
        end
    })

    ShopItem:AddButton({
        Title = "Buy Selected Item",
        Content = "Theoretical maximum",
        Callback = function()
            if not ItemDropdown then return end
            task.spawn(function()
                local item = ItemDropdown
                local amount = tonumber(PurchaseQuantity) or 1
                for i = 1, amount do
                    task.spawn(function()
                        pcall(function()
                            purchase:FireServer(item, "Item", nil, 1)
                        end)
                    end)
                    if i % 20 == 0 then
                        task.wait(0.01)
                    end
                end
            end)
        end
    })

    -- Black Market Sub-Section
    ShopItem:AddSeperator({
        Title = 'Black Market',
    })

    local hud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("hud")
    local safezone = hud:WaitForChild("safezone")
    local BlackMarketGui = safezone:WaitForChild("BlackMarket")
    local ListFrame = BlackMarketGui:WaitForChild("List")
    local PurchaseRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/BlackMarket/Purchase")

    local AutoBM = {
        Enabled = false,
        TargetItem = nil,
        Items = {},
        ItemIDs = {},
        DropdownUI = nil
    }

    local function RefreshItemList()
        AutoBM.Items = {}
        AutoBM.ItemIDs = {}

        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("ItemPreview") then
                local titleLabel = child.ItemPreview:FindFirstChild("ItemHeader")
                    and child.ItemPreview.ItemHeader:FindFirstChild("ItemTitle")

                if titleLabel then
                    local displayName = titleLabel.Text
                    table.insert(AutoBM.Items, displayName)
                    AutoBM.ItemIDs[displayName] = child.Name
                end
            end
        end

        if #AutoBM.Items == 0 then
            table.insert(AutoBM.Items, "No items found")
        end

        if AutoBM.DropdownUI then
            pcall(function()
                if AutoBM.DropdownUI.SetValues then
                    AutoBM.DropdownUI:SetValues(AutoBM.Items)
                elseif AutoBM.DropdownUI.SetOptions then
                    AutoBM.DropdownUI:SetOptions(AutoBM.Items)
                elseif AutoBM.DropdownUI.Refresh then
                    AutoBM.DropdownUI:Refresh(AutoBM.Items)
                end
            end)
        end
    end

    AutoBM.DropdownUI = ShopItem:AddDropdown({
        Title = "Select Item Black Market",
        Options = AutoBM.Items,
        Multi = false,
        Value = nil,
        Callback = function(value)
            if value and AutoBM.ItemIDs[value] then
                AutoBM.TargetItem = value
            end
        end
    })

    ShopItem:AddButton({
        Title = "Refresh Item List Black Market",
        Callback = function()
            RefreshItemList()
        end
    })

    ShopItem:AddToggle({
        Title = "Auto Buy Selected Item Black Market",
        Content = "Automatically buy selected item repeatedly",
        Default = false,
        Callback = function(state)
            AutoBM.Enabled = state
            if state then
                task.spawn(function()
                    while AutoBM.Enabled do
                        if AutoBM.TargetItem and AutoBM.ItemIDs[AutoBM.TargetItem] then
                            local uuid = AutoBM.ItemIDs[AutoBM.TargetItem]
                            pcall(function()
                                PurchaseRemote:FireServer(uuid)
                            end)
                            task.wait(1)
                        else
                            task.wait(0.5)
                        end
                    end
                end)
            end
        end
    })

    -- Auto Buy Carrot Toggle
    ShopItem:AddToggle({
        Title = "Auto Buy Carrot",
        Default = _G.Config.AutoBuyCarrot or false,
        Callback = function(state)
            _G.Config.AutoBuyCarrot = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCarrot do
                        pcall(function()
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(266, 147, -146)
                            end
                            task.wait(0.2)
                            local args = { buffer.fromstring("h\000\006Carrot") }
                            ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    ---------------------------------------------------------
    -- 3. ShopRod Section
    ---------------------------------------------------------
    local rodNames = {}
    local successRods, rodsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("rods"))
    end)
    if successRods and rodsModule then
        local rodsTable = rodsModule.Rods or rodsModule
        if typeof(rodsTable) == "table" then
            for rodName in pairs(rodsTable) do
                table.insert(rodNames, rodName)
            end
            table.sort(rodNames)
        end
    end

    ShopRod:AddToggle({
        Title = "Auto Buy All Rods",
        Content = "Automatically buys all available rods in a loop",
        Default = _G.Config.AutoBuyAllRods or false,
        Callback = function(state)
            _G.Config.AutoBuyAllRods = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyAllRods do
                        pcall(function()
                            for _, rodName in ipairs(rodNames) do
                                if not _G.Config.AutoBuyAllRods then break end
                                fire(purchase, rodName, "Rod", nil, 1)
                                task.wait(0.1)
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end
        end
    })

    ---------------------------------------------------------
    -- 4. Merlin Section
    ---------------------------------------------------------
    local function FireProximity(proximity)
        if proximity:IsA("ProximityPrompt") and proximity.Enabled then
            pcall(function()
                local camera = workspace.CurrentCamera
                if camera then
                    local targetPos = nil
                    if proximity.Parent:IsA("Attachment") then
                        targetPos = proximity.Parent.WorldPosition
                    elseif proximity.Parent:IsA("BasePart") then
                        targetPos = proximity.Parent.Position
                    end
                    if targetPos then
                        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
                        task.wait(0.1)
                    end
                end
            end)
            proximity:InputHoldBegin()
            proximity.HoldDuration = 0
            proximity:InputHoldEnd()
        end
    end

    local merlinOptions = {"1", "2", "5", "10", "25", "50"}
    local selectedMerlinOpt = 1
    Merlin:AddDropdown({
        Title = "Merlin Option",
        Options = merlinOptions,
        Default = "1",
        Callback = function(v)
            for i, option in ipairs(merlinOptions) do
                if option == v then
                    selectedMerlinOpt = i
                    break
                end
            end
        end
    })

    Merlin:AddToggle({
        Title = "Auto Buy Merlin",
        Default = _G.Config.AutoBuyMerlin or false,
        Callback = function(state)
            _G.Config.AutoBuyMerlin = state
            if state then
                task.spawn(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-952, 223, -987)
                    end
                    task.wait(0.5)

                    local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
                    local npcMerlin = npcs and npcs:FindFirstChild("Merlin")
                    local prompt = npcMerlin and npcMerlin:FindFirstChild("ProximityPrompt")
                    if prompt then
                        FireProximity(prompt)
                    end
                    task.wait(0.5)

                    local interactRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
                    while _G.Config.AutoBuyMerlin do
                        pcall(function()
                            interactRemote:InvokeServer(3, selectedMerlinOpt)
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    local MerlinItems = {
        {Title = "Auto Buy - Temporary Luck Boost", Node = 9,  Choice = 1},
        {Title = "Auto Buy - Temporary Lure Boost", Node = 10, Choice = 1},
        {Title = "Auto Buy - Temporary XP Boost",   Node = 7,  Choice = 1},
        {Title = "Auto Buy - Twisted Relic",         Node = 11, Choice = 1},
    }

    local clonedMerlin = nil
    local function setupMerlinClone()
        local originalCFrame = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer.Character.HumanoidRootPart.CFrame

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-952, 223, -987)
        end
        task.wait(0.5)
        local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
        local npcMerlin = npcs and npcs:FindFirstChild("Merlin")
        local prompt = npcMerlin and npcMerlin:FindFirstChild("ProximityPrompt")
        if prompt then
            FireProximity(prompt)
        end
        task.wait(3)

        if npcMerlin then
            clonedMerlin = npcMerlin:Clone()
            clonedMerlin.Parent = npcs
            clonedMerlin.Name = "MerlinClone"
        end
        task.wait(0.3)
        if originalCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
        end
        task.wait(0.5)
    end

    local dialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
    for _, item in ipairs(MerlinItems) do
        local itemKey = "AutoBuyMerlin_" .. item.Node
        Merlin:AddToggle({
            Title = item.Title,
            Default = _G.Config[itemKey] or false,
            Callback = function(state)
                _G.Config[itemKey] = state
                if state then
                    task.spawn(function()
                        if not clonedMerlin or not clonedMerlin.Parent then
                            setupMerlinClone()
                        end
                        pcall(function() dialogInteract:InvokeServer(item.Node, item.Choice) end)
                        while _G.Config[itemKey] do
                            task.wait(30 * 60)
                            if not _G.Config[itemKey] then break end
                            pcall(function() dialogInteract:InvokeServer(item.Node, item.Choice) end)
                        end
                    end)
                else
                    local anyActive = false
                    for _, i in ipairs(MerlinItems) do
                        if _G.Config["AutoBuyMerlin_" .. i.Node] then
                            anyActive = true
                            break
                        end
                    end
                    if not anyActive and clonedMerlin and clonedMerlin.Parent then
                        clonedMerlin:Destroy()
                        clonedMerlin = nil
                    end
                end
            end
        })
    end
end

return Init
