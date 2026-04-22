local minigameCallback = nil

local function StartMinigame(playerInfluence, automaticSpeed, directionChangeInterval)
    SendNUIMessage({
        type = 'startMinigame',
        playerInfluence = playerInfluence,
        automaticSpeed = automaticSpeed,
        directionChangeInterval = directionChangeInterval
    })
    SetNuiFocus(true, true)
end

local function StopMinigame()
    SendNUIMessage({ type = 'stopMinigame' })
    SetNuiFocus(false, false)
end

RegisterNUICallback('minigameResult', function(data, cb)
    local success = data and data.success == true
    cb({ closeUI = true })
    StopMinigame()

    if minigameCallback then
        minigameCallback(success)
    end
    minigameCallback = nil
end)

exports('StartMinigame', function(playerInfluence, automaticSpeed, directionChangeInterval, callback)
    minigameCallback = callback
    StartMinigame(playerInfluence, automaticSpeed, directionChangeInterval)
end)
