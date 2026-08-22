----------
--ESTRAL--
----------

require "BUpacking"

-- Packs used to carry their own spoilage clock in modData, because a pack was
-- not Food and nothing else would ever age it. Perishable packs are Food now
-- and the engine owns the clock, so those keys are dead - but a carton already
-- sitting in a save still has them, and dropping them without reading them
-- would hand the player back a pantry of freshly minted food.
--
-- The published build stored buFoodAge in raw world hours, so hours is the only
-- reading worth honouring. Clamping at the rot threshold means the worst a
-- stale carton can come back as is rotten, never absurd.
--
-- This is a one-shot conversion and the whole file is meant to be deleted a
-- release after it ships.
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

-- Only what a player is carrying or standing in front of. A pack nobody has
-- reached for cannot be observed to be wrong, and sweeping the world for a
-- conversion this short-lived would cost more than it is worth.
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
