----------
--ESTRAL--
----------

require "BU_ApplyWeights"
require "BU_Watched"

-- patching the scripts only reaches items built after the patch, so anything
-- already in hand has to be restamped in the same pass or the option lies.
local function BU_reapplyWeights()
    BU.applyWeights()
    BU.forEachWatchedItem(BU.refreshWeight)
end

local function BU_onFillInventoryContextMenu(playerNum, context, items)
    if not isAdmin() then return end
    context:addOption(getText("ContextMenu_BU_ReapplyWeights"), nil, BU_reapplyWeights)
end
Events.OnFillInventoryObjectContextMenu.Add(BU_onFillInventoryContextMenu)
