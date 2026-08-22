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
