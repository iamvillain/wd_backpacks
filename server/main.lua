RSGCore = exports['rsg-core']:GetCoreObject()

RSGCore.Functions.CreateUseableItem('backpack', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenId = Player.PlayerData.citizenid
    local itemData = Player.Functions.GetItemBySlot(item.slot)
    
    if itemData.info.model == nil then
        -- Set the default backpack model to 'p_ambpack04x' if not set
        itemData.info.model = 'p_ambpack04x'
        itemData.info.stashId = citizenId .. '_' .. itemData.info.model .. '_' .. math.random(1000, 9999)
        Player.Functions.SetInventory(Player.PlayerData.items)
    end
    
    -- Place the backpack on the ground
    TriggerClientEvent('wd_backpacks:client:placeBackpack', src, itemData.info.model, itemData.info.stashId)
end)

-- Remove Backpack Item
RegisterServerEvent('wd_backpacks:server:removeBackpackItem')
AddEventHandler('wd_backpacks:server:removeBackpackItem', function(model, stashId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    Player.Functions.RemoveItem('backpack', 1, false, { model = model, stashId = stashId })
end)

-- Add Backpack Item
RegisterServerEvent('wd_backpacks:server:addBackpackItem')
AddEventHandler('wd_backpacks:server:addBackpackItem', function(model, stashId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    Player.Functions.AddItem('backpack', 1, false, { model = model, stashId = stashId })
end)

-- Check if Backpack is Empty
RegisterServerEvent('wd_backpacks:server:checkBackpackEmpty')
AddEventHandler('wd_backpacks:server:checkBackpackEmpty', function(stashId, callback)
    local src = source
    local isEmpty = true
    
    -- Check if the backpack stash has any items
    TriggerEvent('inventory:server:GetStashItems', stashId, function(stashItems)
        for _, item in pairs(stashItems) do
            if item.amount > 0 then
                isEmpty = false
                break
            end
        end
        
        callback(isEmpty)
    end)
end)