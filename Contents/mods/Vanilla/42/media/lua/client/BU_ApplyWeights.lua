----------
--ESTRAL--
----------

require "BU_WeightData"

local MIN_WEIGHT = 0.01

local function reductionFor(fullType, def, sv)
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
            local raw = baseItem:getActualWeight() * def.count
            local weight = raw * (1 - reductionFor(fullType, def, sv) / 100)
            if weight < MIN_WEIGHT then weight = MIN_WEIGHT end
            bundle:setActualWeight(weight)
        end
    end
end

Events.OnGameStart.Add(BU.applyWeights)

local function onFillInventoryContextMenu(playerNum, context, items)
    if not isAdmin() then return end
    context:addOption(getText("ContextMenu_BU_ReapplyWeights"), nil, function()
        BU.applyWeights()
    end)
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)
