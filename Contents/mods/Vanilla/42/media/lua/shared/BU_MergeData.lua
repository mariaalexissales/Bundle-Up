----------
--ESTRAL--
----------

BU = BU or {}
BU.Merge = BU.Merge or {}

-- powered or refillable kit that happens to be a drainable. pouring one flashlight
-- into another reads as nonsense, and the gas bottles have their own refill flow.
BU.Merge.Deny = {
    ["Base.BlowTorch"]       = true,
    ["Base.Bullhorn"]        = true,
    ["Base.Extinguisher"]    = true,
    ["Base.Lighter"]         = true,
    ["Base.Lighter_Battery"] = true,
    ["Base.Oxygen_Tank"]     = true,
    ["Base.PropaneTank"]     = true,
    ["Base.Propane_Refill"]  = true,
    ["Base.TestWaterMug"]    = true,
}

BU.Merge.DenyCategory = {
    LightSource        = true,
    VehicleMaintenance = true,
}

-- getMaxUses is floor(1 / useDelta) while getCurrentUsesFloat is uses * useDelta, so
-- anything whose uses do not divide 1.0 evenly reports short of full forever - every
-- lantern, torch and candle. topping one off is a no-op that still costs 90 ticks.
-- java does that multiply in float and lua in double, so the compare needs the slack.
local BU_FULL_SLACK = 0.000001

function BU.Merge.maxUses(item)
    return item:getMaxUses()
end

function BU.Merge.uses(item)
    return item:getCurrentUses()
end

function BU.Merge.canFill(item)
    local delta = item:getUseDelta()
    if not delta or delta <= 0 then
        return false
    end
    return BU.Merge.maxUses(item) * delta >= 1 - BU_FULL_SLACK
end

function BU.Merge.canMerge(item)
    if not item or not instanceof(item, "DrainableComboItem") then
        return false
    end
    if not item:canConsolidate() or BU.Merge.Deny[item:getFullType()] then
        return false
    end

    local script = item:getScriptItem()
    if script and BU.Merge.DenyCategory[script:getDisplayCategory()] then
        return false
    end

    return BU.Merge.canFill(item)
end

local function BU_eachMergeable(containers, fn)
    if not containers then return end

    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        local items = container and container:getItems()
        if items then
            for n = 0, items:size() - 1 do
                local item = items:get(n)
                if BU.Merge.canMerge(item) then
                    fn(item)
                end
            end
        end
    end
end

function BU.Merge.gather(containers, fullType)
    local found = {}
    BU_eachMergeable(containers, function(item)
        if item:getFullType() == fullType then
            found[#found + 1] = item
        end
    end)
    return found
end

function BU.Merge.collect(containers)
    local byType = {}
    BU_eachMergeable(containers, function(item)
        local fullType = item:getFullType()
        local bucket = byType[fullType]
        if not bucket then
            bucket = {}
            byType[fullType] = bucket
        end
        bucket[#bucket + 1] = item
    end)
    return byType
end

-- pours the emptiest into the fullest and walks inward, so every step either finishes a
-- spool or empties one. the pairs are ordered but must be built into actions one at a
-- time: ISConsolidateDrainable reads both levels in its constructor, so a whole chain
-- queued up front would lerp from stale numbers and overwrite the earlier merges.
function BU.Merge.plan(items)
    local pool, total, maxUses = {}, 0, 0

    for _, item in ipairs(items) do
        local uses = BU.Merge.uses(item)
        if uses > 0 then
            maxUses = BU.Merge.maxUses(item)
            total = total + uses
            pool[#pool + 1] = { item = item, uses = uses }
        end
    end

    local steps = {}
    if maxUses > 0 then
        table.sort(pool, function(a, b)
            if a.uses ~= b.uses then return a.uses > b.uses end
            return a.item:getID() < b.item:getID()
        end)

        local head, tail = 1, #pool
        while head < tail do
            local into, from = pool[head], pool[tail]
            if into.uses >= maxUses then
                head = head + 1
            else
                local amount = math.min(maxUses - into.uses, from.uses)
                into.uses = into.uses + amount
                from.uses = from.uses - amount
                steps[#steps + 1] = { from = from.item, into = into.item }
                if from.uses <= 0 then
                    tail = tail - 1
                end
            end
        end
    end

    local full, partial = 0, 0
    for _, slot in ipairs(pool) do
        if slot.uses >= maxUses then
            full = full + 1
        elseif slot.uses > 0 then
            partial = partial + 1
        end
    end

    return {
        steps   = steps,
        full    = full,
        partial = partial,
        removed = #pool - full - partial,
        count   = #pool,
        total   = total,
        maxUses = maxUses,
    }
end
