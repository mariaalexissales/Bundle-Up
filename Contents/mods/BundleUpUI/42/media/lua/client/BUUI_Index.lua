----------
--ESTRAL--
----------

BUUI = BUUI or {}

-- Other packing mods can list their module here to appear in the panel; the
-- index keys off the recipe's module prefix rather than a tag so the base mod's
-- 67 recipes need no edits.
BUUI.modules = BUUI.modules or { BundleUp = true }

BUUI.recipes = nil

-- one input covers a whole family and each member can carry its own amount - the
-- boxed recipes write "item 10 [...;50:Base.NutsBolts;...]". the scalar getIntAmount
-- reads 1 for those, so the keyed lookup is the real number and the scalar a fallback.
local function BUUI_amountFor(input, fullName)
    local amount = fullName and input:getAmount(fullName)
    if not amount or amount < 1 then amount = input:getIntAmount() end
    return math.ceil(amount)
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

-- The bulk material is always the input asking for the most of something: Tie5
-- wants one rope and five planks, PackScrapSack one sandbag and 25 scrap. Going
-- by amount rather than by flags matters because flags[ItemCount;IsExclusive] is
-- applied inconsistently across the recipe files - BoxSmall carries none at all.
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
                -- Packing consumes many to make one and unpacking does the reverse, so the
                -- bulk amount tells the two apart without matching on recipe names.
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

    -- Deepest compaction first, so Tie10 outranks Tie5 in the list and Bundle All
    -- reaches for the tighter pack before the looser one competes for the planks.
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

-- Every item the player can reach, tallied by full type. The container list is
-- the same one the vanilla crafting window works from, so "nearby" means exactly
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

-- Mirrors ISInventoryPaneContextMenu.OnNewCraft, the path a double-click on a bundle
-- already takes today: every vanilla caller builds a fresh logic and gives it a craft
-- surface before asking whether the recipe can run.
local function BUUI_probeLogic(player, containers)
    local logic = HandcraftLogic.new(player, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(player, 2))
    logic:setContainers(containers)
    return logic
end

-- Bundle Up fans a single craftRecipe across a whole family through itemMapper,
-- so PackFoodCase alone has to become one row per carton actually present.
-- setRecipeFromContextClick pins the mapper to the sample item, which is what
-- makes the output name, icon and count come back resolved for that family.
-- An input can accept a whole family - PackFoodCase lists all 166 cartons - so the
-- first possible item is a coin toss, not the one in front of the player. Name what
-- the logic actually picked up, and fall back to the script's own list only when
-- nothing was picked up, which is exactly the missing-rope case worth naming.
local function BUUI_inputNames(logic, input)
    local chosen = logic:getSatisfiedInputItems(input)
    if chosen and chosen:size() > 0 then
        local item = chosen:get(0)
        local script = item:getScriptItem()
        return item:getDisplayName(), script and script:getFullName() or nil
    end

    local possible = input:getPossibleInputItems()
    if possible and possible:size() > 0 then
        local script = possible:get(0)
        return script:getDisplayName(), script:getFullName()
    end

    return "?", nil
end

local function BUUI_describeInputs(logic, entry)
    local parts, satisfied = {}, true

    local function describe(input)
        local ok = logic:isInputSatisfied(input) and true or false
        if not ok then satisfied = false end

        local label, fullName = BUUI_inputNames(logic, input)

        parts[#parts + 1] = {
            label = label,
            have = logic:getInputCount(input),
            need = BUUI_amountFor(input, fullName),
            satisfied = ok,
        }
    end

    describe(entry.pivot)
    for _, input in ipairs(entry.secondaries) do describe(input) end

    return parts, satisfied
end

-- Untying a bundle hands back the rope as well as the planks, so reading only the
-- first output would drop half of what the recipe makes. Automation-only outputs
-- are skipped the way the vanilla ingredients widget skips them.
--
-- BundleUp's mappers key on a combination of inputs, so Tie5 cannot resolve its
-- output until both the rope and the planks are in reach. The script's own list of
-- possible results covers the row that is still missing an ingredient.
function BUUI.describeOutputs(logic, recipe)
    local outputs, described = recipe:getOutputs(), {}
    if not outputs then return described end

    local data = logic:getRecipeData()

    for i = 0, outputs:size() - 1 do
        local script = outputs:get(i)
        if not script:isAutomationOnly() and script:getResourceType() == ResourceType.Item then
            local mapper = script.getOutputMapper and script:getOutputMapper()
            local item = data and mapper and mapper:getOutputItem(data, true)

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
                }
            end
        end
    end

    return described
end

-- What the row promises the player, and the only thing separating two bundles the
-- mod names identically: a rope-tied bundle of planks returns Rope, a sheet-rope
-- one returns Sheet Rope.
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

                    local inputs, satisfied = BUUI_describeInputs(logic, entry)
                    local max = logic:getPossibleCraftCount(false)
                    local outputs = BUUI.describeOutputs(logic, entry.recipe)
                    local ready = (satisfied and logic:canPerformCurrentRecipe() and max > 0) and true or false

                    local name = item:getDisplayName()
                    local result = BUUI_outputLabel(outputs)

                    -- Vanilla gives 56 pairs of these items one display name between
                    -- them, so keying on the type alone shows the player two rows it
                    -- cannot tell apart. Merging on what is actually drawn - recipe,
                    -- name and promised output - folds those together while keeping
                    -- rows that differ in the rope they hand back separate.
                    local key = entry.recipe:getScriptObjectFullType()
                        .. "|" .. name .. "|" .. tostring(result)

                    local source = {
                        fullType = fullType,
                        item = item,
                        count = count,
                        container = item:getContainer(),
                        max = max,
                    }

                    local row = byKey[key]
                    if row then
                        row.sources[#row.sources + 1] = source
                        row.sourceCount = row.sourceCount + count
                        row.max = row.max + max

                        -- Show the checks belonging to a source that can actually run,
                        -- so a row offering a Bundle button never lists a blocked
                        -- variant's ingredients.
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
