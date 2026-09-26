----------
--ESTRAL--
----------

require "BU_WeightData"

local MIN_WEIGHT = 0.01
local MAX_WEIGHT = 40

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

-- a nested pack reads its base's weight, so bases have to be patched first.
local function BU_sortedBundles()
    local count = 0
    for _ in pairs(BU.Bundles) do count = count + 1 end
    if BU_order and BU_orderSource == BU.Bundles and BU_orderCount == count then
        return BU_order
    end

    local order, depth = {}, {}
    for fullType in pairs(BU.Bundles) do
        order[#order + 1] = fullType
        depth[fullType] = BU.nestingDepth(fullType)
    end
    table.sort(order, function(a, b)
        if depth[a] ~= depth[b] then return depth[a] < depth[b] end
        return a < b
    end)

    BU_order, BU_orderSource, BU_orderCount = order, BU.Bundles, count
    return order
end

function BU.applyWeights()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv then return end

    local sm = getScriptManager()
    if not sm then return end

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
            bundle:setActualWeight(weight)
        end
    end
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
