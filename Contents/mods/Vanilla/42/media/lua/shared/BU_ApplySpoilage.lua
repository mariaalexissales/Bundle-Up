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
        if pack and pack:getDaysFresh() > 0 then
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

function BU.spoilTargets(fullType)
    local original = BU.PackRot[fullType]
    if original == nil then
        return nil
    end

    local scale = BU_spoilScale()
    if scale == nil then
        return NEVER_ROTS, NEVER_ROTS
    end
    return original.fresh * scale, original.rotten * scale
end

function BU.refreshPack(item)
    if not item or not item:IsFood() then
        return
    end

    local fresh, rotten = BU.spoilTargets(item:getFullType())
    if fresh == nil then
        return
    end

    local current = item:getOffAgeMax()
    if current == nil or current <= 0 or math.abs(current - rotten) < 0.001 then
        return
    end

    -- settle the age under the old thresholds first, or the days since lastAged
    -- get counted at the new scale.
    item:updateAge()
    item:setAge(item:getAge() * (rotten / current))
    item:setOffAge(fresh)
    item:setOffAgeMax(rotten)
end

Events.OnGameStart.Add(BU.applySpoilage)
Events.OnServerStarted.Add(BU.applySpoilage)
