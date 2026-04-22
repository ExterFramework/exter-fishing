ClientBridge = {
    framework = 'standalone',
    fuel = 'none',
    core = nil,
    pendingCallbacks = {}
}

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

function ClientBridge.Init()
    ClientBridge.framework = detectFramework()
    ClientBridge.fuel = detectFuel()

    if ClientBridge.framework == 'qbcore' then
        ClientBridge.core = exports[Config.FrameworkResource.qbcore]:GetCoreObject()
    elseif ClientBridge.framework == 'qbox' then
        ClientBridge.core = exports[Config.FrameworkResource.qbox]:GetCoreObject()
    elseif ClientBridge.framework == 'esx' then
        ClientBridge.core = exports[Config.FrameworkResource.esx]:getSharedObject()
    end
end

function ClientBridge.Notify(message, notifType)
    notifType = notifType or 'inform'

    if ClientBridge.framework == 'qbcore' or ClientBridge.framework == 'qbox' then
        ClientBridge.core.Functions.Notify(message, notifType)
    elseif ClientBridge.framework == 'esx' then
        ClientBridge.core.ShowNotification(message)
    else
        TriggerEvent('chat:addMessage', { args = { 'Fishing', message } })
    end
end

function ClientBridge.TriggerCallback(name, cb, ...)
    local requestId = ('%d:%d'):format(GetGameTimer(), math.random(1111, 9999))
    ClientBridge.pendingCallbacks[requestId] = cb
    TriggerServerEvent('exter-fishing:server:triggerCallback', name, requestId, ...)
end

RegisterNetEvent('exter-fishing:client:callback', function(requestId, payload)
    local cb = ClientBridge.pendingCallbacks[requestId]
    if not cb then return end

    ClientBridge.pendingCallbacks[requestId] = nil
    cb(payload)
end)

function ClientBridge.Progress(name, label, duration, disableOptions, animOptions, onFinish, onCancel)
    disableOptions = disableOptions or {}
    animOptions = animOptions or {}

    if ClientBridge.framework == 'qbcore' or ClientBridge.framework == 'qbox' then
        ClientBridge.core.Functions.Progressbar(name, label, duration, false, true, disableOptions, animOptions, {}, {}, onFinish, onCancel)
        return
    end

    if ClientBridge.framework == 'esx' and resourceStarted('esx_progressbar') then
        exports.esx_progressbar:Progressbar(name, duration, {
            FreezePlayer = disableOptions.disableMovement,
            animation = {
                type = 'anim',
                dict = animOptions.animDict,
                lib = animOptions.anim
            },
            onFinish = onFinish,
            onCancel = onCancel
        })
        return
    end

    CreateThread(function()
        Wait(duration)
        if onFinish then onFinish() end
    end)
end

function ClientBridge.SetVehicleFuel(vehicle, fuelLevel)
    if not DoesEntityExist(vehicle) or ClientBridge.fuel == 'none' then return false end

    if ClientBridge.fuel == 'LegacyFuel' and resourceStarted('LegacyFuel') then
        return exports.LegacyFuel:SetFuel(vehicle, fuelLevel)
    elseif ClientBridge.fuel == 'CDN-Fuel' and resourceStarted('cdn-fuel') then
        return exports['cdn-fuel']:SetFuel(vehicle, fuelLevel)
    elseif ClientBridge.fuel == 'ox_fuel' and resourceStarted('ox_fuel') then
        return Entity(vehicle).state.fuel = fuelLevel
    elseif ClientBridge.fuel == 'qb-fuel' and resourceStarted('qb-fuel') then
        return exports['qb-fuel']:SetFuel(vehicle, fuelLevel)
    end

    return false
end

ClientBridge.Init()
