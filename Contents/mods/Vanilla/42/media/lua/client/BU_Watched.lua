----------
--ESTRAL--
----------

require "BU_WeightData"

local function BU_applyToContainer(container, fn)
    if not container then
        return
    end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        fn(items:get(i))
    end
end

-- every player's own inventory plus whatever loot container they have open --
-- the items the UI is asking about right now, and the only ones worth walking.
function BU.forEachWatchedItem(fn)
    for playerNum = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerNum)
        if player then
            BU_applyToContainer(player:getInventory(), fn)

            local loot = getPlayerLoot(playerNum)
            if loot and loot.backpacks then
                for _, backpack in ipairs(loot.backpacks) do
                    BU_applyToContainer(backpack.inventory, fn)
                end
            end
        end
    end
end
