----------
--ESTRAL--
----------

require "BU_WeightData"

local MIN_WEIGHT = 0.01
local MAX_WEIGHT = 40
local WEIGHT_EPSILON = 0.0001
local SETTLE_DELAY_TICKS = 180

local function BU_reductionFor(fullType, def, sv)
    local short = fullType:match("%.(.+)$") or fullType
    local per = sv["Item_" .. short]
    if per and per >= 0 then return per end

    local built = BU.BaseReduction and BU.BaseReduction[def.base]
    if built then return built end

    local baseType = BU.resolveBase(fullType) or def.base
    local catVar = BU.BaseCategory[baseType]
    if catVar then
        local v = sv[catVar]
        if v and v >= 0 then return v end
    end

    return sv.ReductionDefault or 0
end

local BU_order, BU_orderSource, BU_orderCount = nil, nil, 0

-- a nested pack reads its base's weight, so bases have to be patched first. bucketed because
-- kahlua's table.sort is a recursive quicksort and the add-on rows overflow its stack.
local function BU_sortedBundles()
    local count = 0
    for _ in pairs(BU.Bundles) do count = count + 1 end
    if BU_order and BU_orderSource == BU.Bundles and BU_orderCount == count then
        return BU_order
    end

    local byDepth, deepest = {}, 0
    for fullType in pairs(BU.Bundles) do
        local depth = BU.nestingDepth(fullType)
        local bucket = byDepth[depth]
        if not bucket then
            bucket = {}
            byDepth[depth] = bucket
        end
        bucket[#bucket + 1] = fullType
        if depth > deepest then deepest = depth end
    end

    local order = {}
    for depth = 0, deepest do
        local bucket = byDepth[depth]
        if bucket then
            for i = 1, #bucket do order[#order + 1] = bucket[i] end
        end
    end

    BU_order, BU_orderSource, BU_orderCount = order, BU.Bundles, count
    return order
end

function BU.applyWeights()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv then return 0 end

    local sm = getScriptManager()
    if not sm then return 0 end

    local changed = 0
    local order = BU_sortedBundles()
    for i = 1, #order do
        local fullType = order[i]
        local def = BU.Bundles[fullType]
        local bundle = sm:getItem(fullType)
        local baseItem = sm:getItem(def.base)
        if bundle and baseItem then
            -- a fluid pack is weighed full: the can and the litres it holds, at 1kg
            -- each. an empty pack of the same can simply leaves fluid unset.
            local raw = (baseItem:getActualWeight() + (def.fluid or 0)) * def.count
            local weight = raw * (1 - BU_reductionFor(fullType, def, sv) / 100)
            if weight < MIN_WEIGHT then weight = MIN_WEIGHT end
            if weight > MAX_WEIGHT then weight = MAX_WEIGHT end
            if math.abs(bundle:getActualWeight() - weight) > WEIGHT_EPSILON then
                bundle:setActualWeight(weight)
                changed = changed + 1
            end
        end
    end
    return changed
end

-- an item copies the script weight when built, so saved ones get restamped. no
-- setCustomWeight on purpose: the next sandbox change has to reach them too.
function BU.refreshWeight(item)
    if not item or not BU.Bundles[item:getFullType()] then
        return
    end

    local sm = getScriptManager()
    local script = sm and sm:getItem(item:getFullType())
    if not script then
        return
    end

    -- another weight mod may have frozen a stale value into the item; it would reload over the script.
    if item.isCustomWeight and item:isCustomWeight() then
        item:setCustomWeight(false)
    end

    item:setActualWeight(script:getActualWeight())
    item:setWeight(script:getActualWeight())
end

-- OnInitGlobalModData is the only event after the sandbox loads and before any inventory
-- does. the other two are re-runs. guarded so a build without it keeps the rest.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU.applyWeights)
end
Events.OnGameStart.Add(BU.applyWeights)
Events.OnServerStarted.Add(BU.applyWeights)

-- weight mods rewrite script weights on their own schedule, some of it after the passes above
-- and in no order we can see. check again once things settle, then hourly. a pass that finds
-- nothing wrong writes nothing.
local BU_settled = false
local BU_settleTicks = nil

local function BU_settle()
    local changed = BU.applyWeights()
    if (changed > 0 or not BU_settled) and BU.onWeightsChanged then
        BU.onWeightsChanged()
    end
    BU_settled = true
end

local function BU_settleTick()
    BU_settleTicks = BU_settleTicks + 1
    if BU_settleTicks < SETTLE_DELAY_TICKS then return end

    BU_settleTicks = nil
    Events.OnTick.Remove(BU_settleTick)
    BU_settle()
end

local function BU_armSettle()
    if BU_settleTicks then return end

    BU_settleTicks = 0
    Events.OnTick.Add(BU_settleTick)
end

Events.OnGameStart.Add(BU_armSettle)
Events.OnServerStarted.Add(BU_armSettle)
if Events.EveryHours then
    Events.EveryHours.Add(BU_settle)
end
