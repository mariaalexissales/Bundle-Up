----------
--ESTRAL--
----------

BU = BU or {}

BU.Bundles = {
    ["BundleUp.GingerAleSP"]      = { base = "Base.Pop3",            count = 6 },
    ["BundleUp.SodaPack"]         = { base = "Base.Pop2",            count = 6 },
    ["BundleUp.DietSodaPack"]     = { base = "Base.Pop",             count = 6 },
    ["BundleUp.BlueberrySP"]      = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.BubblegumSP"]      = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.GrapeSP"]          = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.LimeSP"]           = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.OrangeSP"]         = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.PineappleSP"]      = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.StrawberrySP"]     = { base = "Base.SodaCan",         count = 6 },
    ["BundleUp.VarietyPack"]      = { base = "Base.SodaCan",         count = 6 },
}

BU.BaseCategory = {
    ["Base.SodaCan"]         = "ReductionMetal",
    ["Base.Pop"]             = "ReductionMetal",
    ["Base.Pop2"]            = "ReductionMetal",
    ["Base.Pop3"]            = "ReductionMetal",
}

-- keyed by the pack's own base, not resolveBase, or a case's cut lands on its carton too.
BU.BaseReduction = {
    ["Base.IronOre"]                      = 90,
    ["Base.CopperOre"]                    = 90,
    ["Base.LargeStone"]                   = 90,
    ["Base.IronBloom"]                    = 80,
    ["Base.GoldBar"]                      = 75,
    ["Base.HematiteLarge"]                = 70,
    ["Base.MalachiteLarge"]               = 70,
    ["Base.FlatStone"]                    = 60,
    ["Base.LargePlank"]                   = 60,
    ["Base.SilverBar"]                    = 50,
    ["BundleUp.Cornflour2Carton"]         = 50,
    ["BundleUp.Cornmeal2Carton"]          = 50,
    ["BundleUp.DriedBlackBeansCarton"]    = 50,
    ["BundleUp.DriedChickpeasCarton"]     = 50,
    ["BundleUp.DriedKidneyBeansCarton"]   = 50,
    ["BundleUp.DriedLentilsCarton"]       = 50,
    ["BundleUp.DriedSplitPeasCarton"]     = 50,
    ["BundleUp.DriedWhiteBeansCarton"]    = 50,
    ["BundleUp.Flour2Carton"]             = 50,
    ["BundleUp.MacaroniCarton"]           = 50,
    ["BundleUp.PastaCarton"]              = 50,
    ["BundleUp.RiceCarton"]               = 50,
    ["BundleUp.DogFoodBagCrate"]          = 50,
    ["Base.Hematite"]                     = 40,
    ["Base.Malachite"]                    = 40,
    ["Base.IronIngot"]                    = 35,
    ["Base.SteelIngot"]                   = 35,
    ["Base.CopperIngot"]                  = 35,
    ["Base.PiercedIronIngot"]             = 35,
    ["Base.PiercedSteelIngot"]            = 35,
    ["Base.LargeBranch"]                  = 35,
    ["Base.BrassIngot"]                   = 20,
    ["Base.Coke"]                         = 20,
    ["Base.CompostBag"]                   = 20,
    ["Base.ConcretePowder"]               = 20,
    ["Base.PlasterPowder"]                = 20,
    ["Base.Fertilizer"]                   = 20,
    ["Base.DuctTapeBox"]                  = 20,
    ["Base.CowLeather_Angus_Fur_Tan"]     = 20,
    ["Base.CowLeather_Holstein_Fur_Tan"]  = 20,
    ["Base.CowLeather_Simmental_Fur_Tan"] = 20,
    ["Base.Leather_Crude_Large_Tan"]      = 20,
    ["Base.CowLeather_Angus_Fur"]         = 20,
    ["Base.CowLeather_Angus_Fur_Tan_Wet"] = 20,
    ["Base.CowLeather_Angus_Full"]        = 20,
    ["Base.CowLeather_Holstein_Fur"]      = 20,
    ["Base.CowLeather_Holstein_Fur_Tan_Wet"] = 20,
    ["Base.CowLeather_Holstein_Full"]     = 20,
    ["Base.CowLeather_Simmental_Fur"]     = 20,
    ["Base.CowLeather_Simmental_Fur_Tan_Wet"] = 20,
    ["Base.CowLeather_Simmental_Full"]    = 20,
    ["Base.Leather_Crude_Large"]          = 20,
    ["Base.Leather_Crude_Large_Tan_Wet"]  = 20,
}

local MAX_DEPTH = 16

function BU.resolveBase(fullType)
    local def = BU.Bundles[fullType]
    if not def then
        return nil
    end

    local base = def.base
    for _ = 1, MAX_DEPTH do
        local parent = BU.Bundles[base]
        if not parent then
            return base
        end
        base = parent.base
    end
    return nil
end

function BU.nestingDepth(fullType)
    local def = BU.Bundles[fullType]
    for depth = 0, MAX_DEPTH do
        if not def then
            return depth
        end
        local parent = BU.Bundles[def.base]
        if not parent then
            return depth
        end
        def = parent
    end
    return MAX_DEPTH
end
