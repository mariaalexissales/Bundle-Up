----------
--ESTRAL--
----------

BUUI = BUUI or {}

-- keyed off the recipe's module prefix rather than a tag, so the base mod's 67 recipes
-- need no edits and another packing mod only has to name its module here.
BUUI.modules = BUUI.modules or { BundleUp = true }

BUUI.recipes = nil

-- one input covers a whole family and each member can carry its own amount - the
-- boxed recipes write "item 10 [...;50:Base.NutsBolts;...]". the scalar getIntAmount
-- reads 1 for those, so the keyed lookup is the real number and the scalar a fallback.
local function BUUI_amountFor(input, fullName)
    local amount = fullName and input:getIntAmount(fullName) or 0
    if amount < 1 then amount = input:getIntAmount() end
    return amount
end

local function BUUI_largestAmount(input)
    local possible = input:getPossibleInputItems()
    if not possible or possible:size() == 0 then return input:getIntAmount() end

    local largest = 0
    for i = 0, possible:size() - 1 do
        local amount = BUUI_amountFor(input, possible:get(i):getFullName())
        if amount > largest then largest = amount end
    end

    return largest
end

-- the bulk material is the input asking for the most of something - Tie5 wants one
-- rope and five planks. going by amount rather than flags[ItemCount] matters because
-- the flags are inconsistent across the recipe files: BoxSmall carries none at all.
local function BUUI_splitInputs(recipe)
    local inputs = recipe:getInputs()
    if not inputs or inputs:size() == 0 then return nil, nil, 0 end

    local pivot, bulk, others = nil, 0, {}
    for i = 0, inputs:size() - 1 do
        local input = inputs:get(i)
        if input:getResourceType() == ResourceType.Item and not input:isAutomationOnly() then
            local amount = BUUI_largestAmount(input)
            if not pivot or amount > bulk then
                if pivot then others[#others + 1] = pivot end
                pivot, bulk = input, amount
            else
                others[#others + 1] = input
            end
        end
    end

    return pivot, others, bulk
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
        if module and BUUI.modules[module] then
            local pivot, others, bulk = BUUI_splitInputs(recipe)
            if pivot then
                -- packing consumes many to make one and unpacking does the reverse, so
                -- the bulk amount sorts the two without matching on recipe names.
                local bundling = bulk >= 2

                local possible = pivot:getPossibleInputItems()
                if possible then
                    for n = 0, possible:size() - 1 do
                        local fullName = possible:get(n):getFullName()
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
                            count = BUUI_amountFor(pivot, fullName),
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

-- the same container list the vanilla crafting window works from, so "nearby" means
-- what it means everywhere else in the game.
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

-- mirrors ISInventoryPaneContextMenu.OnNewCraft: every vanilla caller builds a fresh
-- logic and gives it a craft surface before asking whether the recipe can run.
local function BUUI_probeLogic(player, containers)
    local logic = HandcraftLogic.new(player, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(player, 2))
    logic:setContainers(containers)
    return logic
end

-- an input can accept a whole family - PackFoodCase lists all 166 cartons - so the
-- first possible item is a coin toss, not the one in front of the player. wanted is
-- the type the row was built from; only the pivot knows it, a secondary passes nil.
local function BUUI_inputNames(logic, input, wanted)
    -- both lists hold the same kind of object, so vanilla swaps one for the other and
    -- reads them alike (ISWidgetInput:197). the fallback is the missing-rope case.
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

-- untying hands back the rope as well as the planks, so reading only the first output
-- drops half of what the recipe makes. the mapper cannot resolve until every input is
-- in reach, so the script's own result list covers a row still short an ingredient.
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

-- what the row promises the player, and part of the key that keeps two bundles of the
-- same name apart.
local function BUUI_outputLabel(outputs)
    if #outputs == 0 then return nil end

    local parts = {}
    for _, output in ipairs(outputs) do
        parts[#parts + 1] = tostring(output.amount) .. " " .. output.name
    end

    return table.concat(parts, " + ")
end

function BUUI.resolveRows(player, bundling)
    local index = BUUI.getIndex()
    local containers, tally, sample = BUUI.scanContainers(player)
    local rows, byKey = {}, {}

    for fullType, count in pairs(tally) do
        local bucket = index[fullType]
        if bucket then
            for _, entry in ipairs(bucket) do
                if entry.bundling == bundling then
                    local item = sample[fullType]
                    local logic = BUUI_probeLogic(player, containers)
                    logic:setRecipeFromContextClick(entry.recipe, item)

                    local inputs, satisfied = BUUI_describeInputs(logic, entry, fullType)
                    -- the flag is forceRecache: this logic was built a line ago and has
                    -- no cache to read, so asking for the cached count answers zero.
                    local max = logic:getPossibleCraftCount(true)
                    local outputs = BUUI.describeOutputs(logic, entry.recipe)
                    local ready = (satisfied and logic:canPerformCurrentRecipe() and max > 0) and true or false

                    local name = item:getDisplayName()
                    local result = BUUI_outputLabel(outputs)

                    -- dozens of these items share a display name, so merging on what is
                    -- drawn - recipe, name, output - folds the duplicates together while
                    -- keeping rows that hand back different rope apart.
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
                            texture = logic:getResultTexture()
                                or (outputs[1] and outputs[1].texture)
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
