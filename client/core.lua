if Config.Framework == 'QBCore' then
    exter = exports[Config.FrameworkFolder]:GetCoreObject()
else
    exter = exports[Config.FrameworkFolder]:getSharedObject()
end

--[[ currentRep = 0

function Rep()
    local p = promise.new()
    if Config.Framework == 'QBCore'then
        exter.Functions.TriggerCallback('exter-contacts:getRep', function(result)
            p:resolve(result)    
        end, "Fishing") 
    else
        exter.TriggerServerCallback('exter-contacts:getRep', function(result)
            p:resolve(result)    
        end, "Fishing") 
    end
    return Citizen.Await(p)
end ]]

function Notify(msg, typ)
    if Config.Framework == 'QBCore' then
        exter.Functions.Notify(msg, typ)
    else
        exter.ShowHelpNotification(msg)
    end
end

function TriggerCallback(name, cb, ...)
    if Config.Framework == 'QBCore' then
        exter.Functions.TriggerCallback(name, cb, ...)
    else
        exter.TriggerServerCallback(name, cb, ...)
    end
end

function ProgBar(name, label, duration, disableOptions, animOptions, onFinish, onCancel)
    if Config.Framework == 'QBCore' then
        exter.Functions.Progressbar(name, label, duration, false, true, disableOptions, animOptions, {}, {}, onFinish, onCancel)
    else
        exports["esx_progressbar"]:Progressbar(name, duration, {
            FreezePlayer = disableOptions.disableMovement,
            animation = {
                type = "anim",
                dict = animOptions.animDict,
                lib = animOptions.anim
            },
            onFinish = onFinish,
            onCancel = onCancel
        })
    end
end