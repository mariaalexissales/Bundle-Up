----------
--ESTRAL--
----------

require "TimedActions/ISInventoryTransferAction"
require "BUpacking"

-- Settle before the move, never after. A pack is charged for its span at
-- whatever container it is sitting in, so it has to be closed out while it is
-- still in the fridge; settling afterwards would bill the fridge span to the
-- backpack and throw away the discount the pack actually earned.
--
-- Both containers get settled, not just the item. Reaching into a fridge that
-- has since lost power is when its contents stop being refrigerated, and the
-- reach is the only notice we get.
local BU_perform = ISInventoryTransferAction.perform

function ISInventoryTransferAction:perform()
    local now = BU.worldAgeHours()
    BU.settleContainer(self.srcContainer, now)
    BU.settleContainer(self.destContainer, now)
    BU.settleItem(self.item, now)

    BU_perform(self)
end

-- A pack that is only sitting there never moves, so the transfer hook never fires
-- and its age never advances off the timestamp it was put away with. Reading it
-- back would still compute the right number, but nothing was reading it, which
-- made cold storage look like it did nothing at all.
--
-- Sweeping the whole world for packs would cost far more than the feature is
-- worth. What a player can actually see is what they are carrying and what they
-- are standing in front of, so that is the whole search.
local function BU_settleWatched()
    local now = BU.worldAgeHours()
    if not now then
        return
    end

    for playerNum = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerNum)
        if player then
            BU.settleContainer(player:getInventory(), now)

            local loot = getPlayerLoot(playerNum)
            if loot and loot.backpacks then
                for _, backpack in ipairs(loot.backpacks) do
                    BU.settleContainer(backpack.inventory, now)
                end
            end
        end
    end
end

Events.EveryTenMinutes.Add(BU_settleWatched)
