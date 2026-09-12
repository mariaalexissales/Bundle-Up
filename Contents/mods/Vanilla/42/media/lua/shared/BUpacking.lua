----------
--ESTRAL--
----------

require "BU_ApplySpoilage"

BU = BU or {}
BUInv = BUInv or {}

PACK_FLAVORS = {
    ["BundleUp.BlueberrySP"]  = "SodaBlueberry",
    ["BundleUp.BubblegumSP"]  = "SodaBubblegum",
    ["BundleUp.LimeSP"]       = "SodaLime",
    ["BundleUp.OrangeSP"]     = "SodaPop",
    ["BundleUp.GrapeSP"]      = "SodaGrape",
    ["BundleUp.PineappleSP"]  = "SodaPineapple",
    ["BundleUp.StrawberrySP"] = "SodaStrewberry",
}

function BU.worldAgeHours()
    local gameTime = getGameTime()
    if not gameTime then return nil end
    return gameTime:getWorldAgeHours()
end

function BUInv.unpackSodaPack(craftRecipeData, character)
    local sodaPack = craftRecipeData:getAllConsumedItems():get(0)
    local sodaFluidName = PACK_FLAVORS[sodaPack:getFullType()]
    if not sodaFluidName then
        return
    end
    local sodaType = Fluid.Get(sodaFluidName)
    if not sodaType then
        return
    end

    local outputItems = craftRecipeData:getAllCreatedItems()
    for i = 0, outputItems:size() - 1 do
        local can = outputItems:get(i)
        local fluidContainer = can:getFluidContainer()
        if fluidContainer then
            fluidContainer:Empty()
            fluidContainer:addFluid(sodaType, 1.0)
            ItemCodeOnCreate.onCreateSodaCan(can)
        end
    end
end

local function BU_refillCreatedCans(craftRecipeData, fluid)
    local outputItems = craftRecipeData:getAllCreatedItems()
    for i = 0, outputItems:size() - 1 do
        local can = outputItems:get(i)
        -- the rope comes out in this same list, and has no fluid container
        local fluidContainer = can:getFluidContainer()
        if fluidContainer then
            fluidContainer:Empty()
            if fluid then
                fluidContainer:addFluid(fluid, fluidContainer:getCapacity())
            end
        end
    end
end

function BUInv.unpackFullGasCans(craftRecipeData, character)
    local petrol = Fluid.Get("Petrol")
    if not petrol then
        return
    end
    BU_refillCreatedCans(craftRecipeData, petrol)
end

function BUInv.unpackEmptyGasCans(craftRecipeData, character)
    -- PetrolCan's script Fluids block is initial contents, so a created can spawns
    -- with a full 10L. empty it or the bundle mints petrol.
    BU_refillCreatedCans(craftRecipeData, nil)
end

local BU_pendingShells = {}
local BU_shellSweepQueued = false

local function BU_shellType(item)
    local script = item:getScriptItem()
    if not script then
        return nil
    end
    local shell = script:getReplaceOnDeplete()
    if not shell or shell == "" then
        return nil
    end
    if not string.find(shell, ".", 1, true) then
        shell = item:getModule() .. "." .. shell
    end
    return shell
end

local function BU_takeShellFromSquare(square, fullType)
    local worldObjects = square:getWorldObjects()
    for i = worldObjects:size() - 1, 0, -1 do
        local worldObject = worldObjects:get(i)
        local item = worldObject:getItem()
        if item and item:getFullType() == fullType then
            square:transmitRemoveItemFromSquare(worldObject)
            square:removeWorldObject(worldObject)
            return true
        end
    end
    return false
end

local function BU_takeShellFromContainer(container, fullType)
    local items = container:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item:getFullType() == fullType then
            container:DoRemoveItem(item)
            sendRemoveItemFromContainer(container, item)
            return true
        end
    end
    return false
end

local function BU_sweepShells()
    Events.OnTick.Remove(BU_sweepShells)
    BU_shellSweepQueued = false

    local pending = BU_pendingShells
    BU_pendingShells = {}
    for _, shell in ipairs(pending) do
        local taken = shell.square ~= nil and BU_takeShellFromSquare(shell.square, shell.type)
        if not taken and shell.container then
            BU_takeShellFromContainer(shell.container, shell.type)
        end
    end
end

function BUInv.stripMintedShells(craftRecipeData, character)
    -- an ItemCount input is drained of every use, so ReplaceOnDeplete fires and
    -- each full bag hands back its empty sack too. no recipe flag suppresses
    -- that branch, and onCreate runs before processDestroyAndUsedItems mints
    -- them - so note where each one will land and take it on the next tick.
    local consumed = craftRecipeData:getAllConsumedItems()
    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        local shellType = item and BU_shellType(item)
        if shellType then
            local worldItem = item:getWorldItem()
            BU_pendingShells[#BU_pendingShells + 1] = {
                type = shellType,
                square = worldItem and worldItem:getSquare() or nil,
                container = item:getContainer(),
            }
        end
    end

    if #BU_pendingShells > 0 and not BU_shellSweepQueued then
        BU_shellSweepQueued = true
        Events.OnTick.Add(BU_sweepShells)
    end
end

local function BU_isCanOfFlavor(can, fluidName)
    local fluidContainer = can:getFluidContainer()
    if not fluidContainer or not fluidContainer:isFull() then
        return false
    end
    local fluid = fluidContainer:getPrimaryFluid()
    return fluid ~= nil and fluid:getFluidTypeString() == fluidName
end

-- these names are built by string, so grepping for testPackOrangeSodaCan finds
-- nothing. the recipes that call them are in recipes_bundled.txt.
for packType, fluidName in pairs(PACK_FLAVORS) do
    local flavor = packType:match("%.(.+)SP$")
    BUInv["testPack" .. flavor .. "SodaCan"] = function(item, character)
        return BU_isCanOfFlavor(item, fluidName)
    end
end

function BUInv.testPackPerishable(item, character)
    -- isRotten is Food-only. the non-perishable cartons are base:normal, so this
    -- guard is what keeps the handcraft window from dying on them.
    return item == nil or not item:IsFood() or not item:isRotten()
end

function BUInv.testPackEmptyMagazine(item, character)
    return item == nil or item:getCurrentAmmoCount() <= 0
end

local function BU_shelfLife(item)
    local life = item:getOffAgeMax()
    if life == nil or life <= 0 then
        return nil
    end
    return life
end

function BUInv.carryFoodAge(craftRecipeData, character)
    local consumed = craftRecipeData:getAllConsumedItems()

    local oldest, softest, oldestRank = nil, nil, nil
    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        if item and item:IsFood() then
            BU.refreshPack(item)

            local life = BU_shelfLife(item)
            local rank = life and (item:getAge() / life) or item:getAge()
            if oldestRank == nil or rank > oldestRank then
                oldest, oldestRank = item, rank
            end
            if softest == nil or item:getFreezingTime() < softest:getFreezingTime() then
                softest = item
            end
        end
    end
    if oldest == nil then
        return
    end

    local sourceLife = BU_shelfLife(oldest)
    local now = BU.worldAgeHours()
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local item = created:get(i)
        if item and item:IsFood() then
            -- a carton's rot thresholds are stretched by the spoilage rate and its
            -- contents' are not, so raw days leak the stretch across the boundary.
            -- carry the fraction of shelf life instead.
            local life = BU_shelfLife(item)
            local age = oldest:getAge()
            if life and sourceLife then
                age = age * (life / sourceLife)
            end

            item:setAge(age)
            if now ~= nil then
                item:setLastAged(now)
            end
            -- new Food has lastFrozenUpdate = 0, so stamping freeze first gets it
            -- melted on the next tick. updateAge sets the timestamp.
            item:updateAge()
            item:copyFrozenFrom(softest)
        end
    end
end
