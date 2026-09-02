----------
--ESTRAL--
----------

require "BU_ApplySpoilage"

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

function BUInv.unpackFullGasCans(craftRecipeData, character)
    local petrol = Fluid.Get("Petrol")
    if not petrol then
        return
    end

    local outputItems = craftRecipeData:getAllCreatedItems()
    for i = 0, outputItems:size() - 1 do
        local can = outputItems:get(i)
        -- the rope comes out in this same list, and has no fluid container
        local fluidContainer = can:getFluidContainer()
        if fluidContainer then
            fluidContainer:Empty()
            fluidContainer:addFluid(petrol, fluidContainer:getCapacity())
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

-- these names are built by string, so grepping for testPackOrangeSodaCan finds
-- nothing. the recipes that call them are in recipes_bundled.txt.
for packType, fluidName in pairs(PACK_FLAVORS) do
    local flavor = packType:match("%.(.+)SP$")
    BUInv["testPack" .. flavor .. "SodaCan"] = function(item, character)
        return BU_isCanOfFlavor(item, fluidName)
    end
end

function BUInv.testPackPerishable(item, character)
    -- isRotten is Food-only. the non-perishable cartons are base:normal, so this
    -- guard is what keeps the handcraft window from dying on them.
    return item == nil or not item:IsFood() or not item:isRotten()
end

function BUInv.testPackEmptyMagazine(item, character)
    return item == nil or item:getCurrentAmmoCount() <= 0
end

local function BU_shelfLife(item)
    local life = item:getOffAgeMax()
    if life == nil or life <= 0 then
        return nil
    end
    return life
end

function BUInv.carryFoodAge(craftRecipeData, character)
    local consumed = craftRecipeData:getAllConsumedItems()

    local oldest, softest, oldestRank = nil, nil, nil
    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        if item and item:IsFood() then
            BU.refreshPack(item)

            local life = BU_shelfLife(item)
            local rank = life and (item:getAge() / life) or item:getAge()
            if oldestRank == nil or rank > oldestRank then
                oldest, oldestRank = item, rank
            end
            if softest == nil or item:getFreezingTime() < softest:getFreezingTime() then
                softest = item
            end
        end
    end
    if oldest == nil then
        return
    end

    local sourceLife = BU_shelfLife(oldest)
    local now = BU.worldAgeHours()
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local item = created:get(i)
        if item and item:IsFood() then
            -- a carton's rot thresholds are stretched by the spoilage rate and its
            -- contents' are not, so raw days leak the stretch across the boundary.
            -- carry the fraction of shelf life instead.
            local life = BU_shelfLife(item)
            local age = oldest:getAge()
            if life and sourceLife then
                age = age * (life / sourceLife)
            end

            item:setAge(age)
            if now ~= nil then
                item:setLastAged(now)
            end
            -- new Food has lastFrozenUpdate = 0, so stamping freeze first gets it
            -- melted on the next tick. updateAge sets the timestamp.
            item:updateAge()
            item:copyFrozenFrom(softest)
        end
    end
end
