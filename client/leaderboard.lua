RegisterNetEvent('exter-fishing:showLeaderboard', function()
    local fishNames = {}
    for _, fish in ipairs(Config.FishLists) do
        fishNames[#fishNames + 1] = fish.name
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showLeaderboard',
        fishList = fishNames
    })
end)

RegisterNUICallback('hideMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('fetchLeaderboard', function(data, cb)
    local fishName = data and data.fishName
    if type(fishName) ~= 'string' or fishName == '' then
        cb({ ok = false })
        return
    end

    ClientBridge.TriggerCallback('exter-fishing:server:getLeaderboard', function(result)
        SendNUIMessage({
            type = 'updateLeaderboard',
            leaderboard = result or {}
        })
        cb({ ok = true })
    end, fishName)
end)
