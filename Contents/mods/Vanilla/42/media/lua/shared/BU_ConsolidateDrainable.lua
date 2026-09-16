----------
--ESTRAL--
----------

require "TimedActions/ISConsolidateDrainable"

local BU_vanillaComplete = ISConsolidateDrainable.complete

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
