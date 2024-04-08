RSGCore = exports['rsg-core']:GetCoreObject()

-- Add a variable to store the currently worn backpack
local currentBackpack = nil
if LocalPlayer.state.isLoggedIn then
    TriggerServerEvent('wd_backpacks:server:getBagPositions')
    print("Getting bag positions")
end
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(1000) -- Wait for the player to fully load

    if LocalPlayer.state.isLoggedIn then
        TriggerServerEvent('wd_backpacks:server:getBagPositions')
        print("Getting bag positions")
    end
end)
-- Place Backpack
RegisterNetEvent('wd_backpacks:client:placeBackpack')
AddEventHandler('wd_backpacks:client:placeBackpack', function(model, stashId)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local x, y, z = table.unpack(coords + forward * 1.0)

    -- Check if the player has a backpack currently attached
    if currentBackpack then
        -- Delete the currently attached backpack
        DeleteEntity(currentBackpack)
        currentBackpack = nil
    end

    local bag = CreateObject(GetHashKey(model), x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(bag)
    SetEntityHeading(bag, heading)
    FreezeEntityPosition(bag, true)

    exports['rsg-target']:AddTargetEntity(bag, {
        options = {
            {
                type = 'client',
                event = 'wd_backpacks:client:lockBackpack',
                icon = 'fas fa-lock',
                label = 'Lock Backpack',
                stashId = stashId,
                canInteract = function(entity)
                    return not IsBackpackLocked(entity)
                end
            },
            {
                type = 'client',
                event = 'wd_backpacks:client:unlockBackpack',
                icon = 'fas fa-unlock',
                label = 'Unlock Backpack',
                stashId = stashId,
                canInteract = function(entity)
                    return IsBackpackLocked(entity)
                end
            },
            {
                type = 'client',
                event = 'wd_backpacks:client:openBackpack',
                icon = 'fas fa-briefcase',
                label = 'Open Backpack',
                stashId = stashId,
                canInteract = function(entity)
                    return not IsBackpackLocked(entity)
                end
            },
            {
                type = 'client',
                event = 'wd_backpacks:client:wearBackpack',
                icon = 'fas fa-backpack',
                label = 'Wear Backpack',
                stashId = stashId,
                entity = bag
            },
            {
                type = 'client',
                event = 'wd_backpacks:client:rollUpBackpack',
                icon = 'fas fa-suitcase-rolling',
                label = 'Roll Up Backpack',
                stashId = stashId,
                entity = bag
            }
        },
        distance = 2.5
    })

    -- Remove the backpack item from the player's inventory
    TriggerServerEvent('wd_backpacks:server:removeBackpackItem', model, stashId)
        -- Save the bag position to the database
    TriggerServerEvent('wd_backpacks:server:saveBagPosition', model, x, y, z, heading, stashId)
end)

-- Lock Backpack
RegisterNetEvent('wd_backpacks:client:lockBackpack')
AddEventHandler('wd_backpacks:client:lockBackpack', function(data)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local backpack = data.entity
    local stashId = data.stashId

    if IsBackpackOwner(backpack, stashId) then
        LockBackpack(backpack)
        exports['rsg-target']:RemoveTargetEntity(backpack, 'Open Backpack')
        exports['rsg-target']:RemoveTargetEntity(backpack, 'Lock Backpack')
        exports['rsg-target']:AddTargetEntity(backpack, {
            options = {
                {
                    type = 'client',
                    event = 'wd_backpacks:client:unlockBackpack',
                    icon = 'fas fa-unlock',
                    label = 'Unlock Backpack',
                    stashId = stashId
                },
                {
                    type = 'client',
                    event = 'wd_backpacks:client:wearBackpack',
                    icon = 'fas fa-backpack',
                    label = 'Wear Backpack',
                    stashId = stashId,
                    entity = backpack
                },
                {
                    type = 'client',
                    event = 'wd_backpacks:client:rollUpBackpack',
                    icon = 'fas fa-suitcase-rolling',
                    label = 'Roll Up Backpack',
                    stashId = stashId,
                    entity = backpack
                }
            },
            distance = 2.5
        })
    else
        RSGCore.Functions.Notify('You are not the owner of this backpack', 'error')
    end
end)

-- Unlock Backpack
RegisterNetEvent('wd_backpacks:client:unlockBackpack')
AddEventHandler('wd_backpacks:client:unlockBackpack', function(data)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local backpack = data.entity
    local stashId = data.stashId

    if IsBackpackOwner(backpack, stashId) then
        UnlockBackpack(backpack)
        exports['rsg-target']:RemoveTargetEntity(backpack, 'Unlock Backpack')
        exports['rsg-target']:AddTargetEntity(backpack, {
            options = {
                {
                    type = 'client',
                    event = 'wd_backpacks:client:lockBackpack',
                    icon = 'fas fa-lock',
                    label = 'Lock Backpack',
                    stashId = stashId
                },
                {
                    type = 'client',
                    event = 'wd_backpacks:client:openBackpack',
                    icon = 'fas fa-briefcase',
                    label = 'Open Backpack',
                    stashId = stashId
                },
                {
                    type = 'client',
                    event = 'wd_backpacks:client:wearBackpack',
                    icon = 'fas fa-backpack',
                    label = 'Wear Backpack',
                    stashId = stashId,
                    entity = backpack
                },
                {
                    type = 'client',
                    event = 'wd_backpacks:client:rollUpBackpack',
                    icon = 'fas fa-suitcase-rolling',
                    label = 'Roll Up Backpack',
                    stashId = stashId,
                    entity = backpack
                }
            },
            distance = 2.5
        })
    else
        RSGCore.Functions.Notify('You are not the owner of this backpack', 'error')
    end
end)

-- Open Backpack
RegisterNetEvent('wd_backpacks:client:openBackpack')
AddEventHandler('wd_backpacks:client:openBackpack', function(data)
    local stashId = data.stashId
    local backpackModel = GetBackpackModel(stashId)

    if backpackModel and Config.Backpacks[backpackModel] then
        local size = Config.Backpacks[backpackModel].size

        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, {
            maxweight = size,
            slots = 10
        })
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
    else
        RSGCore.Functions.Notify('Invalid backpack model', 'error')
    end
end)

-- Wear Backpack
RegisterNetEvent('wd_backpacks:client:wearBackpack')
AddEventHandler('wd_backpacks:client:wearBackpack', function(data)
    local stashId = data.stashId
    local backpackModel = GetBackpackModel(stashId)
    local backpackConfig = Config.Backpacks[backpackModel]
    local entity = data.entity

    -- Check if the player already has a backpack attached
    if currentBackpack then
        RSGCore.Functions.Notify('You are already wearing a backpack', 'error')
        return 
    end

    -- Delete the backpack entity from the world
    DeleteEntity(entity)

    -- Remove the interaction prompts for the backpack
    exports['rsg-target']:RemoveTargetEntity(entity, 'Lock Backpack')
    exports['rsg-target']:RemoveTargetEntity(entity, 'Unlock Backpack')
    exports['rsg-target']:RemoveTargetEntity(entity, 'Open Backpack')
    exports['rsg-target']:RemoveTargetEntity(entity, 'Wear Backpack')
    exports['rsg-target']:RemoveTargetEntity(entity, 'Roll Up Backpack')

    -- Attach the backpack to the player
    local attachedBackpack = AttachBackpack(backpackModel, backpackConfig.pos, backpackConfig.rot, backpackConfig.boneIndex, backpackConfig.softping, backpackConfig.collision, backpackConfig.vertex, backpackConfig.fixedRot)

    -- Set the currently worn backpack
    currentBackpack = attachedBackpack

    -- Add the backpack item to the player's inventory with the correct metadata
    TriggerServerEvent('wd_backpacks:server:addBackpackItem', backpackModel, stashId)
end)

-- Roll Up Backpack
RegisterNetEvent('wd_backpacks:client:rollUpBackpack')
AddEventHandler('wd_backpacks:client:rollUpBackpack', function(data)
    local stashId = data.stashId
    local entity = data.entity

    -- Check if the backpack is empty
    TriggerServerEvent('wd_backpacks:server:checkBackpackEmpty', stashId, function(isEmpty)
        if isEmpty then
            -- Delete the backpack entity from the world
            DeleteEntity(entity)

            -- Remove the interaction prompts for the backpack
            exports['rsg-target']:RemoveTargetEntity(entity, 'Lock Backpack')
            exports['rsg-target']:RemoveTargetEntity(entity, 'Unlock Backpack')
            exports['rsg-target']:RemoveTargetEntity(entity, 'Open Backpack')
            exports['rsg-target']:RemoveTargetEntity(entity, 'Wear Backpack')
            exports['rsg-target']:RemoveTargetEntity(entity, 'Roll Up Backpack')

            -- Check if the rolled up backpack is the currently worn backpack
            if currentBackpack == entity then
                currentBackpack = nil
            end

            -- Add the backpack item to the player's inventory with the correct metadata
            TriggerServerEvent('wd_backpacks:server:addBackpackItem', GetBackpackModel(stashId), stashId)
        else
            RSGCore.Functions.Notify('Cannot roll up the backpack as it contains items', 'error')
        end
    end)
end)

-- Utility Functions
function IsBackpackOwner(entity, stashId)
    local playerCitizenId = RSGCore.Functions.GetPlayerData().citizenid
    return string.find(stashId, playerCitizenId) ~= nil
end

function IsBackpackLocked(entity)
    return Entity(entity).state.locked
end

function LockBackpack(entity)
    Entity(entity).state.locked = true
end

function UnlockBackpack(entity)
    Entity(entity).state.locked = false
end

function GetBackpackModel(stashId)
    local model = string.match(stashId, '_(.+)_')
    return model
end

function AttachBackpack(model, pos, rot, boneIndex, softping, collision, vertex, fixedRot)
    local ped = PlayerPedId()
    local bag = CreateObject(GetHashKey(model), 0, 0, 0, true, true, true)
	SetEntityRotation(bag, rot, 2)
    AttachEntityToEntity(bag, ped, boneIndex, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, false, softping, collision, false, vertex, fixedRot, false, false)

    SetEntityAsMissionEntity(bag, true, true)

    return bag
end