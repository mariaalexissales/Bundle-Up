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

    ["BundleUp.NailsBox_Small"]   = { base = "Base.Nails",        count = 25  },
    ["BundleUp.NailsBox_Medium"]  = { base = "Base.Nails",        count = 50  },
    ["BundleUp.ScrewsBox_Small"]  = { base = "Base.Screws",       count = 25  },
    ["BundleUp.ScrewsBox_Medium"] = { base = "Base.Screws",       count = 50  },
    ["BundleUp.GoldScrap_Small"]  = { base = "Base.GoldScrap",    count = 50  },
    ["BundleUp.GoldScrap_Large"]  = { base = "Base.GoldScrap",    count = 100 },
    ["BundleUp.SilverScrap_Small"]= { base = "Base.SilverScrap",  count = 50  },
    ["BundleUp.SilverScrap_Large"]= { base = "Base.SilverScrap",  count = 100 },
    ["BundleUp.PenBox_Black"]     = { base = "Base.Pen",          count = 10  },
    ["BundleUp.PenBox_Blue"]      = { base = "Base.BluePen",      count = 10  },
    ["BundleUp.PenBox_Red"]       = { base = "Base.RedPen",       count = 10  },
    ["BundleUp.PenBox_Green"]     = { base = "Base.GreenPen",     count = 10  },

    ["BundleUp.WireCable_Small"]  = { base = "Base.Wire",           count = 5  },
    ["BundleUp.WireCable_Large"]  = { base = "Base.Wire",           count = 10 },
    ["BundleUp.SmallMetalSheetS"] = { base = "Base.SmallSheetMetal", count = 5  },
    ["BundleUp.SmallMetalSheetL"] = { base = "Base.SmallSheetMetal", count = 10 },
    ["BundleUp.GingerAleSP"]      = { base = "Base.SodaCan",        count = 6  },
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
    ["Base.Plank"]           = "ReductionWood",
    ["Base.StoneBlock"]      = "ReductionStone",
}

-- A pack's base is usually a vanilla item, but a nested pack names another
-- pack instead. Walking down to the vanilla item at the bottom gives the
-- category lookup something it can match and the total unit count.
local MAX_DEPTH = 16

function BU.resolveBase(fullType)
    local def = BU.Bundles[fullType]
    if not def then
        return nil, 0
    end

    local base = def.base
    local count = def.count
    for _ = 1, MAX_DEPTH do
        local parent = BU.Bundles[base]
        if not parent then
            return base, count
        end
        count = count * parent.count
        base = parent.base
    end
    return nil, 0
end

function BU.nestingDepth(fullType)
    local depth = 0
    local def = BU.Bundles[fullType]
    while def and depth <= MAX_DEPTH do
        local parent = BU.Bundles[def.base]
        if not parent then
            return depth
        end
        depth = depth + 1
        def = parent
    end
    return depth
end
