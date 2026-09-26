----------
--ESTRAL--
----------

BUUI = BUUI or {}

require "BU_MergeData"

BUUI.MODE = {
    BUNDLE   = "bundle",
    UNBUNDLE = "unbundle",
    MERGE    = "merge",
}

-- recipes are picked up by module prefix, not a tag. another packing mod only has to
-- add its module here.
BUUI.modules = BUUI.modules or { BundleUp = true }

BUUI.recipes = nil

local SURFACE_RADIUS = 2

-- family members can carry their own amount ("item 10 [...;50:Base.NutsBolts]") and the
-- plain getIntAmount reads 1 for those, so the keyed lookup is the real count.
local function BUUI_amountFor(input, fullName)
    local amount = fullName and input:getIntAmount(fullName) or 0
    if amount < 1 then amount = input:getIntAmount() end
    return amount
end

local function BUUI_largestAmount(input)
    local possible = input:getPossibleInputItems()
    if not possible or possible:size() == 0 then return input:getIntAmount(), nil, nil end

    local largest, names, amounts = 0, {}, {}
    for i = 0, possible:size() - 1 do
        local fullName = possible:get(i):getFullName()
        local amount = BUUI_amountFor(input, fullName)
        names[i + 1], amounts[i + 1] = fullName, amount
        if amount > largest then largest = amount end
    end

    return largest, names, amounts
end

-- the bulk input is whichever asks for the most (Tie5: 1 rope, 5 planks). flags[ItemCount]
-- can't tell you, BoxSmall carries none.
local function BUUI_splitInputs(recipe)
    local inputs = recipe:getInputs()
    if not inputs or inputs:size() == 0 then return nil, nil, 0 end

    local pivot, bulk, others, names, amounts = nil, 0, {}, nil, nil
    for i = 0, inputs:size() - 1 do
        local input = inputs:get(i)
        if input:getResourceType() == ResourceType.Item and not input:isAutomationOnly() then
            local amount, inputNames, inputAmounts = BUUI_largestAmount(input)
            if not pivot or amount > bulk then
                if pivot then others[#others + 1] = pivot end
                pivot, bulk, names, amounts = input, amount, inputNames, inputAmounts
            else
                others[#others + 1] = input
            end
        end
    end

    return pivot, others, bulk, names, amounts
end

local function BUUI_moduleOf(recipe)
    local fullType = recipe:getScriptObjectFullType()
    return fullType and fullType:match("^([^%.]+)%.") or nil
end

function BUUI.buildIndex()
    local index = {}
    local all = ScriptManager.instance:getAllCraftRecipes()
    if not all then
        BUUI.recipes = index
        return index
    end

    for i = 0, all:size() - 1 do
        local recipe = all:get(i)
        local module = BUUI_moduleOf(recipe)
        if module and BUUI.modules[module] and recipe:getCategory() == "Packing" then
            local pivot, others, bulk, names, amounts = BUUI_splitInputs(recipe)
            if pivot then
                -- many in is packing, one in is unpacking. no recipe names involved.
                local bundling = bulk >= 2

                if names then
                    for n = 1, #names do
                        local fullName = names[n]
                        local bucket = index[fullName]
                        if not bucket then
                            bucket = {}
                            index[fullName] = bucket
                        end

                        -- an entry per item rather than per recipe, because the family
                        -- members disagree: a box takes 10 remotes but 50 nuts and bolts.
                        bucket[#bucket + 1] = {
                            recipe = recipe,
                            pivot = pivot,
                            secondaries = others,
                            count = amounts[n],
                            bundling = bundling,
                        }
                    end
                end
            end
        end
    end

    -- deepest compaction first, so Bundle All reaches for Tie10 before Tie5 competes
    -- for the same planks.
    for _, bucket in pairs(index) do
        table.sort(bucket, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.recipe:getName() < b.recipe:getName()
        end)
    end

    BUUI.recipes = index
    return index
end

function BUUI.getIndex()
    return BUUI.recipes or BUUI.buildIndex()
end

function BUUI.scanContainers(player)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local tally, sample = {}, {}

    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        local items = container:getItems()
        for n = 0, items:size() - 1 do
            local item = items:get(n)
            local fullType = item:getFullType()
            tally[fullType] = (tally[fullType] or 0) + 1
            if not sample[fullType] then sample[fullType] = item end
        end
    end

    return containers, tally, sample
end

-- same order as ISInventoryPaneContextMenu.OnNewCraft: a fresh logic gets its craft
-- surface before anything asks whether the recipe can run.
local function BUUI_probeLogic(player, containers, surface)
    local logic = HandcraftLogic.new(player, nil, nil)
    -- findCraftSurface reads only the player's square, so one lookup covers a whole pass.
    if surface == nil then
        surface = logic:findCraftSurface(player, SURFACE_RADIUS) or false
    end
    logic:setIsoObject(surface or nil)
    logic:setContainers(containers)
    return logic, surface
end

-- PackFoodCase takes all 166 cartons, so the first possible item is a coin toss. wanted is
-- the type the row was built from, and secondaries pass nil.
local function BUUI_inputNames(logic, input, wanted)
    -- vanilla swaps these two lists freely, they hold the same object type. the fallback
    -- is for an input with nothing in reach, like the rope.
    local objects = logic:getSatisfiedInputItems(input)
    if not objects or objects:size() == 0 then
        objects = input:getPossibleInputItems()
    end

    if objects and objects:size() > 0 then
        if wanted then
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if object:getFullName() == wanted then
                    return object:getDisplayName(), object:getFullName()
                end
            end
        end

        local object = objects:get(0)
        return object:getDisplayName(), object:getFullName()
    end

    return "?", nil
end

local function BUUI_describeInputs(logic, entry, fullType)
    local parts, satisfied = {}, true

    local function describe(input, wanted)
        local ok = logic:isInputSatisfied(input) and true or false
        if not ok then satisfied = false end

        local label, fullName = BUUI_inputNames(logic, input, wanted)

        parts[#parts + 1] = {
            label = label,
            have = logic:getInputCount(input),
            need = BUUI_amountFor(input, fullName),
            satisfied = ok,
        }
    end

    describe(entry.pivot, fullType)
    for _, input in ipairs(entry.secondaries) do describe(input) end

    return parts, satisfied
end

-- untying gives back the rope as well as the planks, so read every output. the mapper only
-- resolves with every input in reach, so a short row falls back to the script's list.
function BUUI.describeOutputs(logic, recipe)
    local outputs, described = recipe:getOutputs(), {}
    if not outputs then return described end

    local data = logic:getRecipeData()

    for i = 0, outputs:size() - 1 do
        local script = outputs:get(i)
        if not script:isAutomationOnly() and script:getResourceType() == ResourceType.Item then
            local mapper = script.getOutputMapper and script:getOutputMapper()
            local item = data and mapper and mapper:getOutputItem(data, true)
            local resolved = item ~= nil

            if not item then
                local possible = script:getPossibleResultItems()
                if possible and possible:size() > 0 then item = possible:get(0) end
            end

            if item then
                described[#described + 1] = {
                    fullType = item:getFullName(),
                    name = item:getDisplayName(),
                    amount = script:getIntAmount(),
                    texture = item:getNormalTexture(),
                    resolved = resolved,
                }
            end
        end
    end

    return described
end

-- part of the row key, so two bundles with the same name stay apart.
local function BUUI_outputLabel(outputs)
    if #outputs == 0 then return nil end

    local parts = {}
    for _, output in ipairs(outputs) do
        parts[#parts + 1] = tostring(output.amount) .. " " .. output.name
    end

    return table.concat(parts, " + ")
end

-- a merge row stands in for a recipe it does not have: BUUI_Queue branches on
-- entry.merge, and the sort at the foot of resolveRows reads entry.count.
function BUUI.resolveMergeRows(player)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local rows = {}

    for fullType, items in pairs(BU.Merge.collect(containers)) do
        local plan = BU.Merge.plan(items)
        if #plan.steps > 0 then
            local item = items[1]

            local sources, seen = {}, {}
            for _, candidate in ipairs(items) do
                local container = candidate:getContainer()
                if container and not seen[container] then
                    seen[container] = true
                    sources[#sources + 1] = { fullType = fullType, container = container }
                end
            end

            rows[#rows + 1] = {
                key = "merge|" .. fullType,
                entry = { merge = true, count = plan.total },
                sources = sources,
                sourceCount = plan.count,
                inputs = { {
                    label = getText("IGUI_BUUI_MergePartial"),
                    have = plan.count - plan.full,
                    need = plan.count,
                    satisfied = true,
                } },
                ready = true,
                max = #plan.steps,
                quantity = #plan.steps,
                name = item:getDisplayName(),
                result = getText("IGUI_BUUI_MergeResult",
                    tostring(plan.full + plan.partial), tostring(plan.count)),
                texture = item:getTexture(),
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.sourceCount ~= b.sourceCount then return a.sourceCount > b.sourceCount end
        return (a.name or "") < (b.name or "")
    end)

    return rows, containers
end

function BUUI.resolveRows(player, mode, scan)
    if mode == BUUI.MODE.MERGE then
        return BUUI.resolveMergeRows(player)
    end

    local bundling = mode == BUUI.MODE.BUNDLE
    local index = BUUI.getIndex()
    local containers, tally, sample
    if scan then
        containers, tally, sample = scan.containers, scan.tally, scan.sample
    else
        containers, tally, sample = BUUI.scanContainers(player)
    end
    local rows, byKey, surface = {}, {}, nil

    for fullType, count in pairs(tally) do
        local bucket = index[fullType]
        if bucket then
            for _, entry in ipairs(bucket) do
                if entry.bundling == bundling then
                    local item = sample[fullType]
                    local logic
                    logic, surface = BUUI_probeLogic(player, containers, surface)
                    logic:setRecipeFromContextClick(entry.recipe, item)

                    local inputs, satisfied = BUUI_describeInputs(logic, entry, fullType)
                    -- the flag is forceRecache: this logic was built a line ago and has
                    -- no cache to read, so asking for the cached count answers zero.
                    local max = logic:getPossibleCraftCount(true)
                    local outputs = BUUI.describeOutputs(logic, entry.recipe)
                    local ready = (satisfied and logic:canPerformCurrentRecipe() and max > 0) and true or false

                    local name = item:getDisplayName()
                    local result = BUUI_outputLabel(outputs)

                    -- dozens of items share a display name. keying on recipe, name and output
                    -- folds those together but keeps rows that give back different rope apart.
                    local key = entry.recipe:getScriptObjectFullType()
                        .. "|" .. name .. "|" .. tostring(result)

                    local source = {
                        fullType = fullType,
                        container = item:getContainer(),
                    }

                    local row = byKey[key]
                    if row then
                        row.sources[#row.sources + 1] = source
                        row.sourceCount = row.sourceCount + count
                        row.max = row.max + max

                        -- show the checks of a source that can run, so a ready row never
                        -- lists a blocked variant's ingredients.
                        if ready and not row.ready then
                            row.ready = true
                            row.inputs = inputs
                        end
                    else
                        row = {
                            key = key,
                            entry = entry,
                            sources = { source },
                            sourceCount = count,
                            inputs = inputs,
                            ready = ready,
                            max = max,
                            quantity = 1,
                            name = name,
                            result = result,
                            -- getResultTexture derefs getFirstInputItem() on every input, so a
                            -- row short an ingredient throws. describeOutputs already has the icon.
                            texture = (outputs[1] and outputs[1].texture)
                                or item:getTexture(),
                        }
                        byKey[key] = row
                        rows[#rows + 1] = row
                    end
                end
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.ready ~= b.ready then return a.ready end
        if a.entry.count ~= b.entry.count then return a.entry.count > b.entry.count end
        return (a.name or "") < (b.name or "")
    end)

    return rows, containers
end

Events.OnGameStart.Add(function()
    BUUI.buildIndex()
end)
