----------
--ESTRAL--
----------

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

function BUInv.testPackBlueberrySodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaBlueberry")
end

function BUInv.testPackBubblegumSodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaBubblegum")
end

function BUInv.testPackLimeSodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaLime")
end

function BUInv.testPackOrangeSodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaPop")
end

function BUInv.testPackGrapeSodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaGrape")
end

function BUInv.testPackPineappleSodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaPineapple")
end

function BUInv.testPackStrawberrySodaCan(item, character)
    return BU_isCanOfFlavor(item, "SodaStrewberry")
end

local function BU_worstFoodAge(items)
    local worst = nil
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it:IsFood() then
            local age = it:getAge()
            if worst == nil or age > worst then
                worst = age
            end
        end
    end
    return worst
end

function BUInv.packPerishable(craftRecipeData, character)
    local worst = BU_worstFoodAge(craftRecipeData:getAllConsumedItems())
    if worst == nil then
        return
    end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local pack = created:get(i)
        if pack then
            pack:getModData().buFoodAge = worst
        end
    end
end

function BUInv.unpackPerishable(craftRecipeData, character)
    local consumed = craftRecipeData:getAllConsumedItems()
    local age = nil
    for i = 0, consumed:size() - 1 do
        local pack = consumed:get(i)
        if pack and pack:getModData().buFoodAge ~= nil then
            age = pack:getModData().buFoodAge
            break
        end
    end
    if age == nil then
        return
    end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local food = created:get(i)
        if food and food:IsFood() then
            food:setAge(age)
        end
    end
end
