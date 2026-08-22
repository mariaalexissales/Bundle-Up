----------
--ESTRAL--
----------

require "BU_WeightData"

BU = BU or {}
BUInv = BUInv or {}

PACK_FLAVORS = {
    ["BundleUp.BlueberrySP"]  = "SodaBlueberry",
    ["BundleUp.BubblegumSP"]  = "SodaBubblegum",
    ["BundleUp.LimeSP"]       = "SodaLime",
    ["BundleUp.OrangeSP"]     = "SodaPop",
    ["BundleUp.GrapeSP"]      = "SodaGrape",
    ["BundleUp.PineappleSP"]  = "SodaPineapple",
    ["BundleUp.StrawberrySP"] = "SodaStrewberry",
}

function BU.worldAgeHours()
    local gameTime = getGameTime()
    if not gameTime then return nil end
    return gameTime:getWorldAgeHours()
end

function BUInv.unpackSodaPack(craftRecipeData, character)
    local sodaPack = craftRecipeData:getAllConsumedItems():get(0)
    local sodaFluidName = PACK_FLAVORS[sodaPack:getFullType()]
    if not sodaFluidName then
        return
    end
    local sodaType = Fluid.Get(sodaFluidName)
    if not sodaType then
        return
    end

    local outputItems = craftRecipeData:getAllCreatedItems()
    for i = 0, outputItems:size() - 1 do
        local can = outputItems:get(i)
        local fluidContainer = can:getFluidContainer()
        if fluidContainer then
            fluidContainer:Empty()
            fluidContainer:addFluid(sodaType, 1.0)
            ItemCodeOnCreate.onCreateSodaCan(can)
        end
    end
end

local function BU_isCanOfFlavor(can, fluidName)
    local fluidContainer = can:getFluidContainer()
    if not fluidContainer or not fluidContainer:isFull() then
        return false
    end
    local fluid = fluidContainer:getPrimaryFluid()
    return fluid ~= nil and fluid:getFluidTypeString() == fluidName
end

-- These build the testPack<Flavor>SodaCan names the pack recipes ask for by
-- string, so grepping the Lua for them turns up nothing: see recipes_bundled.txt.
for packType, fluidName in pairs(PACK_FLAVORS) do
    local flavor = packType:match("%.(.+)SP$")
    BUInv["testPack" .. flavor .. "SodaCan"] = function(item, character)
        return BU_isCanOfFlavor(item, fluidName)
    end
end

local function BU_spoilRate()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv or sv.CartonSpoilRate == nil then
        return 1.0
    end
    return sv.CartonSpoilRate / 100
end

-- Read off Food.getFridgeFactor: Refrigeration Effectiveness runs 1 "Very Low"
-- through 6 "No decay", and its switch falls back to case 3.
local FRIDGE_FACTOR = { 0.4, 0.3, 0.2, 0.1, 0.03, 0.0 }
local DEFAULT_FRIDGE_FACTOR = 0.2

-- Food.getFoodRotSpeed, the Food Spoilage setting. Loose food is scaled by this
-- too, so packed food has to be or the two drift apart.
local ROT_SPEED = { 1.7, 1.4, 1.0, 0.7, 0.4 }
local DEFAULT_ROT_SPEED = 1.0

-- Food.updateFreezing: four hours to freeze solid, an hour and a half to thaw,
-- doubled when a powered fridge is doing the thawing and cut to a sixth next to
-- something hot.
local HOURS_TO_FREEZE = 4.0
local THAW_HOURS = 1.5
local FROZEN = 100

-- Ages are in days but the world clock is in hours.
local HOURS_PER_DAY = 24.0

-- What a given age means, and whether a thing can freeze at all, belong to the
-- base item, so ask a spare copy of it rather than reimplementing either here.
local probes = {}

local function BU_probe(baseType)
    if baseType == nil then
        return nil
    end

    local probe = probes[baseType]
    if probe == nil then
        -- Caching the failure as false matters as much as caching the item: a
        -- probe we cannot build must never be retried on every settle, and must
        -- never take a context menu or a container transfer down with it.
        local ok, created = pcall(instanceItem, baseType)
        probe = (ok and created) or false
        probes[baseType] = probe
    end
    if not probe or not probe:IsFood() then
        return nil
    end
    return probe
end

local function BU_isAgeRotten(baseType, age)
    local probe = BU_probe(baseType)
    if probe == nil or age == nil then
        return false
    end

    probe:setAge(age)
    return probe:isRotten()
end

local function BU_canFreeze(item)
    local probe = BU_probe(BU.resolveBase(item:getFullType()))
    return probe ~= nil and probe:canBeFrozen()
end

local function BU_fridgeFactor()
    local factor = SandboxVars and SandboxVars.FridgeFactor
    factor = factor and FRIDGE_FACTOR[factor]
    if factor == nil then
        return DEFAULT_FRIDGE_FACTOR
    end
    return factor
end

local function BU_rotSpeed()
    local speed = SandboxVars and SandboxVars.FoodRotSpeed
    speed = speed and ROT_SPEED[speed]
    if speed == nil then
        return DEFAULT_ROT_SPEED
    end
    return speed
end

-- Vanilla scales a fridge and a freezer by the same factor. What makes a
-- freezer worth more is that its contents eventually freeze solid, and frozen
-- food does not age at all.
local function BU_coldFactor(container)
    if not container then
        return 1.0
    end
    if not container:isFridge() and not container:isFreezer() then
        return 1.0
    end

    local square = container:getSourceGrid()
    if not square or not square:haveElectricity() then
        return 1.0
    end
    return BU_fridgeFactor()
end

local function BU_isFreezing(container)
    return container ~= nil and container:isFreezer() and container:isPowered()
end

local function BU_freezeAfter(freeze, container, freezing, hours)
    if freeze < FROZEN and freezing then
        freeze = freeze + hours / HOURS_TO_FREEZE * FROZEN
    elseif freeze > 0 then
        local thaw = THAW_HOURS
        if container then
            if container:isFridge() and container:isPowered() then
                thaw = thaw * 2
            end
            if container:getTemprature() > 1.0 then
                thaw = thaw / 6
            end
        end
        freeze = freeze - hours / thaw * FROZEN
    end

    if freeze < 0 then
        return 0
    end
    if freeze > FROZEN then
        return FROZEN
    end
    return freeze
end

local function BU_effectiveFreeze(item, now, container)
    if not item then
        return nil
    end
    if item:IsFood() then
        return item:getFreezingTime()
    end

    local modData = item:getModData()
    if modData.buFoodAge == nil then
        return nil
    end

    local freeze = modData.buFreezeTime or 0
    local packedAt = modData.buPackedAt
    if packedAt == nil or now == nil or now <= packedAt then
        return freeze
    end

    container = container or item:getOutermostContainer()
    local freezing = BU_isFreezing(container)

    -- Nothing frozen and nothing freezing answers 0 either way, so do not pay to
    -- build a probe confirming it. That is most packs, most of the time, and it
    -- keeps every ordinary container move from instantiating anything.
    if freeze <= 0 and not freezing then
        return 0
    end
    if not BU_canFreeze(item) then
        return 0
    end

    return BU_freezeAfter(freeze, container, freezing, now - packedAt)
end

-- Food carries its own age; a pack carries the age it was sealed at plus the
-- time since, charged at whatever the storage it is sitting in is worth right
-- now. Reading both the same way lets a pack sit anywhere in a chain.
--
-- The rate is read live rather than remembered, which is what vanilla does and
-- what makes a dead fridge cost its contents the discount rather than keep
-- crediting one that lapsed at some unknowable point in the span.
local function BU_effectiveAge(item, now, container, freeze)
    if not item then
        return nil
    end
    if item:IsFood() then
        return item:getAge()
    end

    local modData = item:getModData()
    local age = modData.buFoodAge
    if age == nil then
        return nil
    end

    local packedAt = modData.buPackedAt
    if packedAt == nil or now == nil or now <= packedAt then
        return age
    end

    container = container or item:getOutermostContainer()
    if freeze == nil then
        freeze = BU_effectiveFreeze(item, now, container)
    end

    -- Vanilla settles freezing before aging and then zeroes the whole delta if
    -- the result is frozen, so a span that ends solid contributes nothing.
    local rate = 0.0
    if freeze == nil or freeze < FROZEN then
        rate = BU_coldFactor(container)
    end

    local hours = (now - packedAt) * rate * BU_spoilRate() * BU_rotSpeed()
    return age + hours / HOURS_PER_DAY
end

-- Where the clock actually moves. Callers settle a pack while it is still in the
-- container it spent the span in, which is why nothing has to be remembered
-- about that container afterwards.
function BU.settleItem(item, now, container)
    if not item or item:IsFood() or not now then
        return
    end

    local modData = item:getModData()
    if modData.buFoodAge == nil then
        return
    end

    container = container or item:getOutermostContainer()
    local freeze = BU_effectiveFreeze(item, now, container)

    modData.buFoodAge = BU_effectiveAge(item, now, container, freeze)
    modData.buFreezeTime = freeze
    modData.buPackedAt = now
end

function BU.settleContainer(container, now)
    if not container or not now then
        return
    end

    local items = container:getItems()
    for i = 0, items:size() - 1 do
        BU.settleItem(items:get(i), now)
    end
end

local function BU_stampAge(item, age, freeze, now)
    if not item then
        return
    end
    if item:IsFood() then
        item:setAge(age)
        if now ~= nil then
            item:setLastAged(now)
        end
        -- A freshly created Food carries no freezing timestamp, so its first
        -- update would charge every hour since the epoch against the stamp and
        -- melt it. Normalising while it is still unfrozen costs nothing, and
        -- setFreezingTime raises the frozen flag itself.
        item:updateAge()
        item:setFreezingTime(freeze)
        return
    end

    local modData = item:getModData()
    modData.buFoodAge = age
    modData.buFreezeTime = freeze
    modData.buPackedAt = now
end

local function BU_worstAge(items, now)
    local worst = nil
    for i = 0, items:size() - 1 do
        local age = BU_effectiveAge(items:get(i), now)
        if age ~= nil and (worst == nil or age > worst) then
            worst = age
        end
    end
    return worst
end

-- A pack is only as frozen as its least frozen contents, or one soft carton
-- would come back out of a case frozen solid.
local function BU_leastFrozen(items, now)
    local least = nil
    for i = 0, items:size() - 1 do
        local freeze = BU_effectiveFreeze(items:get(i), now)
        if freeze ~= nil and (least == nil or freeze < least) then
            least = freeze
        end
    end
    return least
end

-- Loose food answers for itself; a pack answers for what it is holding, or
-- rotten cartons would launder into a fresh-looking case.
function BUInv.testPackPerishable(item, character)
    if not item then
        return true
    end
    if item:IsFood() then
        return not item:isRotten()
    end

    local now = BU.worldAgeHours()
    local container = item:getOutermostContainer()
    local freeze = BU_effectiveFreeze(item, now, container)
    if freeze ~= nil and freeze >= FROZEN then
        return true
    end

    local baseType = BU.resolveBase(item:getFullType())
    return not BU_isAgeRotten(baseType, BU_effectiveAge(item, now, container, freeze))
end

-- Packing and unpacking are the same move in opposite directions: take the
-- oldest thing going in and stamp that age onto everything coming out.
function BUInv.carryFoodAge(craftRecipeData, character)
    local now = BU.worldAgeHours()
    local consumed = craftRecipeData:getAllConsumedItems()
    local worst = BU_worstAge(consumed, now)
    if worst == nil then
        return
    end
    local freeze = BU_leastFrozen(consumed, now) or 0

    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        BU_stampAge(created:get(i), worst, freeze, now)
    end
end
