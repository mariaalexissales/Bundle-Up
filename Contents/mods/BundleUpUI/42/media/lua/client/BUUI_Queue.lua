----------
--ESTRAL--
----------

require "BUUI_Index"
require "TimedActions/ISConsolidateDrainable"

BUUI = BUUI or {}
BUUI.Queue = BUUI.Queue or {}

local BUUI_active = nil
local BUUI_stepMerge

local function BUUI_snapshot(player)
    local seen = {}
    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        seen[items:get(i):getID()] = true
    end
    return seen
end

-- the concrete output types are only knowable once the mapper is pinned. collecting
-- them up front lets the diff below reject anything picked up mid-craft. an unresolved
-- output is describeOutputs guessing at the family, so filtering on it would strand the
-- real ones in the player's inventory - hand back nil and let the diff stand alone.
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
        -- without a resolved output list, trust the diff alone.
        local isOutput = (not types) or types[item:getFullType()]

        if isNew and isOutput then
            local action = ISInventoryTransferUtil.newInventoryTransferAction(
                player, item, player:getInventory(), container, nil)
            action:setAllowMissingItems(true)
            ISTimedActionQueue.add(action)
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

-- a row can stand for several item types the game names alike, so a batch that
-- exhausts one carries on into the next instead of stopping short.
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

local function BUUI_step()
    local job = BUUI_active
    if not job then return end

    if job.remaining <= 0 then
        if job.nextRow then
            local row = job.nextRow(job)
            if row then
                job.row = row
                job.remaining = row.quantity
            end
        end
        if job.remaining <= 0 then
            BUUI_finish(false)
            return
        end
    end

    local row = job.row
    if row.entry.merge then
        BUUI_stepMerge(job, row)
        return
    end

    local source, sample, containers = BUUI_nextSample(job)
    if not source then
        job.remaining = 0
        BUUI_step()
        return
    end

    local logic = HandcraftLogic.new(job.player, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(job.player, 2))
    logic:setContainers(containers)
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

    local outputTypes = BUUI_outputTypes(logic, row.entry.recipe)

    for _, action in ipairs(actions) do
        local before = nil

        action:setOnStart(function()
            before = BUUI_snapshot(job.player)
            logic:startCraftAction(action)
        end)

        action:setOnComplete(function()
            logic:stopCraftAction()

            -- stopping clears the queue, but an action already under way still reports
            -- back. without this the stale callback drives the next batch.
            if BUUI_active ~= job then return end

            BUUI_returnOutputs(job.player, before or {}, outputTypes, source.container)

            job.done = job.done + 1
            job.remaining = job.remaining - 1
            if job.onProgress then job.onProgress(job) end

            BUUI_step()
        end)

        action:setOnCancel(function()
            logic:stopCraftAction(true)
            if BUUI_active == job then BUUI_finish(true) end
        end)

        ISTimedActionQueue.add(action)
    end

    ISCraftingUI.ReturnItemsToOriginalContainer(job.player, putBack)
end

local function BUUI_noteHome(job, item)
    local container = item:getContainer()
    if not container or container == job.player:getInventory() then return end

    job.homes = job.homes or {}
    for _, home in ipairs(job.homes) do
        if home.item == item then return end
    end
    job.homes[#job.homes + 1] = { item = item, container = container }
end

local function BUUI_returnHomes(job)
    for _, home in ipairs(job.homes or {}) do
        -- whatever was poured dry is gone by now, so the transfer has to tolerate it.
        local back = ISInventoryTransferUtil.newInventoryTransferAction(
            job.player, home.item, job.player:getInventory(), home.container, nil)
        back:setAllowMissingItems(true)
        ISTimedActionQueue.add(back)
    end
    job.homes = nil
end

-- a merge has no recipe for HandcraftLogic to run, and it cannot be queued in bulk
-- either: ISConsolidateDrainable reads both fill levels in its constructor, so each
-- step is planned and built only once the one before it has finished. it carries no
-- setOnComplete, hence the perform wrapper.
function BUUI_stepMerge(job, row)
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

    BUUI_noteHome(job, step.from)
    BUUI_noteHome(job, step.into)

    ISInventoryPaneContextMenu.transferIfNeeded(job.player, step.from)
    ISInventoryPaneContextMenu.transferIfNeeded(job.player, step.into)

    local action = ISConsolidateDrainable:new(job.player, step.from, step.into, nil)
    local perform = action.perform
    action.perform = function(self)
        perform(self)

        -- stopping clears the queue, but an action already under way still reports
        -- back. without this the stale callback drives the next batch.
        if BUUI_active ~= job then return end

        job.done = job.done + 1
        job.remaining = job.remaining - 1
        if job.remaining <= 0 then BUUI_returnHomes(job) end
        if job.onProgress then job.onProgress(job) end

        BUUI_step()
    end

    ISTimedActionQueue.add(action)
end

function BUUI.Queue.isRunning()
    return BUUI_active ~= nil
end

-- nextRow is the only thing that differs between a fixed list and Bundle All: it
-- hands back the next row to run, or nil to finish.
local function BUUI_begin(player, nextRow, onProgress, onFinished)
    if BUUI_active then return false end

    BUUI_active = {
        player = player,
        row = nil,
        sourceIndex = 1,
        remaining = 0,
        total = 0,
        done = 0,
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

-- the list is fixed when the button is pressed, so an earlier row can eat what a later
-- one counted on - Tie10 and Tie5 want the same planks. not an error: the step loop
-- looks each source up by type and skips a spent one, so the batch just makes fewer.
function BUUI.Queue.startRows(player, rows, onProgress, onFinished)
    local index = 0

    local function nextRow(job)
        while true do
            index = index + 1
            local row = rows[index]
            if not row then return nil end

            if (row.quantity or 0) > 0 then
                job.total = job.total + row.quantity
                job.sourceIndex = 1
                return row
            end
        end
    end

    return BUUI_begin(player, nextRow, onProgress, onFinished)
end

-- Bundle All cannot be planned up front: Tie5 and Tie10 compete for the same planks
-- and getPossibleCraftCount cannot see crafts that have not happened. so each batch
-- finishes before the next row is chosen.
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
                job.total = job.total + row.max
                job.sourceIndex = 1
                return row
            end
        end
        return nil
    end

    return BUUI_begin(player, nextRow, onProgress, onFinished)
end
