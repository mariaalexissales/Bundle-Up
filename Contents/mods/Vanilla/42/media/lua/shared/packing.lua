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

local PACK_FLAVORS_REVERSE = {}
for itemType, fluidName in pairs(PACK_FLAVORS) do
    PACK_FLAVORS_REVERSE[fluidName] = itemType
end

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

---@param craftRecipeData CraftRecipeData
---@param character IsoGameCharacter
function BUInv.packSodaPack(craftRecipeData, character)
    local sodaCan = craftRecipeData:getAllConsumedItems():get(0)

    local fluidContainer = sodaCan:getFluidContainer()
    if not fluidContainer then
        return
    end

    local fluid = fluidContainer:getPrimaryFluid()
    if not fluid then
        return
    end

    local packType = PACK_FLAVORS_REVERSE[fluid:getFluidTypeString()]
    if not packType then
        return
    end

    local inventory = character:getInventory()
    local sodaPack = inventory:AddItem(packType)
    return sodaPack
end

---@param item InventoryItem
---@param character IsoGameCharacter
---@return boolean logicTestResult
function BUInv.testPackSodaCan(item, character)
    local fluidContainer = item:getFluidContainer()
    if not fluidContainer then
        return false
    end

    local fluid = fluidContainer:getPrimaryFluid()
    if not fluid then
        return false
    end
    local sodaType = fluid:getFluidType()

    local inventory = character:getInventory()
    local cans = inventory:FindAll(item:getFullType())
    local count = 0

    for i = 0, cans:size() - 1 do
        local can = cans:get(i)
        local canFluidContainer = can:getFluidContainer()
        local canFluid = canFluidContainer and canFluidContainer:getPrimaryFluid()
        if canFluid and canFluid:getFluidType() == sodaType then
            count = count + 1
        end
    end

    return count >= 6
end