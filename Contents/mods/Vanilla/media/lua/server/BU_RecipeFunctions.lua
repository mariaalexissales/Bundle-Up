----------
--ESTRAL--
----------

require "BU_WeightData"

local function give(player, fullType, count)
    local inv = player:getInventory()
    for _ = 1, (count or 1) do
        inv:AddItem(fullType)
    end
end

function Recipe.OnCreate.BUGiveRope(items, result, player)
    give(player, "Base.Rope", 1)
end

function Recipe.OnCreate.BUGiveSheetRope(items, result, player)
    give(player, "Base.SheetRope", 1)
end

function Recipe.OnCreate.BUGiveSandbag(items, result, player)
    give(player, "Base.EmptySandbag", 1)
end

function Recipe.OnTest.BUIsNotFavorite(item, result)
    return not item:isFavorite()
end

function Recipe.OnCreate.BUSaveFood(items, result, player)
    local worst = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsFood() and item:getAge() > worst then
            worst = item:getAge()
        end
    end
    result:getModData().buFoodAge = worst
end

function Recipe.OnCreate.BULoadFood(items, result, player)
    local carton = items:get(0)
    if not carton then return end

    local def = BU and BU.Bundles and BU.Bundles[carton:getFullType()]
    if not def then
        print("[BundleUp] no bundle data for " .. tostring(carton:getFullType()))
        return
    end

    local age = carton:getModData().buFoodAge or 0
    if result and result:IsFood() then
        result:setAge(age)
    end

    local inv = player:getInventory()
    for _ = 2, def.count do
        local food = inv:AddItem(def.base)
        if food and food:IsFood() then
            food:setAge(age)
        end
    end
end
