BUInv = BUInv or {}

PACK_FLAVORS = {
    ["BundleUp.BlueberrySP"]    = "SodaBlueberry",
    ["BundleUp.BubblegumSP"]    = "SodaBubblegum",
    ["BundleUp.LimeSP"]         = "SodaLime",
    ["BundleUp.OrangeSP"]       = "SodaPop",
    ["BundleUp.GrapeSP"]        = "SodaGrape",
    ["BundleUp.PineappleSP"]    = "SodaPineapple",
    ["BundleUp.StrawberrySP"]   = "SodaStrawberry",
}

---@param craftRecipeData CraftRecipeData
---@param character IsoGameCharacter
function BUInv.unpackSodaPack(craftRecipeData, character)
    local sodaPack = craftRecipeData:getAllConsumedItems():get(0)
    local sodaFluid = PACK_FLAVORS[sodaPack:getFullType()]

    local sodaType = Fluid.Get(sodaFluid)
    local outputItems = craftRecipeData:getAllCreatedItems()

    -- put the soda in the cans
    for i = 0, outputItems:size() - 1 do
        local can = outputItems:get(i)
        local fluidContainer = can:getFluidContainer()
        fluidContainer:Empty()
        fluidContainer:addFluid(sodaType, 1.0)
        can:setColor(sodaType:getColor())
    end
end
