----------
--ESTRAL--
----------

require "BU_WeightData"

local cartons = nil

local function BU_perishableCartons()
    if cartons then
        return cartons
    end
    if not BU.Bundles or not BU.BaseCategory then
        return nil
    end

    cartons = {}
    for fullType in pairs(BU.Bundles) do
        if BU.BaseCategory[BU.resolveBase(fullType)] == "ReductionFood" then
            cartons[fullType] = true
        end
    end
    return cartons
end

local function BU_stampLootCartons(roomName, containerType, container)
    local gameTime = getGameTime()
    if not gameTime or not container then
        return
    end

    local perishable = BU_perishableCartons()
    if not perishable then
        return
    end

    local now = gameTime:getWorldAgeHours()
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and perishable[item:getFullType()] then
            local modData = item:getModData()
            if modData.buPackedAt == nil then
                modData.buFoodAge = 0
                modData.buPackedAt = now
            end
        end
    end
end

Events.OnFillContainer.Add(BU_stampLootCartons)
