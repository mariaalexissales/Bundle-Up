----------
--ESTRAL--
----------

require "BUpacking"

BUInv = BUInv or {}

local BU_pendingMelts = {}
local BU_meltSweepQueued = false

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

local function BU_isGone(item)
    if item:getContainer() then
        return false
    end
    local worldItem = item:getWorldItem()
    return worldItem == nil or worldItem:getWorldObjectIndex() == -1
end

local function BU_meltItem(item, character)
    local container = item:getContainer()
    if container then
        character:removeFromHands(item)
        sendRemoveItemFromContainer(container, item)
        container:Remove(item)
        return
    end
    local worldItem = item:getWorldItem()
    if worldItem and worldItem:getSquare() then
        worldItem:getSquare():transmitRemoveItemFromSquare(worldItem)
    end
end

local function BU_giveBack(entry, character)
    local container = entry.container
    if container and container:getType() ~= "floor" then
        local item = container:AddItem(entry.type)
        if item then
            sendAddItemToContainer(container, item)
        end
    else
        Actions.addOrDropItem(character, instanceItem(entry.type))
    end
end

local function BU_sweepMelts()
    Events.OnTick.Remove(BU_sweepMelts)
    BU_meltSweepQueued = false

    local pending = BU_pendingMelts
    BU_pendingMelts = {}
    for _, melt in ipairs(pending) do
        for _, entry in ipairs(melt.entries) do
            local gone = BU_isGone(entry.item)
            if entry.melts and not gone then
                BU_meltItem(entry.item, melt.character)
            elseif gone and not entry.melts then
                BU_giveBack(entry, melt.character)
            end
        end
    end
end

function BUInv.bulkSmelt(craftRecipeData, character)
    local input, data = BU_meltLine(craftRecipeData)
    local molten = craftRecipeData:getFirstCreatedItem()
    if not input or not molten or not instanceof(molten, "DrainableComboItem") then
        return
    end

    local entries, total = {}, 0
    for i = 0, data:getAppliedItemsCount() - 1 do
        local item = data:getAppliedItem(i)
        local entry = {
            item = item,
            type = item:getFullType(),
            container = item:getContainer(),
            worth = 1 / input:getRelativeScale(item:getFullType()),
        }
        entries[#entries + 1] = entry
        total = total + entry.worth
    end

    local uses = BU_crucibleUses(craftRecipeData)
    local units = math.min(math.floor(total + 0.0001), molten:getMaxUses() - uses)
    local melted = 0
    for _, entry in ipairs(entries) do
        entry.melts = melted + entry.worth <= units + 0.0001
        if entry.melts then
            melted = melted + entry.worth
        end
    end

    molten:setCurrentUses(uses + units)
    molten:syncItemFields()
    -- a part-filled crucible is drained whole, and that mints an empty one
    BUInv.stripMintedShells(craftRecipeData, character)

    -- the engine destroys ceil(ratio) items whatever each is worth, so 52 pieces
    -- lose 15. settle the melt set once processDestroyAndUsedItems has run.
    BU_pendingMelts[#BU_pendingMelts + 1] = { character = character, entries = entries }
    if not BU_meltSweepQueued then
        BU_meltSweepQueued = true
        Events.OnTick.Add(BU_sweepMelts)
    end
end
