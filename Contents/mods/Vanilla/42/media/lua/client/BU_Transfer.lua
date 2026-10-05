----------
--ESTRAL--
----------

require "TimedActions/ISInventoryTransferAction"

BU = BU or {}

function BU.sendBack(player, item, container)
    -- not the util factory: item arrange swaps in its own action for floor drops while shift is held.
    local action = ISInventoryTransferAction:new(
        player, item, player:getInventory(), container, nil)
    -- whatever was poured dry is gone by now, so the transfer has to tolerate it.
    action:setAllowMissingItems(true)
    ISTimedActionQueue.add(action)
end

function BU.noteHome(player, homes, item)
    local container = item:getContainer()
    if not container or container == player:getInventory() then return homes end

    homes = homes or {}
    for _, home in ipairs(homes) do
        if home.item == item then return homes end
    end
    homes[#homes + 1] = { item = item, container = container }
    return homes
end

function BU.sendHomes(player, homes)
    for _, home in ipairs(homes or {}) do
        BU.sendBack(player, home.item, home.container)
    end
end
