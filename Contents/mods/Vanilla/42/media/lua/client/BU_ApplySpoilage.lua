----------
--ESTRAL--
----------

require "BU_WeightData"

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
        if pack and pack:IsFood() and pack:getDaysFresh() > 0 then
            -- scale off the remembered values, not the current ones, or every
            -- re-run multiplies the last run's result.
            local original = BU.PackRot[fullType]
            if original == nil then
                original = { fresh = pack:getDaysFresh(), rotten = pack:getDaysTotallyRotten() }
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
