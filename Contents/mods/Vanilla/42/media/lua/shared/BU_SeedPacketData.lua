----------
--ESTRAL--
----------

BU = BU or {}
BU.SeedPackets = BU.SeedPackets or {}

-- the packet input of vanilla's PutSeedsInPacket, which only fills a packet named after
-- the seed going in.
BU.SeedPackets.Empty = {
    ["Base.BarleyBagSeed_Empty"]            = true,
    ["Base.BasilBagSeed_Empty"]             = true,
    ["Base.BellPepperBagSeed_Empty"]        = true,
    ["Base.BlackSageBagSeed_Empty"]         = true,
    ["Base.BroadleafPlantainBagSeed_Empty"] = true,
    ["Base.BroccoliBagSeed2_Empty"]         = true,
    ["Base.CabbageBagSeed2_Empty"]          = true,
    ["Base.CarrotBagSeed2_Empty"]           = true,
    ["Base.CauliflowerBagSeed_Empty"]       = true,
    ["Base.ChamomileBagSeed_Empty"]         = true,
    ["Base.ChivesBagSeed_Empty"]            = true,
    ["Base.CilantroBagSeed_Empty"]          = true,
    ["Base.ComfreyBagSeed_Empty"]           = true,
    ["Base.CommonMallowBagSeed_Empty"]      = true,
    ["Base.CornBagSeed_Empty"]              = true,
    ["Base.CucumberBagSeed_Empty"]          = true,
    ["Base.FlaxBagSeed_Empty"]              = true,
    ["Base.GarlicBagSeed_Empty"]            = true,
    ["Base.GreenpeasBagSeed_Empty"]         = true,
    ["Base.HabaneroBagSeed_Empty"]          = true,
    ["Base.HempBagSeed_Empty"]              = true,
    ["Base.HopsBagSeed_Empty"]              = true,
    ["Base.JalapenoBagSeed_Empty"]          = true,
    ["Base.KaleBagSeed_Empty"]              = true,
    ["Base.LavenderBagSeed_Empty"]          = true,
    ["Base.LeekBagSeed_Empty"]              = true,
    ["Base.LemonGrassBagSeed_Empty"]        = true,
    ["Base.LettuceBagSeed_Empty"]           = true,
    ["Base.MarigoldBagSeed_Empty"]          = true,
    ["Base.MintBagSeed_Empty"]              = true,
    ["Base.OnionBagSeed_Empty"]             = true,
    ["Base.OreganoBagSeed_Empty"]           = true,
    ["Base.ParsleyBagSeed_Empty"]           = true,
    ["Base.PoppyBagSeed_Empty"]             = true,
    ["Base.PotatoBagSeed2_Empty"]           = true,
    ["Base.PumpkinBagSeed_Empty"]           = true,
    ["Base.RedRadishBagSeed2_Empty"]        = true,
    ["Base.RoseBagSeed_Empty"]              = true,
    ["Base.RosemaryBagSeed_Empty"]          = true,
    ["Base.RyeBagSeed_Empty"]               = true,
    ["Base.SageBagSeed_Empty"]              = true,
    ["Base.SoybeansBagSeed_Empty"]          = true,
    ["Base.SpinachBagSeed_Empty"]           = true,
    ["Base.StrewberrieBagSeed2_Empty"]      = true,
    ["Base.SugarBeetBagSeed_Empty"]         = true,
    ["Base.SunflowerBagSeed_Empty"]         = true,
    ["Base.SweetPotatoBagSeed_Empty"]       = true,
    ["Base.ThymeBagSeed_Empty"]             = true,
    ["Base.TobaccoBagSeed_Empty"]           = true,
    ["Base.TomatoBagSeed2_Empty"]           = true,
    ["Base.TurnipBagSeed_Empty"]            = true,
    ["Base.WatermelonBagSeed_Empty"]        = true,
    ["Base.WheatBagSeed_Empty"]             = true,
    ["Base.WildGarlicBagSeed_Empty"]        = true,
    ["Base.ZucchiniBagSeed_Empty"]          = true,
}

function BU.SeedPackets.isEmpty(fullType)
    return BU.SeedPackets.Empty[fullType] == true
end
