----------
--ESTRAL--
----------

require "BU_WeightData"

-- Perishable packs are Food, so the engine owns their spoilage clock and there
-- is no per-tick hook left to scale. CartonSpoilRate therefore has to be spent
-- up front, by stretching the rot thresholds the engine will later count
-- against: half rate means twice the days.
--
-- 0% has to mean "never rots" rather than "rots instantly", so it maps to a
-- ceiling far past any survivable run instead of dividing by zero.
local NEVER_ROTS = 100000

BU.PackRot = BU.PackRot or {}

local function BU_spoilScale()
    local sv = SandboxVars and SandboxVars.BundleUp
    local rate = sv and sv.CartonSpoilRate
    if rate == nil or rate >= 100 then
        return 1.0
    end
    if rate <= 0 then
        return nil
    end
    return 100 / rate
end

function BU.applySpoilage()
    local sm = getScriptManager()
    if not sm then return end

    local scale = BU_spoilScale()

    for fullType in pairs(BU.Bundles) do
        local pack = sm:getItem(fullType)
        -- Only the packs that were given rot data are Food; the rest never
        -- spoiled in the first place and have nothing to stretch.
        if pack and pack:getDaysFresh() > 0 then
            local baseFresh = pack:getDaysFresh()
            local baseRotten = pack:getDaysTotallyRotten()

            -- Re-deriving from the current value would compound every time this
            -- runs, so the shipped numbers are remembered once and scaled from.
            local original = BU.PackRot[fullType]
            if original == nil then
                original = { fresh = baseFresh, rotten = baseRotten }
                BU.PackRot[fullType] = original
            end

            if scale == nil then
                pack:setDaysFresh(NEVER_ROTS)
                pack:setDaysTotallyRotten(NEVER_ROTS)
            else
                pack:setDaysFresh(original.fresh * scale)
                pack:setDaysTotallyRotten(original.rotten * scale)
            end
        end
    end
end

Events.OnGameStart.Add(BU.applySpoilage)
