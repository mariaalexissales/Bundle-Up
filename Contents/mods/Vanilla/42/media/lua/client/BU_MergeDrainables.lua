----------
--ESTRAL--
----------

require "BU_MergeData"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISConsolidateDrainable"

local BU_vanillaCheckConsolidate = ISInventoryPaneContextMenu.checkConsolidate

local function BU_returnHome(playerObj, homes)
    for _, home in ipairs(homes) do
        -- whatever was poured dry is gone by now, so the transfer has to tolerate it.
        local action = ISInventoryTransferUtil.newInventoryTransferAction(
            playerObj, home.item, playerObj:getInventory(), home.container, nil)
        action:setAllowMissingItems(true)
        ISTimedActionQueue.add(action)
    end
end

-- vanilla's isValid and nextItem only look in the main inventory, so every spool has to be
-- pulled in before the pour starts. runAgain slots each chained pour ahead of the returns.
local function BU_pullIn(playerObj, items)
    local homes = {}
    for _, item in ipairs(items) do
        local container = item:getContainer()
        if container and container ~= playerObj:getInventory() then
            homes[#homes + 1] = { item = item, container = container }
        end
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    end
    return homes
end

local function BU_onConsolidate(playerObj, drainable, intoItem)
    local homes = BU_pullIn(playerObj, { drainable, intoItem })
    ISTimedActionQueue.add(ISConsolidateDrainable:new(playerObj, drainable, intoItem, nil))
    BU_returnHome(playerObj, homes)
end

local function BU_onConsolidateAll(playerObj, drainable, consolidateList)
    local involved = { drainable }
    for _, item in ipairs(consolidateList) do
        involved[#involved + 1] = item
    end
    local homes = BU_pullIn(playerObj, involved)

    local intoItem
    if drainable:getCurrentUsesFloat() < 1 then
        intoItem = table.remove(consolidateList, 1)
    else
        drainable = table.remove(consolidateList, 1)
        intoItem = table.remove(consolidateList, 1)
    end
    ISTimedActionQueue.add(ISConsolidateDrainable:new(playerObj, drainable, intoItem, consolidateList))
    BU_returnHome(playerObj, homes)
end

local function BU_fillLabel(item)
    return item:getName() .. " (" .. math.floor(item:getCurrentUsesFloat() * 100)
        .. getText("ContextMenu_FullPercent") .. ")"
end

local function BU_allLoose(playerObj, drainable, candidates)
    local inventory = playerObj:getInventory()
    if drainable:getContainer() ~= inventory then return false end

    for _, item in ipairs(candidates) do
        if item:getContainer() ~= inventory then return false end
    end
    return true
end

function ISInventoryPaneContextMenu.checkConsolidate(drainable, playerObj, context, previousPourInto)
    if not (drainable and BU.Merge.canMerge(drainable)) then
        return BU_vanillaCheckConsolidate(drainable, playerObj, context, previousPourInto)
    end

    -- vanilla's getItemsFromType skips worn bags and nearby crates. this is the same
    -- container list the packing panel reads.
    local candidates = BU.Merge.gather(ISInventoryPaneContextMenu.getContainers(playerObj),
        drainable:getFullType())

    if BU_allLoose(playerObj, drainable, candidates) then
        return BU_vanillaCheckConsolidate(drainable, playerObj, context, previousPourInto)
    end

    local skip = {}
    for _, item in ipairs(previousPourInto or {}) do
        skip[item] = true
    end

    local consolidateList = {}
    for _, item in ipairs(candidates) do
        if item ~= drainable and not skip[item] and BU.Merge.uses(item) < BU.Merge.maxUses(item) then
            consolidateList[#consolidateList + 1] = item
        end
    end
    if #consolidateList == 0 then return end

    local option = context:addOption(getText(drainable:getConsolidateOption() or "ContextMenu_Pour_into"), nil, nil)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    if #consolidateList > 1 then
        submenu:addOption(getText("ContextMenu_MergeAll"), playerObj, BU_onConsolidateAll, drainable, consolidateList)
    end

    for _, intoItem in ipairs(consolidateList) do
        submenu:addOption(BU_fillLabel(intoItem), playerObj, BU_onConsolidate, drainable, intoItem)
    end
end
