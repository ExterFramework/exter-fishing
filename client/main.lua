local canFish = false
local isFishing = false
local fishingRod

local fishAnimation = function()
    local ped = PlayerPedId()
    RequestAnimDict('mini@tennis')
    while not HasAnimDictLoaded('mini@tennis') do Wait(0) end
    TaskPlayAnim(ped, 'mini@tennis', 'forehand_ts_md_far', 1.0, -1.0, 1.0, 48, 0, 0, 0, 0)
    while IsEntityPlayingAnim(ped, 'mini@tennis', 'forehand_ts_md_far', 3) do Wait(0) end

    -- Fish Animation
    RequestAnimDict('amb@world_human_stand_fishing@idle_a')
    while not HasAnimDictLoaded('amb@world_human_stand_fishing@idle_a') do Wait(0) end
    TaskPlayAnim(ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 1.0, -1.0, 1.0, 10, 0, 0, 0, 0)
    
    
    ProgBar("wait_bit", "Waiting for a bite...", math.random(10, 20) * 1000, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, function() -- Done
        TaskPlayAnim(ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 1.0, -1.0, 1.0, 10, 0, 0, 0, 0)
        exports['exter-fishing']:StartMinigame(35, 2000, 1500, function(success)
            if success then
                TriggerServerEvent("exter-fishing:collectFishingCatch")
            else
                Notify("You failed to catch the fish. Get Better!")
            end
    
            ClearPedTasks(ped)
            DeleteObject(fishingRod)
            isFishing = false
        end) 
    end, function()
        ClearPedTasks(ped)
        DeleteObject(fishingRod)
        isFishing = false
    end) 
end

local startFishing = function()
    if isFishing then return end
    isFishing = true

    local fishingRodHash = GetHashKey("prop_fishing_rod_01")
    if not IsModelValid(fishingRodHash) then return end
    if not HasModelLoaded(fishingRodHash) then RequestModel(fishingRodHash) end
    while not HasModelLoaded do Wait(0) end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local object = CreateObject(fishingRodHash, pedCoords, true, false, false)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.05, 0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(object)
    fishingRod = object
    fishAnimation()
end

RegisterNetEvent("exter-fishing:startMami", function()
    local playerPed = PlayerPedId()
	local pos = GetEntityCoords(playerPed) 
	if IsPedSwimming(playerPed) then return Notify("You can't be swimming and fishing at the same time.", "error") end 
	if IsPedInAnyVehicle(playerPed) then return Notify("You need to exit your vehicle to start fishing.", "error") end 
	if GetWaterHeight(pos.x, pos.y, pos.z - 1, pos.z - 3.0)  then
		startFishing()
	else
		Notify('You need to get close to the shore', 'error')
	end
end)