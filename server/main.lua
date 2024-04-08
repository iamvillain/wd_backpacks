RSGCore = exports['rsg-core']:GetCoreObject()
-- Check if the table exists
local tableExists = exports.oxmysql:query("SHOW TABLES LIKE 'bag_positions'", function(data)
    if data and #data > 0 then
        print("[wd_backpacks] Table exists, you're good to go!")
    else
        -- If the table doesn't exist, create it
        exports.oxmysql:execute([[
            CREATE TABLE IF NOT EXISTS `bag_positions` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `model` VARCHAR(50) NOT NULL,
                `pos_x` FLOAT NOT NULL,
                `pos_y` FLOAT NOT NULL,
                `pos_z` FLOAT NOT NULL,
                `heading` FLOAT NOT NULL,
                `stash_id` VARCHAR(100) NOT NULL
            )
        ]], {})
        print("[wd_backpacks] Table 'bag_positions' created successfully.")
    end
end)
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

-- Save Bag Position
RegisterServerEvent('wd_backpacks:server:saveBagPosition')
AddEventHandler('wd_backpacks:server:saveBagPosition', function(model, x, y, z, heading, stashId)
    MySQL.Async.execute('INSERT INTO bag_positions (model, pos_x, pos_y, pos_z, heading, stash_id) VALUES (?, ?, ?, ?, ?, ?)', {model, x, y, z, heading, stashId})
end)

-- Remove Bag Position
RegisterServerEvent('wd_backpacks:server:removeBagPosition')
AddEventHandler('wd_backpacks:server:removeBagPosition', function(stashId)
    MySQL.Async.execute('DELETE FROM bag_positions WHERE stash_id = ?', {stashId})
end)

-- Get Bag Positions
RegisterServerEvent('wd_backpacks:server:getBagPositions')
AddEventHandler('wd_backpacks:server:getBagPositions', function()
    local src = source
    
    MySQL.Async.fetchAll('SELECT * FROM bag_positions', {}, function(result)
        TriggerClientEvent('wd_backpacks:client:spawnBags', src, result)
    end)
end)
