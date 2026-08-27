----------
--ESTRAL--
----------

require "BU_ApplySpoilage"

-- a pack only converts when the player is carrying it or has its container open.
-- one sitting in a crate nobody opens converts later at no cost, because age
-- accrues the same whatever the thresholds say.
local function BU_refreshContainer(container)
    if not container then
        return
    end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        BU.refreshPack(items:get(i))
    end
end

local function BU_refreshWatched()
    for playerNum = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerNum)
        if player then
            BU_refreshContainer(player:getInventory())

            local loot = getPlayerLoot(playerNum)
            if loot and loot.backpacks then
                for _, backpack in ipairs(loot.backpacks) do
                    BU_refreshContainer(backpack.inventory)
                end
            end
        end
    end
end

Events.EveryTenMinutes.Add(BU_refreshWatched)
