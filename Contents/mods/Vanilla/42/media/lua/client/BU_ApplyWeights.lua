----------
--ESTRAL--
----------

require "BU_WeightData"

local MIN_WEIGHT = 0.01

local function BU_reductionFor(fullType, def, sv)
    local short = fullType:match("%.(.+)$") or fullType
    local per = sv["Item_" .. short]
    if per and per >= 0 then return per end

    local baseType = BU.resolveBase(fullType) or def.base
    local catVar = BU.BaseCategory[baseType]
    if catVar then
        local v = sv[catVar]
        if v and v >= 0 then return v end
    end

    return sv.ReductionDefault or 0
end

function BU.applyWeights()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv then return end

    local sm = getScriptManager()
    if not sm then return end

    -- A nested pack reads its base's weight, so the base has to be final
    -- first. Depth is measured once up front rather than per comparison.
    local order, depth = {}, {}
    for fullType in pairs(BU.Bundles) do
        order[#order + 1] = fullType
        depth[fullType] = BU.nestingDepth(fullType)
    end
    table.sort(order, function(a, b)
        if depth[a] ~= depth[b] then return depth[a] < depth[b] end
        return a < b
    end)

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
            bundle:setActualWeight(weight)
        end
    end
end

-- an item copies the script weight when it is built, so one restored from a
-- save predates the patch below and has to be restamped. deliberately no
-- setCustomWeight: leaving it unset keeps the weight script-derived, so the
-- next sandbox change still reaches bundles already sitting in a save.
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

-- OnInitGlobalModData is the first event to fire after SandboxOptions.load(),
-- and it lands before the cell deserializes any inventory, so a saved bundle is
-- built from an already-patched script item. OnGameStart is far too late for
-- that; it stays on as a harmless re-run. Guarded so a build missing the event
-- degrades instead of taking the whole file down.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU.applyWeights)
end
Events.OnGameStart.Add(BU.applyWeights)
