----------
--ESTRAL--
----------

require "BU_MergeData"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISConsolidateDrainable"

local BU_vanillaCheckConsolidate = ISInventoryPaneContextMenu.checkConsolidate

local function BU_homesOf(playerObj, items)
    local homes = {}
    for _, item in ipairs(items) do
        local container = item:getContainer()
        if container and container ~= playerObj:getInventory() then
            homes[#homes + 1] = { item = item, container = container }
        end
    end
    return homes
end

local function BU_returnHome(playerObj, homes)
    for _, home in ipairs(homes) do
        -- whatever was poured dry is gone by now, so the transfer has to tolerate it.
        local action = ISInventoryTransferUtil.newInventoryTransferAction(
            playerObj, home.item, playerObj:getInventory(), home.container, nil)
        action:setAllowMissingItems(true)
        ISTimedActionQueue.add(action)
    end
end

-- one step at a time: ISConsolidateDrainable reads both fill levels in its constructor,
-- so a whole chain queued up front would lerp every later merge from stale numbers and
-- undo the earlier ones. it carries no setOnComplete either, hence the perform wrapper.
local function BU_chainMerge(playerObj, steps, index, homes)
    local step = steps[index]
    if not step then
        BU_returnHome(playerObj, homes)
        return
    end

    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, step.from)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, step.into)

    local action = ISConsolidateDrainable:new(playerObj, step.from, step.into, nil)
    local perform = action.perform
    action.perform = function(self)
        perform(self)
        BU_chainMerge(playerObj, steps, index + 1, homes)
    end

    ISTimedActionQueue.add(action)
end

local function BU_onMerge(playerObj, from, into)
    local homes = BU_homesOf(playerObj, { from, into })
    BU_chainMerge(playerObj, { { from = from, into = into } }, 1, homes)
end

local function BU_onMergeAll(playerObj, candidates)
    local plan = BU.Merge.plan(candidates)
    if #plan.steps == 0 then return end

    BU_chainMerge(playerObj, plan.steps, 1, BU_homesOf(playerObj, candidates))
end

local function BU_fillLabel(item)
    return item:getName() .. " (" .. math.floor(item:getCurrentUsesFloat() * 100)
        .. getText("ContextMenu_FullPercent") .. ")"
end

function ISInventoryPaneContextMenu.checkConsolidate(drainable, playerObj, context, previousPourInto)
    if not (drainable and BU.Merge.canMerge(drainable)) then
        return BU_vanillaCheckConsolidate(drainable, playerObj, context, previousPourInto)
    end

    -- vanilla asks the main inventory with the non-recursive getItemsFromType, so spools
    -- in a worn bag or the crate you are standing at never show up. same list the packing
    -- panel reads, so "in reach" means one thing across the mod.
    local candidates = BU.Merge.gather(ISInventoryPaneContextMenu.getContainers(playerObj),
        drainable:getFullType())

    local targets = {}
    for _, item in ipairs(candidates) do
        if item ~= drainable and BU.Merge.uses(item) < BU.Merge.maxUses(item) then
            targets[#targets + 1] = item
        end
    end
    if #targets == 0 then return end

    local option = context:addOption(getText(drainable:getConsolidateOption() or "ContextMenu_Merge"), nil, nil)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    if #targets > 1 then
        submenu:addOption(getText("ContextMenu_MergeAll"), playerObj, BU_onMergeAll, candidates)
    end

    for _, into in ipairs(targets) do
        submenu:addOption(BU_fillLabel(into), playerObj, BU_onMerge, drainable, into)
    end
end
