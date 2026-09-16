----------
--ESTRAL--
----------

require "BU_MergeData"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISConsolidateDrainable"

local BU_vanillaCheckConsolidate = ISInventoryPaneContextMenu.checkConsolidate

local BU_jobs = {}
local BU_pump

local function BU_noteHome(playerObj, job, item)
    local container = item:getContainer()
    if not container or container == playerObj:getInventory() then return end

    for _, home in ipairs(job.homes) do
        if home.item == item then return end
    end
    job.homes[#job.homes + 1] = { item = item, container = container }
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

local function BU_inReach(containers, item)
    local container = item:getContainer()
    return container ~= nil and containers:contains(container)
end

local function BU_stillPours(containers, from, into)
    return BU_inReach(containers, from) and BU_inReach(containers, into)
        and BU.Merge.uses(from) > 0 and BU.Merge.uses(into) < BU.Merge.maxUses(into)
end

local function BU_nextStep(playerObj, job)
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)

    while job.requests[1] do
        local request = job.requests[1]
        local step = nil

        if request.fullType then
            if request.remaining > 0 then
                request.remaining = request.remaining - 1
                step = BU.Merge.plan(BU.Merge.gather(containers, request.fullType)).steps[1]
            end
            if not step then table.remove(job.requests, 1) end
        else
            table.remove(job.requests, 1)
            if BU_stillPours(containers, request.from, request.into) then step = request end
        end

        if step then return step end
    end

    return nil
end

function BU_pump(playerObj, job)
    local step = BU_nextStep(playerObj, job)
    if not step then
        if BU_jobs[playerObj] == job then BU_jobs[playerObj] = nil end
        BU_returnHome(playerObj, job.homes)
        return
    end

    BU_noteHome(playerObj, job, step.from)
    BU_noteHome(playerObj, job, step.into)

    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, step.from)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, step.into)

    local action = ISConsolidateDrainable:new(playerObj, step.from, step.into, nil)

    local perform = action.perform
    action.perform = function(self)
        perform(self)
        if BU_jobs[playerObj] == job then BU_pump(playerObj, job) end
    end

    local stop = action.stop
    action.stop = function(self)
        stop(self)
        if BU_jobs[playerObj] == job then BU_jobs[playerObj] = nil end
    end

    local forceCancel = action.forceCancel
    action.forceCancel = function(self)
        forceCancel(self)
        if BU_jobs[playerObj] == job then BU_jobs[playerObj] = nil end
    end

    job.action = action
    ISTimedActionQueue.add(action)
end

-- ISConsolidateDrainable reads both fill levels in new(), so a pour queued behind another
-- runs from stale numbers and undoes it. only one is ever queued, built as the last finishes.
local function BU_request(playerObj, request)
    local job = BU_jobs[playerObj]
    -- hasAction, not just the job, since a cleared queue can drop the pour without a stop.
    if job and ISTimedActionQueue.hasAction(job.action) then
        job.requests[#job.requests + 1] = request
        return
    end

    job = { requests = { request }, homes = {} }
    BU_jobs[playerObj] = job
    BU_pump(playerObj, job)
end

local function BU_onMerge(playerObj, from, into)
    BU_request(playerObj, { from = from, into = into })
end

local function BU_onMergeAll(playerObj, fullType, steps)
    BU_request(playerObj, { fullType = fullType, remaining = steps })
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
        submenu:addOption(getText("ContextMenu_MergeAll"), playerObj, BU_onMergeAll,
            drainable:getFullType(), #BU.Merge.plan(candidates).steps)
    end

    for _, into in ipairs(targets) do
        submenu:addOption(BU_fillLabel(into), playerObj, BU_onMerge, drainable, into)
    end
end
