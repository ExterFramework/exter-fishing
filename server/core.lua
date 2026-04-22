Bridge = {
    framework = 'standalone',
    inventory = 'standalone',
    fuel = 'none',
    core = nil,
    callbacks = {}
}

local function dbg(...)
    if Config.Debug then
        print('[exter-fishing]', ...)
    end
end

local function resourceStarted(name)
    return name and GetResourceState(name) == 'started'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return string.lower(Config.Framework)
    end

    if resourceStarted(Config.FrameworkResource.qbox) then return 'qbox' end
    if resourceStarted(Config.FrameworkResource.qbcore) then return 'qbcore' end
    if resourceStarted(Config.FrameworkResource.esx) then return 'esx' end
    return 'standalone'
end

local function detectInventory()
    if Config.Inventory ~= 'auto' then
        return Config.Inventory
    end

    for inventoryName, resourceName in pairs(Config.InventoryResource) do
        if resourceStarted(resourceName) then
            return inventoryName
        end
    end

    if Bridge.framework == 'esx' then
        return 'esx_inventory'
    end

    return 'standalone'
end

local function detectFuel()
    if not Config.Fuel.enabled then return 'none' end
    if Config.Fuel.system ~= 'auto' then return Config.Fuel.system end

    for fuelName, resourceName in pairs(Config.Fuel.resources) do
        if resourceStarted(resourceName) then
            return fuelName
        end
    end

    return 'none'
end

function Bridge.Init()
    Bridge.framework = detectFramework()

    if Bridge.framework == 'qbcore' then
        Bridge.core = exports[Config.FrameworkResource.qbcore]:GetCoreObject()
    elseif Bridge.framework == 'qbox' then
        Bridge.core = exports[Config.FrameworkResource.qbox]:GetCoreObject()
    elseif Bridge.framework == 'esx' then
        Bridge.core = exports[Config.FrameworkResource.esx]:getSharedObject()
    end

    Bridge.inventory = detectInventory()
    Bridge.fuel = detectFuel()

    dbg(('framework=%s inventory=%s fuel=%s'):format(Bridge.framework, Bridge.inventory, Bridge.fuel))
end

function Bridge.GetPlayer(source)
    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        return Bridge.core.Functions.GetPlayer(source)
    elseif Bridge.framework == 'esx' then
        return Bridge.core.GetPlayerFromId(source)
    end
    return nil
end

function Bridge.Notify(source, message, notifType)
    notifType = notifType or 'inform'
    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        TriggerClientEvent('QBCore:Notify', source, message, notifType)
    elseif Bridge.framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'Fishing', message } })
    end
end

function Bridge.GetIdentifier(source)
    local player = Bridge.GetPlayer(source)
    if not player then return ('standalone:%s'):format(source) end

    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        return player.PlayerData.citizenid or ('src:%s'):format(source)
    end

    if Bridge.framework == 'esx' then
        return player.identifier or ('src:%s'):format(source)
    end

    return ('src:%s'):format(source)
end

function Bridge.GetName(source)
    local player = Bridge.GetPlayer(source)
    if not player then return GetPlayerName(source) or ('Unknown (%s)'):format(source) end

    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        local info = player.PlayerData.charinfo or {}
        return (info.firstname or 'Unknown') .. ' ' .. (info.lastname or '')
    elseif Bridge.framework == 'esx' then
        return player.getName() or (GetPlayerName(source) or 'Unknown')
    end

    return GetPlayerName(source) or 'Unknown'
end

local function normalizeInventoryItem(item)
    if not item then return nil end

    local info = item.info or item.metadata or {}
    local amount = item.amount or item.count or 0
    return {
        name = item.name,
        amount = amount,
        info = info,
        slot = item.slot
    }
end

function Bridge.GetInventoryItems(source, player)
    player = player or Bridge.GetPlayer(source)

    if Bridge.inventory == 'ox_inventory' and resourceStarted(Config.InventoryResource['ox_inventory']) then
        local items = exports.ox_inventory:GetInventoryItems(source) or {}
        local normalized = {}
        for _, item in pairs(items) do
            normalized[#normalized + 1] = normalizeInventoryItem(item)
        end
        return normalized
    end

    if (Bridge.framework == 'qbcore' or Bridge.framework == 'qbox') and player then
        local items = player.PlayerData.items or {}
        local normalized = {}
        for _, item in pairs(items) do
            normalized[#normalized + 1] = normalizeInventoryItem(item)
        end
        return normalized
    end

    if Bridge.framework == 'esx' and player then
        local items = player.inventory or {}
        local normalized = {}
        for _, item in pairs(items) do
            if item.count and item.count > 0 then
                normalized[#normalized + 1] = normalizeInventoryItem(item)
            end
        end
        return normalized
    end

    return {}
end

function Bridge.HasItem(source, itemName, amount, player)
    amount = amount or 1
    player = player or Bridge.GetPlayer(source)

    if Bridge.inventory == 'ox_inventory' and resourceStarted(Config.InventoryResource['ox_inventory']) then
        local count = exports.ox_inventory:GetItemCount(source, itemName)
        return (count or 0) >= amount
    end

    if Bridge.inventory == 'qs-inventory' and resourceStarted(Config.InventoryResource['qs-inventory']) then
        local ok, count = pcall(function()
            return exports['qs-inventory']:Search(source, 'count', itemName)
        end)
        if ok then return (count or 0) >= amount end
    end

    if (Bridge.framework == 'qbcore' or Bridge.framework == 'qbox') and player then
        local item = player.Functions.GetItemByName(itemName)
        return item and (item.amount or 0) >= amount
    end

    if Bridge.framework == 'esx' and player then
        local item = player.getInventoryItem(itemName)
        return item and (item.count or 0) >= amount
    end

    return false
end

function Bridge.AddItem(source, itemName, amount, metadata, player)
    amount = amount or 1
    player = player or Bridge.GetPlayer(source)

    if Bridge.inventory == 'ox_inventory' and resourceStarted(Config.InventoryResource['ox_inventory']) then
        return exports.ox_inventory:AddItem(source, itemName, amount, metadata or nil)
    end

    if Bridge.inventory == 'qs-inventory' and resourceStarted(Config.InventoryResource['qs-inventory']) then
        local ok, result = pcall(function()
            return exports['qs-inventory']:AddItem(source, itemName, amount, false, metadata or {})
        end)
        if ok then return result end
    end

    if (Bridge.framework == 'qbcore' or Bridge.framework == 'qbox') and player then
        return player.Functions.AddItem(itemName, amount, nil, metadata or nil)
    end

    if Bridge.framework == 'esx' and player then
        player.addInventoryItem(itemName, amount)
        return true
    end

    return false
end

function Bridge.RemoveItem(source, itemName, amount, player)
    amount = amount or 1
    player = player or Bridge.GetPlayer(source)

    if Bridge.inventory == 'ox_inventory' and resourceStarted(Config.InventoryResource['ox_inventory']) then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    end

    if Bridge.inventory == 'qs-inventory' and resourceStarted(Config.InventoryResource['qs-inventory']) then
        local ok, result = pcall(function()
            return exports['qs-inventory']:RemoveItem(source, itemName, amount)
        end)
        if ok then return result end
    end

    if (Bridge.framework == 'qbcore' or Bridge.framework == 'qbox') and player then
        return player.Functions.RemoveItem(itemName, amount)
    end

    if Bridge.framework == 'esx' and player then
        player.removeInventoryItem(itemName, amount)
        return true
    end

    return false
end

function Bridge.AddMoney(source, amount)
    local player = Bridge.GetPlayer(source)
    if not player then return false end

    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        player.Functions.AddMoney('cash', amount)
        return true
    elseif Bridge.framework == 'esx' then
        player.addMoney(amount)
        return true
    end

    return false
end

function Bridge.RegisterUsableItem(itemName, handler)
    if Bridge.framework == 'qbcore' or Bridge.framework == 'qbox' then
        Bridge.core.Functions.CreateUseableItem(itemName, function(source, item)
            handler(source, item)
        end)
    elseif Bridge.framework == 'esx' then
        Bridge.core.RegisterUsableItem(itemName, function(source)
            handler(source)
        end)
    else
        dbg(('Standalone mode: usable item %s cannot be auto-registered.'):format(itemName))
    end
end

function Bridge.RegisterCallback(name, handler)
    Bridge.callbacks[name] = handler
end

RegisterNetEvent('exter-fishing:server:triggerCallback', function(name, requestId, ...)
    local src = source
    local callback = Bridge.callbacks[name]
    if not callback then
        TriggerClientEvent('exter-fishing:client:callback', src, requestId, nil)
        return
    end

    callback(src, function(result)
        TriggerClientEvent('exter-fishing:client:callback', src, requestId, result)
    end, ...)
end)

Bridge.Init()
