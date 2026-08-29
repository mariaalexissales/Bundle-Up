----------
--ESTRAL--
----------

BU = BU or {}

BU.Bundles = {
    ["BundleUp.PlankR"]         = { base = "Base.Plank",          count = 5  },
    ["BundleUp.PlankSR"]        = { base = "Base.Plank",          count = 5  },
    ["BundleUp.SheetMetalR"]    = { base = "Base.SheetMetal",     count = 5  },
    ["BundleUp.SheetMetalSR"]   = { base = "Base.SheetMetal",     count = 5  },
    ["BundleUp.IronPipesR"]     = { base = "Base.MetalPipe",      count = 5  },
    ["BundleUp.IronPipesSR"]    = { base = "Base.MetalPipe",      count = 5  },
    ["BundleUp.IronBarR"]       = { base = "Base.IronBar",        count = 5  },
    ["BundleUp.IronBarSR"]      = { base = "Base.IronBar",        count = 5  },
    ["BundleUp.PlankLR"]        = { base = "Base.Plank",          count = 10 },
    ["BundleUp.PlankLSR"]       = { base = "Base.Plank",          count = 10 },
    ["BundleUp.SheetMetalLR"]   = { base = "Base.SheetMetal",     count = 10 },
    ["BundleUp.SheetMetalLSR"]  = { base = "Base.SheetMetal",     count = 10 },
    ["BundleUp.IronPipesLR"]    = { base = "Base.MetalPipe",      count = 10 },
    ["BundleUp.IronPipesLSR"]   = { base = "Base.MetalPipe",      count = 10 },
    ["BundleUp.IronBarLR"]      = { base = "Base.IronBar",        count = 10 },
    ["BundleUp.IronBarLSR"]     = { base = "Base.IronBar",        count = 10 },
    ["BundleUp.GasCanR"]        = { base = "Base.PetrolCan",      count = 4  },
    ["BundleUp.GasCanSR"]       = { base = "Base.PetrolCan",      count = 4  },
    ["BundleUp.GasCanFullR"]    = { base = "Base.PetrolCan",      count = 4, fluid = 10 },
    ["BundleUp.GasCanFullSR"]   = { base = "Base.PetrolCan",      count = 4, fluid = 10 },

    ["BundleUp.NailsBox_Small"]   = { base = "Base.Nails",        count = 25  },
    ["BundleUp.NailsBox_Medium"]  = { base = "Base.Nails",        count = 50  },
    ["BundleUp.ScrewsBox_Small"]  = { base = "Base.Screws",       count = 25  },
    ["BundleUp.ScrewsBox_Medium"] = { base = "Base.Screws",       count = 50  },
    ["BundleUp.GoldScrap_Small"]  = { base = "Base.GoldScrap",    count = 50  },
    ["BundleUp.GoldScrap_Large"]  = { base = "Base.GoldScrap",    count = 100 },
    ["BundleUp.SilverScrap_Small"]= { base = "Base.SilverScrap",  count = 50  },
    ["BundleUp.SilverScrap_Large"]= { base = "Base.SilverScrap",  count = 100 },
    ["BundleUp.Coke_Small"]       = { base = "Base.Coke",         count = 50  },
    ["BundleUp.Coke_Large"]       = { base = "Base.Coke",         count = 100 },
    ["BundleUp.PenBox_Black"]     = { base = "Base.Pen",          count = 10  },
    ["BundleUp.PenBox_Blue"]      = { base = "Base.BluePen",      count = 10  },
    ["BundleUp.PenBox_Red"]       = { base = "Base.RedPen",       count = 10  },
    ["BundleUp.PenBox_Green"]     = { base = "Base.GreenPen",     count = 10  },

    ["BundleUp.WireCable_Small"]  = { base = "Base.Wire",           count = 5  },
    ["BundleUp.WireCable_Large"]  = { base = "Base.Wire",           count = 10 },
    ["BundleUp.SmallMetalSheetS"] = { base = "Base.SmallSheetMetal", count = 5  },
    ["BundleUp.SmallMetalSheetL"] = { base = "Base.SmallSheetMetal", count = 10 },
    ["BundleUp.GingerAleSP"]      = { base = "Base.Pop3",          count = 6  },
    ["BundleUp.SodaPack"]         = { base = "Base.Pop2",          count = 6  },
    ["BundleUp.DietSodaPack"]     = { base = "Base.Pop",           count = 6  },
    ["BundleUp.BlueberrySP"]      = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.BubblegumSP"]      = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.GrapeSP"]          = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.LimeSP"]           = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.OrangeSP"]         = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.PineappleSP"]      = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.StrawberrySP"]     = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.VarietyPack"]      = { base = "Base.SodaCan",        count = 6  },
    ["BundleUp.StoneBlockPack"]   = { base = "Base.StoneBlock",     count = 10 },

    ["BundleUp.Sack_Sack"]        = { base = "Base.EmptySandbag",   count = 5  },

}

BU.BaseCategory = {
    ["Base.Nails"]           = "ReductionMetal",
    ["Base.Screws"]          = "ReductionMetal",
    ["Base.GoldScrap"]       = "ReductionMetal",
    ["Base.SilverScrap"]     = "ReductionMetal",
    ["Base.Wire"]            = "ReductionMetal",
    ["Base.SmallSheetMetal"] = "ReductionMetal",
    ["Base.SheetMetal"]      = "ReductionMetal",
    ["Base.MetalPipe"]       = "ReductionMetal",
    ["Base.IronBar"]         = "ReductionMetal",
    ["Base.SodaCan"]         = "ReductionMetal",
    ["Base.Pop"]             = "ReductionMetal",
    ["Base.Pop2"]            = "ReductionMetal",
    ["Base.Pop3"]            = "ReductionMetal",
    ["Base.Plank"]           = "ReductionWood",
    -- coke is forge fuel, not timber; it rides the wood slider with charcoal.
    ["Base.Coke"]            = "ReductionWood",
    ["Base.StoneBlock"]      = "ReductionStone",
    ["Base.PetrolCan"]       = "ReductionOther",
}

-- A pack's base is usually a vanilla item, but a nested pack names another
-- pack instead. Walking down to the vanilla item at the bottom gives the
-- category lookup something it can match.
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
