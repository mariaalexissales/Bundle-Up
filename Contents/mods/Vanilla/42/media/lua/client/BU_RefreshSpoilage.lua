----------
--ESTRAL--
----------

require "BU_ApplySpoilage"
require "BU_Watched"

-- a pack only converts when the player is carrying it or has its container open.
-- one sitting in a crate nobody opens converts later at no cost, because age
-- accrues the same whatever the thresholds say.
Events.EveryTenMinutes.Add(function()
    BU.forEachWatchedItem(BU.refreshPack)
end)
