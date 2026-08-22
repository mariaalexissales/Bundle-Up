----------
--ESTRAL--
----------

require "BUpacking"

-- one-shot conversion of the old modData clock. delete this file a release
-- after it ships.
--
-- buFoodAge is in hours, not days - that was the bug. don't drop the /24.
local HOURS_PER_DAY = 24.0

local function BU_migratePack(item)
    if not item or not item:IsFood() then
        return
    end

    local modData = item:getModData()
    local hours = modData.buFoodAge
    if hours == nil then
        return
    end

    local days = hours / HOURS_PER_DAY
    local rotten = item:getOffAgeMax()
    if rotten and rotten > 0 and days > rotten then
        days = rotten
    end

    item:setAge(days)
    item:setLastAged(BU.worldAgeHours())
    item:updateAge()
    if modData.buFreezeTime then
        item:setFreezingTime(modData.buFreezeTime)
    end

    modData.buFoodAge = nil
    modData.buPackedAt = nil
    modData.buFreezeTime = nil
end

local function BU_migrateContainer(container)
    if not container then
        return
    end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        BU_migratePack(items:get(i))
    end
end

local function BU_migrateWatched()
    for playerNum = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerNum)
        if player then
            BU_migrateContainer(player:getInventory())

            local loot = getPlayerLoot(playerNum)
            if loot and loot.backpacks then
                for _, backpack in ipairs(loot.backpacks) do
                    BU_migrateContainer(backpack.inventory)
                end
            end
        end
    end
end

Events.EveryTenMinutes.Add(BU_migrateWatched)
