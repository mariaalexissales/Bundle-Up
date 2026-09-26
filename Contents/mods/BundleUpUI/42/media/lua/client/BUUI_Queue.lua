----------
--ESTRAL--
----------

require "BUUI_Index"
require "BU_Transfer"
require "TimedActions/ISConsolidateDrainable"

BUUI = BUUI or {}
BUUI.Queue = BUUI.Queue or {}

local BUUI_active = nil
local BUUI_step

local function BUUI_snapshot(player)
    local seen = {}
    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        seen[items:get(i):getID()] = true
    end
    return seen
end

-- an unresolved output is describeOutputs guessing at the family. filtering on a guess
-- strands the real outputs in the player's inventory, so return nil and trust the diff.
local function BUUI_outputTypes(logic, recipe)
    local types, any = {}, false

    for _, output in ipairs(BUUI.describeOutputs(logic, recipe)) do
        if not output.resolved then return nil end
        types[output.fullType] = true
        any = true
    end

    return any and types or nil
end

-- CraftRecipeData exposes no created-items list to Lua, so what the craft made is
-- whatever is in the player's inventory that was not there when it started.
local function BUUI_returnOutputs(player, before, types, container)
    if not container or container == player:getInventory() then return end

    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local isNew = not before[item:getID()]
        local isOutput = (not types) or types[item:getFullType()]

        if isNew and isOutput then
            BU.sendBack(player, item, container)
        end
    end
end

-- the recipes are all InHandCraft, so materials pass through the player's hands. one
-- craft's worth at a time keeps peak carried weight at a recipe, not a whole crate.
local function BUUI_stageInputs(player, logic)
    local returned = {}
    if logic:getRecipe():isCanBeDoneFromFloor() then return returned end

    local items = logic:getRecipeData():getAllInputItems()
    local putBack = logic:getRecipeData():getAllPutBackInputItems()

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getContainer() ~= player:getInventory() then
            ISInventoryPaneContextMenu.transferIfNeeded(player, item)
            if putBack:contains(item) then returned[#returned + 1] = item end
        end
    end

    return returned
end

-- the sample the row was built from is eaten by the first craft, so every iteration
-- has to find a live one of that type before pinning the mapper.
local function BUUI_liveSample(player, fullType)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    for i = 0, containers:size() - 1 do
        local items = containers:get(i):getItems()
        for n = 0, items:size() - 1 do
            local item = items:get(n)
            if item:getFullType() == fullType then return item, containers end
        end
    end
    return nil, containers
end

local function BUUI_nextSample(job)
    local sources = job.row.sources

    while job.sourceIndex <= #sources do
        local source = sources[job.sourceIndex]
        local sample, containers = BUUI_liveSample(job.player, source.fullType)
        if sample then return source, sample, containers end
        job.sourceIndex = job.sourceIndex + 1
    end

    return nil
end

local function BUUI_finish(cancelled)
    local job = BUUI_active
    BUUI_active = nil
    if job and job.onFinished then job.onFinished(cancelled) end
end

local function BUUI_returnHomes(job)
    BU.sendHomes(job.player, job.homes)
    job.homes = nil
end

local function BUUI_stepDone(job, settle)
    -- stopping clears the queue, but an action already under way still reports
    -- back. without this the stale callback drives the next batch.
    if BUUI_active ~= job then return end
    if settle then settle() end

    job.remaining = job.remaining - 1
    if job.remaining <= 0 then BUUI_returnHomes(job) end
    if job.onProgress then job.onProgress(job) end

    BUUI_step()
end

local function BUUI_hasWork(job)
    if job.remaining <= 0 and job.nextRow then
        local row = job.nextRow(job)
        if row then
            job.row = row
            job.remaining = row.quantity
        end
    end
    return job.remaining > 0
end

local function BUUI_queueCraft(job, logic, actions, recipe, home)
    local outputTypes = BUUI_outputTypes(logic, recipe)

    for _, action in ipairs(actions) do
        local before = nil

        action:setOnStart(function()
            before = BUUI_snapshot(job.player)
            logic:startCraftAction(action)
        end)

        action:setOnComplete(function()
            logic:stopCraftAction()
            BUUI_stepDone(job, function()
                BUUI_returnOutputs(job.player, before or {}, outputTypes, home)
            end)
        end)

        action:setOnCancel(function()
            logic:stopCraftAction(true)
            if BUUI_active == job then BUUI_finish(true) end
        end)

        ISTimedActionQueue.add(action)
    end
end

local function BUUI_stepCraft(job, row)
    local source, sample, containers = BUUI_nextSample(job)
    if not source then
        job.remaining = 0
        BUUI_step()
        return
    end

    local logic = BUUI.probeLogic(job.player, containers)
    logic:setRecipeFromContextClick(row.entry.recipe, sample)

    if not logic:canPerformCurrentRecipe() or logic:getPossibleCraftCount(true) < 1 then
        -- this type is spent or blocked, but a merged row may have another behind it,
        -- so step past rather than abandon the batch.
        job.sourceIndex = job.sourceIndex + 1
        BUUI_step()
        return
    end

    local putBack = BUUI_stageInputs(job.player, logic)
    logic:updateManualInputAllowedItemTypes()

    local actions = ISEntityUI.HandcraftStartMultiple(job.player, logic, false, 1, false)
    if not actions or #actions == 0 then
        BUUI_finish(false)
        return
    end

    BUUI_queueCraft(job, logic, actions, row.entry.recipe, source.container)
    ISCraftingUI.ReturnItemsToOriginalContainer(job.player, putBack)
end

-- ISConsolidateDrainable reads both fill levels in its constructor, so each pour is built
-- only after the last one finished. it has no setOnComplete, hence the perform wrapper.
local function BUUI_stepMerge(job, row)
    local source = row.sources[1]
    local step = nil

    if source then
        local containers = ISInventoryPaneContextMenu.getContainers(job.player)
        step = BU.Merge.plan(BU.Merge.gather(containers, source.fullType)).steps[1]
    end

    if not step then
        job.remaining = 0
        BUUI_returnHomes(job)
        BUUI_step()
        return
    end

    job.homes = BU.noteHome(job.player, job.homes, step.from)
    job.homes = BU.noteHome(job.player, job.homes, step.into)

    ISInventoryPaneContextMenu.transferIfNeeded(job.player, step.from)
    ISInventoryPaneContextMenu.transferIfNeeded(job.player, step.into)

    local action = ISConsolidateDrainable:new(job.player, step.from, step.into, nil)
    local perform = action.perform
    action.perform = function(self)
        perform(self)
        BUUI_stepDone(job)
    end

    -- walking off or a missing item ends it in stop, or in forceCancel while it still
    -- waits behind a transfer. perform never fires then, and the batch would hang on Stop.
    local stop = action.stop
    action.stop = function(self)
        stop(self)
        if BUUI_active == job then BUUI_finish(true) end
    end
    local forceCancel = action.forceCancel
    action.forceCancel = function(self)
        forceCancel(self)
        if BUUI_active == job then BUUI_finish(true) end
    end

    ISTimedActionQueue.add(action)
end

BUUI_step = function()
    local job = BUUI_active
    if not job then return end

    if not BUUI_hasWork(job) then
        BUUI_finish(false)
        return
    end

    if job.row.entry.merge then
        BUUI_stepMerge(job, job.row)
    else
        BUUI_stepCraft(job, job.row)
    end
end

function BUUI.Queue.isRunning()
    return BUUI_active ~= nil
end

local function BUUI_begin(player, nextRow, onProgress, onFinished)
    if BUUI_active then return false end

    BUUI_active = {
        player = player,
        row = nil,
        sourceIndex = 1,
        remaining = 0,
        onProgress = onProgress,
        onFinished = onFinished,
        nextRow = nextRow,
    }

    BUUI_step()
    return true
end

function BUUI.Queue.stop()
    if not BUUI_active then return end

    local player = BUUI_active.player
    BUUI_active = nil
    ISTimedActionQueue.clear(player)
end

-- the list is fixed at the click, so an earlier row can eat a later one's planks. the
-- step loop skips a spent source, so the batch just makes fewer.
function BUUI.Queue.startRows(player, rows, onProgress, onFinished)
    local index = 0

    local function nextRow(job)
        while true do
            index = index + 1
            local row = rows[index]
            if not row then return nil end

            if (row.quantity or 0) > 0 then
                job.sourceIndex = 1
                return row
            end
        end
    end

    return BUUI_begin(player, nextRow, onProgress, onFinished)
end

-- each row is picked after the last batch finishes. Tie5 and Tie10 share planks and
-- getPossibleCraftCount can't see crafts that haven't happened yet.
function BUUI.Queue.startAll(player, mode, onProgress, onFinished)
    local attempted = {}

    local function nextRow(job)
        local rows = BUUI.resolveRows(player, mode)
        for _, row in ipairs(rows) do
            -- row.key is the only thing separating the rope twins: Untie5 takes both
            -- plank bundles and they share a name, so keying on that would skip one.
            if row.ready and row.max > 0 and not attempted[row.key] then
                attempted[row.key] = true
                row.quantity = row.max
                job.sourceIndex = 1
                return row
            end
        end
        return nil
    end

    return BUUI_begin(player, nextRow, onProgress, onFinished)
end
