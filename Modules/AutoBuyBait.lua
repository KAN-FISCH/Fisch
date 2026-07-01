
local function init(baitName, amount)
    print("[NewFish5] Buying Bait:", baitName, "Amount:", amount)
    local purchase = game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Merchant/Purchase")
    if purchase then
        local rem = tonumber(amount) or 1
        while rem > 0 do 
            local batch = rem > 50 and 50 or rem
            purchase:FireServer(baitName, "Fish", nil, batch) 
            rem = rem - batch 
            task.wait(0.1)
        end
    end
end
return init