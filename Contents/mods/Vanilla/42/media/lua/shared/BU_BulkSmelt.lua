----------
--ESTRAL--
----------

require "BUpacking"

BUInv = BUInv or {}

local function BU_meltLine(craftRecipeData)
    local inputs = craftRecipeData:getRecipe():getInputs()
    for i = 0, inputs:size() - 1 do
        local input = inputs:get(i)
        if input:isVariableAmount() then
            return input, craftRecipeData:getDataForInputScript(input)
        end
    end
    return nil, nil
end

local function BU_meltedCount(craftRecipeData, input, data)
    -- matched items outnumber destroyed ones when the queued ratio is lower, and
    -- giving back from the matched count dupes scrap.
    local ratio = craftRecipeData:getCalculatedVariableInputRatio()
    local destroyed = math.ceil(input:getIntAmount() * ratio - 0.0001)
    return math.min(data:getAppliedItemsCount(), destroyed)
end

local function BU_crucibleUses(craftRecipeData)
    local consumed = craftRecipeData:getAllConsumedItems()
    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        if instanceof(item, "DrainableComboItem") then
            return item:getCurrentUses()
        end
    end
    return 0
end

local function BU_giveBack(sample, count, character)
    local fullType = sample:getFullType()
    local container = sample:getContainer()
    for _ = 1, count do
        if container and container:getType() ~= "floor" then
            local item = container:AddItem(fullType)
            if item then
                sendAddItemToContainer(container, item)
            end
        else
            Actions.addOrDropItem(character, instanceItem(fullType))
        end
    end
end

function BUInv.bulkForgeClamp(craftRecipeData, character)
    -- variable outputs round the ratio up, so 10 scrap would make 3 sheets
    craftRecipeData:setTargetVariableInputRatio(math.floor(craftRecipeData:getCalculatedVariableInputRatio()))
end

function BUInv.bulkSmelt(craftRecipeData, character)
    local input, data = BU_meltLine(craftRecipeData)
    if not input or data:getAppliedItemsCount() == 0 then
        return
    end

    local perUnit = input:getIntAmount()
    local melted = BU_meltedCount(craftRecipeData, input, data)
    local units = math.floor(melted / perUnit)

    local molten = craftRecipeData:getFirstCreatedItem()
    if molten and instanceof(molten, "DrainableComboItem") then
        local uses = BU_crucibleUses(craftRecipeData)
        units = math.min(units, molten:getMaxUses() - uses)
        molten:setCurrentUses(uses + units)
        molten:syncItemFields()
        -- a part-filled crucible is drained whole, and that mints an empty one
        BUInv.stripMintedShells(craftRecipeData, character)
    end

    local leftover = melted - units * perUnit
    if leftover > 0 then
        BU_giveBack(data:getFirstAppliedItem(), leftover, character)
    end
end
