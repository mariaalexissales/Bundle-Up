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

-- Vanilla's Refrigeration Effectiveness, 1 "Very Low" through 6 "No decay", so a
-- packed carton slows by whatever the player already set for the loose food next
-- to it. The divisors themselves live in Java and had to be matched by eye.
local FRIDGE_RATE = { 0.75, 0.5, 0.33, 0.2, 0.1, 0.0 }
local DEFAULT_FRIDGE_FACTOR = 3

-- Food keeps hoursToFreeze and hoursToThaw to itself, so these mirror it from
-- the outside.
local HOURS_TO_FREEZE = 24
local HOURS_TO_THAW = 24
local FROZEN = 100

-- getType is the one form of this check vanilla itself makes from Lua, and a
-- fridge only runs while its square still has power.
local function BU_coldKind(container)
    if not container then
        return nil
    end

    local kind = container:getType()
    if kind ~= "freezer" and kind ~= "fridge" then
        return nil
    end

    local parent = container:getParent()
    local square = parent and parent:getSquare()
    if not square or not square:haveElectricity() then
        return nil
    end
    return kind
end

local function BU_coldRate(item)
    local kind = BU_coldKind(item:getContainer())
    if kind == nil then
        return 1.0
    end
    if kind == "freezer" then
        return 0.0
    end

    local factor = SandboxVars and SandboxVars.FridgeFactor or DEFAULT_FRIDGE_FACTOR
    return FRIDGE_RATE[factor] or FRIDGE_RATE[DEFAULT_FRIDGE_FACTOR]
end

local function BU_inFreezer(item)
    return BU_coldKind(item:getContainer()) == "freezer"
end

local function BU_freezeAfter(freeze, inFreezer, hours)
    if inFreezer then
        freeze = freeze + hours / HOURS_TO_FREEZE * FROZEN
    else
        freeze = freeze - hours / HOURS_TO_THAW * FROZEN
    end

    if freeze < 0 then
        return 0
    end
    if freeze > FROZEN then
        return FROZEN
    end
    return freeze
end

-- Food carries its own age; a pack carries the age it was sealed at plus the
-- time since, at the rate the cold storage it was sealed into was running.
-- Reading both the same way lets a pack sit anywhere in a chain.
local function BU_effectiveAge(item, now)
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
    if packedAt ~= nil and now ~= nil and now > packedAt then
        local rate = modData.buColdRate or 1.0
        age = age + (now - packedAt) * rate * BU_spoilRate()
    end
    return age
end

local function BU_effectiveFreeze(item, now)
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
    if packedAt ~= nil and now ~= nil and now > packedAt then
        freeze = BU_freezeAfter(freeze, modData.buInFreezer, now - packedAt)
    end
    return freeze
end

-- Where the clock actually moves. Closing the span at the rate it was opened at
-- is what lets a pack cross from a freezer to a backpack without the fridge
-- discount leaking backwards or forwards over the move.
function BU.settleItem(item, now)
    if not item or item:IsFood() then
        return
    end

    local modData = item:getModData()
    if modData.buFoodAge == nil then
        return
    end

    modData.buFoodAge = BU_effectiveAge(item, now)
    modData.buFreezeTime = BU_effectiveFreeze(item, now)
    modData.buPackedAt = now
    modData.buColdRate = BU_coldRate(item)
    modData.buInFreezer = BU_inFreezer(item)
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
        item:setFreezingTime(freeze)
        item:setFrozen(freeze >= FROZEN)
        return
    end

    local modData = item:getModData()
    modData.buFoodAge = age
    modData.buFreezeTime = freeze
    modData.buPackedAt = now
    modData.buColdRate = BU_coldRate(item)
    modData.buInFreezer = BU_inFreezer(item)
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

-- A pack is only as frozen as its least frozen contents, or one warm carton
-- would come back out of a case fully frozen.
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

-- Whether an age counts as rotten is the base item's business, so ask a spare
-- copy of it rather than reimplementing the thresholds here.
local rotProbes = {}

local function BU_isAgeRotten(baseType, age)
    if baseType == nil or age == nil then
        return false
    end

    local probe = rotProbes[baseType]
    if probe == nil then
        probe = InventoryItemFactory.CreateItem(baseType) or false
        rotProbes[baseType] = probe
    end
    if not probe or not probe:IsFood() then
        return false
    end

    probe:setAge(age)
    return probe:isRotten()
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
    local freeze = BU_effectiveFreeze(item, now)
    if freeze ~= nil and freeze >= FROZEN then
        return true
    end

    local baseType = BU.resolveBase(item:getFullType())
    return not BU_isAgeRotten(baseType, BU_effectiveAge(item, now))
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
