local isFishing = false
local fishingRod

local function loadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function cleanupFishingState(ped)
    if ped and DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end

    if fishingRod and DoesEntityExist(fishingRod) then
        DeleteEntity(fishingRod)
    end

    fishingRod = nil
    isFishing = false
end

local function fishAnimation()
    local ped = PlayerPedId()

    loadAnim('mini@tennis')
    TaskPlayAnim(ped, 'mini@tennis', 'forehand_ts_md_far', 1.0, -1.0, 1300, 48, 0, false, false, false)
    Wait(1300)

    loadAnim('amb@world_human_stand_fishing@idle_a')
    TaskPlayAnim(ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 1.0, -1.0, -1, 10, 0, false, false, false)

    local duration = math.random(Config.WaitForBiteMs.min, Config.WaitForBiteMs.max)
    ClientBridge.Progress('wait_bite', 'Waiting for a bite...', duration, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, function()
        exports['exter-fishing']:StartMinigame(35, 2000, 1500, function(success)
            if success then
                TriggerServerEvent('exter-fishing:collectFishingCatch')
            else
                ClientBridge.Notify('You failed to catch the fish. Try again!', 'error')
            end

            cleanupFishingState(ped)
        end)
    end, function()
        cleanupFishingState(ped)
    end)
end

local function startFishing()
    if isFishing then return end
    isFishing = true

    local model = `prop_fishing_rod_01`
    if not IsModelValid(model) then
        ClientBridge.Notify('Fishing rod model is invalid.', 'error')
        isFishing = false
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    fishingRod = CreateObject(model, coords.x, coords.y, coords.z, true, false, false)

    if not DoesEntityExist(fishingRod) then
        ClientBridge.Notify('Failed to create fishing rod object.', 'error')
        isFishing = false
        return
    end

    AttachEntityToEntity(fishingRod, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.05, 0.0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)

    fishAnimation()
end

RegisterNetEvent('exter-fishing:startMami', function()
    local ped = PlayerPedId()

    if IsPedSwimming(ped) then
        return ClientBridge.Notify("You can't swim and fish at the same time.", 'error')
    end

    if IsPedInAnyVehicle(ped) then
        return ClientBridge.Notify('Exit your vehicle before fishing.', 'error')
    end

    local pos = GetEntityCoords(ped)
    local hasWater = GetWaterHeight(pos.x, pos.y, pos.z - 1.0, pos.z - 3.0)
    if not hasWater then
        return ClientBridge.Notify('You need to get close to shore.', 'error')
    end

    startFishing()
end)
