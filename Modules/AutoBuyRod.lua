
local function init(rodName)
    print("[NewFish5] Buying Rod:", rodName)
    local purchase = game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Merchant/Purchase")
    if purchase then
        purchase:FireServer(rodName, "Rod", nil, 1)
    end
end
return init