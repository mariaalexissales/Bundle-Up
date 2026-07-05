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

    local inventory = character:getInventory()
    local outputItems = craftRecipeData:getAllCreatedItems()

    local pending = {}
    for i = 0, outputItems:size() - 1 do
        pending[#pending + 1] = outputItems:get(i)
    end

    local matchedCan = nil
    local maxAttempts = 100
    for _ = 1, maxAttempts do
        local can = table.remove(pending) or inventory:AddItem("Base.SodaCan")
        local fluidContainer = can:getFluidContainer()
        local fluid = fluidContainer and fluidContainer:getPrimaryFluid()
        if fluid and fluid:getFluidType() == sodaType then
            matchedCan = can
            break
        end
        inventory:Remove(can)
    end

    -- discard any of the recipe's own outputs we never got around to checking
    for _, can in ipairs(pending) do
        inventory:Remove(can)
    end

    if not matchedCan then
        -- correct flavor never rolled naturally within the retry budget;
        -- fluid/name will still be correct, but skip setColor() since it
        -- doesn't survive a save/reload (the icon would revert to whatever
        -- color this can originally rolled).
        matchedCan = inventory:AddItem("Base.SodaCan")
        local fluidContainer = matchedCan:getFluidContainer()
        fluidContainer:Empty()
        fluidContainer:addFluid(sodaType, 1.0)
    end

    for _ = 1, 5 do
        inventory:AddItem(matchedCan:createCloneItem())
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

    local sodaFluid = fluid:getFluidTypeString()
    local sodaType = Fluid.Get(sodaFluid)

    local packType = PACK_FLAVORS_REVERSE[sodaFluid]
    if not packType then
        return
    end

    local intakeItems = craftRecipeData:getInputItems(0)
    local matched = 0
    for i = intakeItems:size() - 1, 0, -1 do
        local can = intakeItems:get(i)
        local canFluidContainer = can:getFluidContainer()
        local canFluid = canFluidContainer and canFluidContainer:getPrimaryFluid()
        if matched < 6 and canFluid and canFluid:getFluidType() == sodaType then
            matched = matched + 1
        else
            craftRecipeData:removeInputItem(can)
        end
    end

    local inventory = character:getInventory()
    if matched < 6 then
        local cans = inventory:FindAll(sodaCan:getFullType())
        for i = 0, cans:size() - 1 do
            if matched >= 6 then
                break
            end
            local can = cans:get(i)
            if not craftRecipeData:containsInputItem(can) then
                local canFluidContainer = can:getFluidContainer()
                local canFluid = canFluidContainer and canFluidContainer:getPrimaryFluid()
                if canFluid and canFluid:getFluidType() == sodaType then
                    inventory:Remove(can)
                    matched = matched + 1
                end
            end
        end
    end

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