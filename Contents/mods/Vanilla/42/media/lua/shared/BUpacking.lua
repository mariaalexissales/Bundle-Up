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

-- Food carries its own age; a pack carries the age it was sealed at plus the
-- time since. Reading both the same way lets a pack sit anywhere in a chain.
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
        age = age + (now - packedAt) * BU_spoilRate()
    end
    return age
end

local function BU_stampAge(item, age, now)
    if not item then
        return
    end
    if item:IsFood() then
        item:setAge(age)
        if now ~= nil then
            item:setLastAged(now)
        end
        return
    end

    local modData = item:getModData()
    modData.buFoodAge = age
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

    local baseType = BU.resolveBase(item:getFullType())
    return not BU_isAgeRotten(baseType, BU_effectiveAge(item, BU.worldAgeHours()))
end

-- Packing and unpacking are the same move in opposite directions: take the
-- oldest thing going in and stamp that age onto everything coming out.
function BUInv.carryFoodAge(craftRecipeData, character)
    local now = BU.worldAgeHours()
    local worst = BU_worstAge(craftRecipeData:getAllConsumedItems(), now)
    if worst == nil then
        return
    end

    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        BU_stampAge(created:get(i), worst, now)
    end
end
