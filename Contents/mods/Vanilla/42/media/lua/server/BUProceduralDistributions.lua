local PACK_ITEMS = {
    "BundleUp.BlueberrySP",
    "BundleUp.BubblegumSP",
    "BundleUp.GrapeSP",
    "BundleUp.LimeSP",
    "BundleUp.OrangeSP",
    "BundleUp.PineappleSP",
    "BundleUp.StrawberrySP",
    "BundleUp.GingerAleSP",
    "BundleUp.VarietyPack",
}

local PACK_WEIGHTS = {
    BandPracticeFridge  = 0.1,
    BarCounterMisc      = 0.2,
    BeerGardenCounter   = 0.01,
    BreweryCans         = 0.45,
    CafeteriaDrinks     = 0.2,
    CrateBeer           = 0.05,
    FridgeBeer          = 0.01,
    FridgeGarage        = 0.1,
    FridgeGeneric       = 0.005,
    FridgeHoarder       = 0.1,
    FridgeHunter        = 0.9,
    FridgeSoda          = 0.55,
    FridgeTrailerPark   = 0.01,
    JuiceStandFridge    = 1.65,
    KitchenBottles      = 0.45,
    LiquorStoreBeer     = 0.1,
    NolansFridge        = 0.01,
    SafehouseBooze      = 0.1,
    SafehouseFood       = 0.45,
    SafehouseFood_Mid   = 0.1,
    SafehouseFridge     = 0.45,
    SafehouseFridge_Mid = 0.1,
    StoreShelfDrinks    = 1.65,
    TheatreDrinks       = 0.45,
}

local ProceduralDistributions_list = ProceduralDistributions.list
local table_insert = table.insert

for tableName, weight in pairs(PACK_WEIGHTS) do
    local distribution = ProceduralDistributions_list[tableName]
    local items = distribution and distribution.items
    if items then
        for i = 1, #PACK_ITEMS do
            table_insert(items, PACK_ITEMS[i])
            table_insert(items, weight)
        end
    end
end
