----------
--ESTRAL--
----------

require "BUUI_Index"
if not BUUI.MODE then return end

require "BUUI_Queue"

local STALE_REFRESHES = 10
local SOURCES_SHOWN = 3

BUUI.LABELS = {
    [BUUI.MODE.BUNDLE] = {
        items = "IGUI_BUUI_BundleItems", all = "IGUI_BUUI_BundleAll", empty = "IGUI_BUUI_Empty",
    },
    [BUUI.MODE.UNBUNDLE] = {
        items = "IGUI_BUUI_UnbundleItems", all = "IGUI_BUUI_UnbundleAll", empty = "IGUI_BUUI_EmptyUnbundle",
    },
    [BUUI.MODE.MERGE] = {
        items = "IGUI_BUUI_MergeItems", all = "IGUI_BUUI_MergeAll", empty = "IGUI_BUUI_EmptyMerge",
    },
}

local function BUUI_sameScan(a, b)
    if not a or not b or a.square ~= b.square then return false end

    local ca, cb = a.containers, b.containers
    if ca:size() ~= cb:size() then return false end
    for i = 0, ca:size() - 1 do
        if ca:get(i) ~= cb:get(i) then return false end
    end

    for fullType, count in pairs(a.tally) do
        if b.tally[fullType] ~= count then return false end
    end
    for fullType in pairs(b.tally) do
        if a.tally[fullType] == nil then return false end
    end

    return true
end

function BUUI.scanReach(player)
    local containers, tally, sample = BUUI.scanContainers(player)
    return {
        square = player:getCurrentSquare(),
        containers = containers,
        tally = tally,
        sample = sample,
    }
end

-- the player's own inventory has no holder and its raw type reads "none".
local function BUUI_containerName(container)
    local holder = container:getContainingItem()
    if holder then return holder:getName() end

    local kind = container:getType()
    if not kind or kind == "" or kind == "none" then
        return getText("IGUI_BUUI_Inventory")
    end

    return getTextOrNull("IGUI_ContainerTitle_" .. tostring(kind)) or tostring(kind)
end

function BUUI.describeSources(containers)
    local names, seen = {}, {}

    for i = 0, containers:size() - 1 do
        local name = BUUI_containerName(containers:get(i))
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    if #names == 0 then return getText("IGUI_BUUI_NoSources") end

    local shown = {}
    for i = 1, math.min(SOURCES_SHOWN, #names) do shown[i] = names[i] end

    local text = getText("IGUI_BUUI_Sources") .. " " .. table.concat(shown, ", ")
    if #names > SOURCES_SHOWN then
        text = text .. " (+" .. tostring(#names - SOURCES_SHOWN) .. ")"
    end

    return text
end

-- the auto-refresh rebuilds every row, so a dialled quantity has to be carried
-- across by key or the timer wipes it before the player reaches the button.
function BUUI.refreshView(view, scan)
    local dialled = {}
    for _, row in ipairs(view.rows) do
        if row.key then dialled[row.key] = row.quantity end
    end

    if view.mode == BUUI.MODE.MERGE then
        scan = nil
    else
        scan = scan or BUUI.scanReach(view.player)
    end
    view.lastScan = scan
    view.skipped = 0

    local rows, containers = BUUI.resolveRows(view.player, view.mode, scan)
    view.rows = rows
    view.sourceText = BUUI.describeSources(containers)

    view.ready = 0
    for _, row in ipairs(view.rows) do
        local previous = dialled[row.key]
        if previous then row.quantity = math.min(previous, row.max) end
        if row.ready then view.ready = view.ready + 1 end
    end
end

-- fill levels, wear and rot change a row without moving the tally, so merge is never
-- gated and the other tabs still re-probe after STALE_REFRESHES skipped checks.
function BUUI.pollView(view)
    if view.mode == BUUI.MODE.MERGE or view.skipped >= STALE_REFRESHES then
        return true, nil
    end

    local scan = BUUI.scanReach(view.player)
    if BUUI_sameScan(scan, view.lastScan) then
        view.skipped = view.skipped + 1
        return false
    end
    return true, scan
end

function BUUI.chosenRows(view)
    local chosen = {}
    for _, row in ipairs(view.rows) do
        if row.ready and (row.quantity or 0) > 0 then
            chosen[#chosen + 1] = row
        end
    end
    return chosen
end

local BUUI_views = {}

function BUUI.addView(onBatch)
    BUUI_views[#BUUI_views + 1] = onBatch
end

function BUUI.notifyViews(finished)
    for _, onBatch in ipairs(BUUI_views) do onBatch(finished) end
end

function BUUI.runBatch(player, mode)
    -- stop fires no callback, so the views are told here.
    if BUUI.Queue.isRunning() then
        BUUI.Queue.stop()
        BUUI.notifyViews(true)
        return
    end

    local worked = false

    BUUI.Queue.startAll(player, mode,
        function()
            worked = true
            BUUI.notifyViews(false)
        end,
        function(cancelled)
            BUUI.notifyViews(true)
            if not worked and not cancelled then
                HaloTextHelper.addText(player, getText(BUUI.LABELS[mode].empty))
            end
        end)

    -- with nothing to do the batch has already finished inside startAll.
    if BUUI.Queue.isRunning() then BUUI.notifyViews(false) end
end
