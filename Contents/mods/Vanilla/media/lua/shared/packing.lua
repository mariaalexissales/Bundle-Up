BUInv = BUInv or {}

local function isFood(item)
    return item and instanceof(item, "Food") and item:getDisplayCategory() == "Food" and item:getCurrentUses() > 0 and not item:isPackaged()
end

function BUInv.IsFavorite(items, result)
    return not items:isFavorite()
end

function BUInv.IsFood(items, result)
    return isFood(items)
end