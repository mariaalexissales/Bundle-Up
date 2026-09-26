----------
--ESTRAL--
----------

require "TimedActions/ISConsolidateDrainable"

local BU_vanillaComplete = ISConsolidateDrainable.complete
local BU_vanillaRunAgain = ISConsolidateDrainable.runAgain

-- perform chains before complete() nils a poured-dry source, so vanilla pours into a spool
-- about to be deleted and the queue resets. take vanilla's last branch: pour into this one.
function ISConsolidateDrainable:runAgain(drainable, intoItem)
    if intoItem and intoItem == self.drainable and self.fromTarget <= 0.0001 then
        return BU_vanillaRunAgain(self, self:nextItem(), drainable)
    end
    return BU_vanillaRunAgain(self, drainable, intoItem)
end

-- a server pour ends on a timer, not on its last update, so the lerp stops short or runs past 1
-- and the clamp at full eats the source. land both spools on the targets new() worked out.
function ISConsolidateDrainable:complete()
    self.drainable:setUsedDelta(self.fromTarget)
    self.intoItem:setUsedDelta(self.intoTarget)
    if isServer() then
        sendItemStats(self.drainable)
        sendItemStats(self.intoItem)
    end
    return BU_vanillaComplete(self)
end
