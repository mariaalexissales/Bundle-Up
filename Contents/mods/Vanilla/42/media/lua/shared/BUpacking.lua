BUInv = BUInv or {}

PACK_FLAVORS = {
    ["BundleUp.BlueberrySP"]    = "SodaBlueberry",
    ["BundleUp.BubblegumSP"]    = "SodaBubblegum",
    ["BundleUp.LimeSP"]         = "SodaLime",
    ["BundleUp.OrangeSP"]       = "SodaPop",
    ["BundleUp.GrapeSP"]        = "SodaGrape",
    ["BundleUp.PineappleSP"]    = "SodaPineapple",
    ["BundleUp.StrawberrySP"]   = "SodaStrewberry",
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
