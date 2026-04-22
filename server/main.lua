local function round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function roundInteger(num)
    return math.floor(num + 0.5)
end

local function isFishItem(itemName)
    for _, fish in ipairs(Config.FishLists) do
        if fish.name == itemName then
            return true
        end
    end
    return false
end

local function pickRandomFish()
    local fishWeights = {}
    local totalWeight = 0.0

    for _, fish in ipairs(Config.FishLists) do
        local lengthRange = math.max((fish.maxLength or 0) - (fish.minLength or 0), 1)
        local avgPrice = ((fish.minPrice or 0) + (fish.maxPrice or 0)) / 2
        local weighted = lengthRange * math.pow(math.max(avgPrice, 1), -1.5)
        local adjusted = math.max(weighted, 0.1) * (1 + math.random() * 0.2)

        totalWeight = totalWeight + adjusted
        fishWeights[#fishWeights + 1] = { fish = fish, weight = adjusted }
    end

    if totalWeight <= 0 then return nil end

    local target = math.random() * totalWeight
    local running = 0.0
    for _, entry in ipairs(fishWeights) do
        running = running + entry.weight
        if target <= running then
            return entry.fish
        end
    end

    return fishWeights[#fishWeights] and fishWeights[#fishWeights].fish or nil
end

Bridge.RegisterUsableItem(Config.Items.rod, function(source)
    TriggerClientEvent('exter-fishing:startMami', source)
end)

RegisterNetEvent('exter-fishing:collectFishingCatch', function()
    local src = source
    local player = Bridge.GetPlayer(src)

    if not player and Bridge.framework ~= 'standalone' then
        return
    end

    if not Bridge.HasItem(src, Config.Items.bait, 1, player) then
        Bridge.Notify(src, 'Fish escaped because you had no bait.', 'error')
        return
    end

    local selectedFish = pickRandomFish()
    if not selectedFish then
        Bridge.Notify(src, 'No fish data available. Please contact staff.', 'error')
        return
    end

    local lengthRange = math.max(selectedFish.maxLength - selectedFish.minLength, 1)
    local length = selectedFish.minLength + (lengthRange * (math.random() ^ 2))

    local priceRange = math.max(selectedFish.maxPrice - selectedFish.minPrice, 1)
    local lengthRatio = (length - selectedFish.minLength) / lengthRange
    local price = selectedFish.minPrice + (priceRange * lengthRatio)

    length = round(length, 2)
    price = round(price, 2)

    if math.random() <= Config.BaitConsumeChance then
        Bridge.RemoveItem(src, Config.Items.bait, 1, player)
    end

    local metadata = { length = length, price = price }
    local added = Bridge.AddItem(src, selectedFish.name, 1, metadata, player)

    if not added then
        Bridge.Notify(src, 'Inventory penuh / item gagal ditambahkan.', 'error')
        return
    end

    local playerName = Bridge.GetName(src)
    local caughtAt = os.date('%Y-%m-%d %H:%M:%S')
    TriggerEvent('exter-fishing:server:updateLeaderboard', selectedFish.name, length, playerName, caughtAt)

    Bridge.Notify(src, ('You caught a %s (%.2f cm)!'):format(selectedFish.name, length), 'success')
end)

RegisterNetEvent('exter-fishing:sellFishes', function()
    local src = source
    local player = Bridge.GetPlayer(src)
    local totalValue = 0

    local inventoryItems = Bridge.GetInventoryItems(src, player)
    for _, itemData in ipairs(inventoryItems) do
        local itemName = itemData.name and string.lower(itemData.name) or nil
        if itemName and isFishItem(itemName) then
            local info = itemData.info or {}
            local price = tonumber(info.price) or 0
            local amount = tonumber(itemData.amount) or 0

            if amount > 0 and price > 0 then
                totalValue = totalValue + (round(price, 2) * amount)
                Bridge.RemoveItem(src, itemName, amount, player)
            end
        end
    end

    totalValue = roundInteger(totalValue)

    if totalValue <= 0 then
        Bridge.Notify(src, 'Tidak ada ikan yang bisa dijual.', 'error')
        return
    end

    if not Bridge.AddMoney(src, totalValue) then
        Bridge.Notify(src, 'Framework standalone tidak mendukung uang bawaan.', 'error')
        return
    end

    Bridge.Notify(src, ('Berhasil menjual ikan seharga $%d'):format(totalValue), 'success')
end)
