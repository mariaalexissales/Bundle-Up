----------
--ESTRAL--
----------

require "BU_ApplySpoilage"
require "BU_Watched"

-- only watched packs convert. one in a crate nobody opens converts later at no cost,
-- age accrues the same whatever the thresholds say.
Events.EveryTenMinutes.Add(function()
    BU.forEachWatchedItem(BU.refreshPack)
end)
