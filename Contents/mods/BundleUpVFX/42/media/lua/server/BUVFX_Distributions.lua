----------
--ESTRAL--
----------

require "BUProceduralDistributions"
require "BUVFX_WeightData"

if not (BU and BU.addLoot and BUVFX and BUVFX.Loot) then return end

for i = 1, #BUVFX.Loot do
    local entry = BUVFX.Loot[i]
    BU.addLoot(entry.option, entry.items, entry.weights)
end
