----------
--ESTRAL--
----------

require "TimedActions/ISInventoryTransferAction"
require "BUpacking"

-- A pack changes rate when it changes container, and it only changes container
-- because someone moved it. Settling after the move closes the old span at the
-- old rate and opens the new one at the rate where it landed.
--
-- Both ends of the move get settled, not just the item: opening a fridge that
-- has since lost power is the one way a pack's stored rate goes stale without
-- the pack itself moving, and reaching into it is when that starts to matter.
local BU_perform = ISInventoryTransferAction.perform

function ISInventoryTransferAction:perform()
    BU_perform(self)

    local now = BU.worldAgeHours()
    BU.settleContainer(self.srcContainer, now)
    BU.settleContainer(self.destContainer, now)
    BU.settleItem(self.item, now)
end
