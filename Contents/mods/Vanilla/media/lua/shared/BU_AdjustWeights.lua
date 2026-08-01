----------
--ESTRAL--
----------

require "BU_WeightData"

local MIN_WEIGHT = 0.01

local function reductionFor(fullType, def, sv)
    local short = fullType:match("%.(.+)$") or fullType
    local per = sv["Item_" .. short]
    if per and per >= 0 then return per end

    local catVar = BU.BaseCategory[def.base]
    if catVar then
        local v = sv[catVar]
        if v and v >= 0 then return v end
    end

    return sv.ReductionDefault or 0
end

local function applyOne(fullType, def, sv)
    local bundle = ScriptManager.instance:getItem(fullType)
    local baseItem = ScriptManager.instance:getItem(def.base)
    if not bundle or not baseItem then
        print("[BundleUp] missing item, skipping weight for " .. tostring(fullType))
        return
    end

    local weight = baseItem:getActualWeight() * def.count
    weight = weight * (1 - reductionFor(fullType, def, sv) / 100)
    if weight < MIN_WEIGHT then weight = MIN_WEIGHT end

    bundle:DoParam(string.format("Weight = %.4f", weight))
end

function BU.applyWeights()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv then return end

    for fullType, def in pairs(BU.Bundles) do
        local ok, err = pcall(applyOne, fullType, def, sv)
        if not ok then
            print("[BundleUp] failed to set weight for " .. tostring(fullType) .. ": " .. tostring(err))
        end
    end
end

Events.OnGameTimeLoaded.Add(BU.applyWeights)
