----------
--ESTRAL--
----------

local ProceduralDistributions_list = ProceduralDistributions.list
local table_insert = table.insert

-- SandboxVars.BundleUp is nil at file-load time (initSandboxVars() hasn't run yet),
-- so items go in at base weight now and get recorded here for BU_applySpawnRates()
-- to rescale in place once the sandbox options actually exist.
local registry = {}

local function BU_applyDistribution(option, items, weights)
    local slots = registry[option]
    if not slots then
        slots = {}
        registry[option] = slots
    end
    for tableName, weight in pairs(weights) do
        local distribution = ProceduralDistributions_list[tableName]
        local containerItems = distribution and distribution.items
        if containerItems then
            for i = 1, #items do
                table_insert(containerItems, items[i])
                table_insert(containerItems, weight)
                slots[#slots + 1] = {
                    items = containerItems,
                    index = #containerItems,
                    name  = items[i],
                    base  = weight,
                }
            end
        end
    end
end

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

BU_applyDistribution("SpawnSixPacks", PACK_ITEMS, PACK_WEIGHTS)

local FOOD_ITEMS = {
    "BundleUp.BBQSauceCarton",
    "BundleUp.BalsamicVinegarCarton",
    "BundleUp.BeefJerkyCarton",
    "BundleUp.CandyCaramelsCarton",
    "BundleUp.CandyCornCarton",
    "BundleUp.CandyFruitSlicesCarton",
    "BundleUp.CandyGummyfishCarton",
    "BundleUp.CandyMolassesCarton",
    "BundleUp.CandyNovapopsCarton",
    "BundleUp.CandycaneCarton",
    "BundleUp.ChocolateCarton",
    "BundleUp.ChocolateChipsCarton",
    "BundleUp.Chocolate_ButterchunkersCarton",
    "BundleUp.Chocolate_CandyCarton",
    "BundleUp.Chocolate_CrackleCarton",
    "BundleUp.Chocolate_DeuxCarton",
    "BundleUp.Chocolate_GalacticDairyCarton",
    "BundleUp.Chocolate_RoysPBPucksCarton",
    "BundleUp.Chocolate_SmirkersCarton",
    "BundleUp.Chocolate_SnikSnakCarton",
    "BundleUp.CilantroDriedCarton",
    "BundleUp.CookieChocolateChipCarton",
    "BundleUp.CookieJellyCarton",
    "BundleUp.CookiesChocolateCarton",
    "BundleUp.CookiesOatmealCarton",
    "BundleUp.CookiesShortbreadCarton",
    "BundleUp.Cornflour2Carton",
    "BundleUp.Cornmeal2Carton",
    "BundleUp.CrackersCarton",
    "BundleUp.CrispsCarton",
    "BundleUp.Crisps2Carton",
    "BundleUp.Crisps3Carton",
    "BundleUp.Crisps4Carton",
    "BundleUp.DehydratedMeatStickCarton",
    "BundleUp.Dip_SalsaCarton",
    "BundleUp.DriedBlackBeansCarton",
    "BundleUp.DriedChickpeasCarton",
    "BundleUp.DriedKidneyBeansCarton",
    "BundleUp.DriedLentilsCarton",
    "BundleUp.DriedSplitPeasCarton",
    "BundleUp.Flour2Carton",
    "BundleUp.GrahamCrackersCarton",
    "BundleUp.GranolaBarCarton",
    "BundleUp.GumCarton",
    "BundleUp.GummyBearsCarton",
    "BundleUp.GummyWormsCarton",
    "BundleUp.HardCandiesCarton",
    "BundleUp.HiHisCarton",
    "BundleUp.HoneyCarton",
    "BundleUp.JamFruitCarton",
    "BundleUp.JamMarmaladeCarton",
    "BundleUp.JellyBeansCarton",
    "BundleUp.JujubesCarton",
    "BundleUp.KetchupCarton",
    "BundleUp.LardCarton",
    "BundleUp.LavenderPetalsDriedCarton",
    "BundleUp.LicoriceBlackCarton",
    "BundleUp.LicoriceRedCarton",
    "BundleUp.MacaroniCarton",
    "BundleUp.MapleSyrupCarton",
    "BundleUp.MargarineCarton",
    "BundleUp.MarinaraCarton",
    "BundleUp.MarshmallowsCarton",
    "BundleUp.MustardCarton",
    "BundleUp.OatsRawCarton",
    "BundleUp.OilOliveCarton",
    "BundleUp.OilVegetableCarton",
    "BundleUp.PeanutButterCarton",
    "BundleUp.PepperCarton",
    "BundleUp.PepperHabaneroCarton",
    "BundleUp.PepperJalapenoCarton",
    "BundleUp.PepperJalapenoDriedCarton",
    "BundleUp.PlonkiesCarton",
    "BundleUp.PopcornCarton",
    "BundleUp.PorkRindsCarton",
    "BundleUp.PowderedGarlicCarton",
    "BundleUp.PowderedOnionCarton",
    "BundleUp.PretzelCarton",
    "BundleUp.RamenCarton",
    "BundleUp.RiceVinegarCarton",
    "BundleUp.RockCandyCarton",
    "BundleUp.ScoutCookiesCarton",
    "BundleUp.SeasoningSaltCarton",
    "BundleUp.Seasoning_BasilCarton",
    "BundleUp.Seasoning_ChivesCarton",
    "BundleUp.Seasoning_CilantroCarton",
    "BundleUp.Seasoning_OreganoCarton",
    "BundleUp.Seasoning_ParsleyCarton",
    "BundleUp.Seasoning_RosemaryCarton",
    "BundleUp.Seasoning_SageCarton",
    "BundleUp.Seasoning_ThymeCarton",
    "BundleUp.SesameOilCarton",
    "BundleUp.SnoGlobesCarton",
    "BundleUp.SoysauceCarton",
    "BundleUp.SugarCarton",
    "BundleUp.SugarBrownCarton",
    "BundleUp.Teabag2Carton",
    "BundleUp.ThymeDriedCarton",
    "BundleUp.YoghurtCarton",
    "BundleUp.BasilDriedCarton",
    "BundleUp.BellPepperCarton",
    "BundleUp.BlackSageDriedCarton",
    "BundleUp.BroccoliCarton",
    "BundleUp.ButterCarton",
    "BundleUp.CabbageCarton",
    "BundleUp.CarrotsCarton",
    "BundleUp.CauliflowerCarton",
    "BundleUp.CerealCarton",
    "BundleUp.ChamomileDriedCarton",
    "BundleUp.CheeseCarton",
    "BundleUp.ChivesDriedCarton",
    "BundleUp.ChocoCakesCarton",
    "BundleUp.ChocolateCoveredCoffeeBeansCarton",
    "BundleUp.CinnamonRollCarton",
    "BundleUp.CocoaPowderCarton",
    "BundleUp.Coffee2Carton",
    "BundleUp.CommonMallowDriedCarton",
    "BundleUp.CookiesSugarCarton",
    "BundleUp.CornCarton",
    "BundleUp.CrispyRiceSquareCarton",
    "BundleUp.CucumberCarton",
    "BundleUp.Dip_NachoCheeseCarton",
    "BundleUp.Dip_RanchCarton",
    "BundleUp.DogFoodBagCrate",
    "BundleUp.DriedWhiteBeansCarton",
    "BundleUp.EggplantCarton",
    "BundleUp.GarlicCarton",
    "BundleUp.GingerbreadmanCarton",
    "BundleUp.GinsengCarton",
    "BundleUp.GreenpeasCarton",
    "BundleUp.HotsauceCarton",
    "BundleUp.KaleCarton",
    "BundleUp.LeekCarton",
    "BundleUp.LettuceCarton",
    "BundleUp.MarigoldDriedCarton",
    "BundleUp.MayonnaiseFullCarton",
    "BundleUp.MintHerbDriedCarton",
    "BundleUp.OnionCarton",
    "BundleUp.OreganoDriedCarton",
    "BundleUp.ParsleyDriedCarton",
    "BundleUp.PastaCarton",
    "BundleUp.PepperHabaneroDriedCarton",
    "BundleUp.PicklesCarton",
    "BundleUp.PotatoCarton",
    "BundleUp.QuaggaCakesCarton",
    "BundleUp.RedRadishCarton",
    "BundleUp.RemouladeFullCarton",
    "BundleUp.RiceCarton",
    "BundleUp.RosePetalsDriedCarton",
    "BundleUp.RosemaryDriedCarton",
    "BundleUp.SageDriedCarton",
    "BundleUp.SalamiCarton",
    "BundleUp.SaltCarton",
    "BundleUp.SoybeansCarton",
    "BundleUp.SpinachCarton",
    "BundleUp.SquashCarton",
    "BundleUp.SugarBeetCarton",
    "BundleUp.SweetPotatoCarton",
    "BundleUp.TomatoCarton",
    "BundleUp.TomatoPasteCarton",
    "BundleUp.TortillaChipsCarton",
    "BundleUp.TurkeyEggCarton",
    "BundleUp.TurnipCarton",
    "BundleUp.WildEggsCarton",
    "BundleUp.WildGarlicDriedCarton",
    "BundleUp.ZucchiniCarton",
}

local FOOD_WEIGHTS = {
    GigamartCannedFood      = 0.3,
    GigamartDryGoods        = 0.3,
    GigamartBakingMisc      = 0.2,
    GigamartCandy           = 0.2,
    GigamartCrisps          = 0.2,
    GigamartSauce           = 0.2,
    GigamartSpices          = 0.15,
    GigamartBottles         = 0.15,
    GigamartBBQ             = 0.1,
    GroceryStandFruits1     = 0.15,
    GroceryStandFruits2     = 0.15,
    GroceryStandFruits3     = 0.15,
    GroceryStandVegetables1 = 0.15,
    GroceryStandVegetables2 = 0.15,
    GroceryStandVegetables3 = 0.15,
    GroceryStandVegetables4 = 0.15,
    GroceryStandVegetables5 = 0.15,
    GroceryStandLettuce     = 0.15,
    GroceryStorageCrate1    = 0.4,
    GroceryStorageCrate2    = 0.4,
    GroceryStorageCrate3    = 0.4,
}

BU_applyDistribution("SpawnFood", FOOD_ITEMS, FOOD_WEIGHTS)

local MATERIALS_ITEMS = {
    "BundleUp.PlankR",
    "BundleUp.PlankSR",
    "BundleUp.SheetMetalR",
    "BundleUp.SheetMetalSR",
    "BundleUp.IronPipesR",
    "BundleUp.IronPipesSR",
    "BundleUp.IronBarR",
    "BundleUp.IronBarSR",
    "BundleUp.PlankLR",
    "BundleUp.PlankLSR",
    "BundleUp.SheetMetalLR",
    "BundleUp.SheetMetalLSR",
    "BundleUp.IronPipesLR",
    "BundleUp.IronPipesLSR",
    "BundleUp.IronBarLR",
    "BundleUp.IronBarLSR",
    "BundleUp.NailsBox_Small",
    "BundleUp.NailsBox_Medium",
    "BundleUp.ScrewsBox_Small",
    "BundleUp.ScrewsBox_Medium",
    "BundleUp.WireCable_Small",
    "BundleUp.WireCable_Large",
    "BundleUp.SmallMetalSheetS",
    "BundleUp.SmallMetalSheetL",
    "BundleUp.StoneBlockPack",
    "BundleUp.NutsBoltsBox",
    "BundleUp.HingeBox",
    "BundleUp.DoorknobBox",
    "BundleUp.SmallHandleBox",
    "BundleUp.WeldingRodsBox",
    "BundleUp.WhetstoneBox",
    "BundleUp.BuckleBox",
}

local MATERIALS_WEIGHTS = {
    ToolStoreCarpentry   = 0.3,
    ToolStoreMetalwork   = 0.3,
    ToolStoreTools       = 0.2,
    ToolStoreMisc        = 0.2,
    ToolStoreAccessories = 0.15,
    ToolStoreHandles     = 0.15,
}

BU_applyDistribution("SpawnMaterials", MATERIALS_ITEMS, MATERIALS_WEIGHTS)

local GENERAL_ITEMS = {
    "BundleUp.AdhesiveTapeBoxCrate",
    "BundleUp.AluminumBox",
    "BundleUp.AmplifierBox",
    "BundleUp.BakingSodaBox",
    "BundleUp.BatteryBoxCrate",
    "BundleUp.ButterKnifeBox",
    "BundleUp.ButtonBox",
    "BundleUp.CandleBoxCrate",
    "BundleUp.CorrectionFluidBox",
    "BundleUp.DuctTapeBoxCrate",
    "BundleUp.ElectricWireBox",
    "BundleUp.EpoxyBox",
    "BundleUp.FiberglassTapeBox",
    "BundleUp.ForkBox",
    "BundleUp.Garbagebag_boxBox",
    "BundleUp.GasmaskFilterBox",
    "BundleUp.GlueBox",
    "BundleUp.GravyMixBox",
    "BundleUp.HairgelBox",
    "BundleUp.Hairspray2Box",
    "BundleUp.InsectRepellentBox",
    "BundleUp.JarLidBox",
    "BundleUp.LightBulbBlueBox",
    "BundleUp.LightBulbBoxCrate",
    "BundleUp.LightBulbCyanBox",
    "BundleUp.LightBulbGreenBox",
    "BundleUp.LightBulbMagentaBox",
    "BundleUp.LightBulbOrangeBox",
    "BundleUp.LightBulbPinkBox",
    "BundleUp.LightBulbPurpleBox",
    "BundleUp.LightBulbRedBox",
    "BundleUp.LightBulbYellowBox",
    "BundleUp.LighterBox",
    "BundleUp.LighterBBQBox",
    "BundleUp.LighterDisposableBox",
    "BundleUp.MagnesiumFirestarterBox",
    "BundleUp.MakeupEyeshadowBox",
    "BundleUp.MakeupFoundationBox",
    "BundleUp.MatchesBox",
    "BundleUp.MotionSensorBox",
    "BundleUp.PagerBox",
    "BundleUp.PancakeMixBox",
    "BundleUp.PaperNapkins2Box",
    "BundleUp.PaperclipBoxCrate",
    "BundleUp.PillowBox",
    "BundleUp.RadioReceiverBox",
    "BundleUp.RadioTransmitterBox",
    "BundleUp.RatPoisonBox",
    "BundleUp.ReceiverBox",
    "BundleUp.RemoteBox",
    "BundleUp.SlugRepellentBox",
    "BundleUp.SmallAnimalBoneBox",
    "BundleUp.Soap2Box",
    "BundleUp.SparklersBox",
    "BundleUp.SpongeBox",
    "BundleUp.SpoonBox",
    "BundleUp.TarpBox",
    "BundleUp.Thread_AramidBox",
    "BundleUp.Thread_SinewBox",
    "BundleUp.TimerBox",
    "BundleUp.TimerCraftedBox",
    "BundleUp.TissueBoxCrate",
    "BundleUp.ToiletPaperBox",
    "BundleUp.ToothbrushBox",
    "BundleUp.TriggerCraftedBox",
    "BundleUp.TwineBox",
    "BundleUp.Vinegar2Box",
    "BundleUp.Vinegar_JugBox",
    "BundleUp.WoodglueBox",
    "BundleUp.YeastBox",
    "BundleUp.ZiptiesBox",
    "BundleUp.PenBox_Black",
    "BundleUp.PenBox_Blue",
    "BundleUp.PenBox_Red",
    "BundleUp.PenBox_Green",
}

local GENERAL_WEIGHTS = {
    GigamartLightbulb        = 0.3,
    GigamartCleaning         = 0.25,
    GigamartToiletries       = 0.25,
    GigamartPaper            = 0.2,
    GigamartHousewares       = 0.2,
    GigamartPots             = 0.15,
    GigamartHouseElectronics = 0.15,
    GigamartSchool           = 0.15,
    GigamartTools            = 0.15,
}

BU_applyDistribution("SpawnSupplies", GENERAL_ITEMS, GENERAL_WEIGHTS)

local FISHING_SUPPLY_ITEMS = {
    "BundleUp.FishingHookBoxCrate",
    "BundleUp.FishingLineBox",
    "BundleUp.JigLureBox",
    "BundleUp.MinnowLureBox",
    "BundleUp.PremiumFishingLineBox",
}

local FISHING_SUPPLY_WEIGHTS = {
    FishingStoreBait = 0.3,
    FishingStoreGear = 0.2,
}

BU_applyDistribution("SpawnFishing", FISHING_SUPPLY_ITEMS, FISHING_SUPPLY_WEIGHTS)

local MEDICAL_ITEMS = {
    "BundleUp.AlcoholBandageBox",
    "BundleUp.AlcoholWipesBox",
    "BundleUp.AlcoholedCottonBallsBox",
    "BundleUp.PillsBox",
    "BundleUp.PillsAntiDepBox",
    "BundleUp.PillsBetaBox",
    "BundleUp.PillsSleepingTabletsBox",
    "BundleUp.PillsVitaminsBox",
    "BundleUp.TissueBox",
    "BundleUp.WaterPurificationTabletsBox",
    "BundleUp.BandageDirtyBox",
    "BundleUp.DisinfectantBox",
}

local MEDICAL_WEIGHTS = {
    MedicalStorageDrugs = 0.3,
    MedicalClinicDrugs  = 0.25,
    StoreShelfMedical   = 0.2,
    FridgeMedical       = 0.1,
}

BU_applyDistribution("SpawnMedical", MEDICAL_ITEMS, MEDICAL_WEIGHTS)

local AMMO_ITEMS = {
    "BundleUp.44ClipBox",
    "BundleUp.JS14ClipBox",
    "BundleUp.556ClipBox",
    "BundleUp.45ClipBox",
    "BundleUp.M14ClipBox",
    "BundleUp.9mmClipBox",
}

local AMMO_WEIGHTS = {
    GunStoreAmmunition    = 0.2,
    GunStoreMagsAmmo      = 0.3,
    ArmyStorageAmmunition = 0.2,
    ArmySurplusAmmoBoxes  = 0.15,
    SWATStorageAmmunition = 0.15,
}

BU_applyDistribution("SpawnAmmo", AMMO_ITEMS, AMMO_WEIGHTS)

local AMMO_CARTON_ITEMS = {
    "BundleUp.44ClipCarton",
    "BundleUp.JS14ClipCarton",
    "BundleUp.556ClipCarton",
    "BundleUp.45ClipCarton",
    "BundleUp.M14ClipCarton",
    "BundleUp.9mmClipCarton",
}

local AMMO_CARTON_WEIGHTS = {
    GunStoreAmmunition    = 0.05,
    GunStoreMagsAmmo      = 0.07,
    ArmyStorageAmmunition = 0.05,
    ArmySurplusAmmoBoxes  = 0.04,
    SWATStorageAmmunition = 0.04,
}

applyDistribution("SpawnAmmo", AMMO_CARTON_ITEMS, AMMO_CARTON_WEIGHTS)

local CAP_CARTON_ITEMS = {
    "BundleUp.CapGunCapCarton",
}

local CAP_CARTON_WEIGHTS = {
    WildWestSheriffDesk   = 0.1,
    WildWestSheriffLocker = 0.1,
}

applyDistribution("SpawnAmmo", CAP_CARTON_ITEMS, CAP_CARTON_WEIGHTS)

local FARMING_ITEMS = {
    "BundleUp.BarleyBagSeedPouch",
    "BundleUp.BasilBagSeedPouch",
    "BundleUp.BellPepperBagSeedPouch",
    "BundleUp.BlackSageBagSeedPouch",
    "BundleUp.BroadleafPlantainBagSeedPouch",
    "BundleUp.BroccoliBagSeed2Pouch",
    "BundleUp.CabbageBagSeed2Pouch",
    "BundleUp.CarrotBagSeed2Pouch",
    "BundleUp.CauliflowerBagSeedPouch",
    "BundleUp.ChamomileBagSeedPouch",
    "BundleUp.ChivesBagSeedPouch",
    "BundleUp.CilantroBagSeedPouch",
    "BundleUp.ComfreyBagSeedPouch",
    "BundleUp.CommonMallowBagSeedPouch",
    "BundleUp.CornBagSeedPouch",
    "BundleUp.CucumberBagSeedPouch",
    "BundleUp.FlaxBagSeedPouch",
    "BundleUp.GarlicBagSeedPouch",
    "BundleUp.GreenpeasBagSeedPouch",
    "BundleUp.HabaneroBagSeedPouch",
    "BundleUp.HempBagSeedPouch",
    "BundleUp.HopsBagSeedPouch",
    "BundleUp.JalapenoBagSeedPouch",
    "BundleUp.KaleBagSeedPouch",
    "BundleUp.LavenderBagSeedPouch",
    "BundleUp.LeekBagSeedPouch",
    "BundleUp.LemonGrassBagSeedPouch",
    "BundleUp.LettuceBagSeedPouch",
    "BundleUp.MarigoldBagSeedPouch",
    "BundleUp.MintBagSeedPouch",
    "BundleUp.OnionBagSeedPouch",
    "BundleUp.OreganoBagSeedPouch",
    "BundleUp.ParsleyBagSeedPouch",
    "BundleUp.PoppyBagSeedPouch",
    "BundleUp.PotatoBagSeed2Pouch",
    "BundleUp.PumpkinBagSeedPouch",
    "BundleUp.RedRadishBagSeed2Pouch",
    "BundleUp.RoseBagSeedPouch",
    "BundleUp.RosemaryBagSeedPouch",
    "BundleUp.RyeBagSeedPouch",
    "BundleUp.SageBagSeedPouch",
    "BundleUp.SoybeansBagSeedPouch",
    "BundleUp.SpinachBagSeedPouch",
    "BundleUp.StrewberrieBagSeed2Pouch",
    "BundleUp.SugarBeetBagSeedPouch",
    "BundleUp.SunflowerBagSeedPouch",
    "BundleUp.SweetPotatoBagSeedPouch",
    "BundleUp.ThymeBagSeedPouch",
    "BundleUp.TobaccoBagSeedPouch",
    "BundleUp.TomatoBagSeed2Pouch",
    "BundleUp.TurnipBagSeedPouch",
    "BundleUp.WatermelonBagSeedPouch",
    "BundleUp.WheatBagSeedPouch",
    "BundleUp.WildGarlicBagSeedPouch",
    "BundleUp.ZucchiniBagSeedPouch",
}

local FARMING_WEIGHTS = {
    GardenStoreMisc  = 0.4,
    GardenStoreTools = 0.2,
    GigamartFarming  = 0.2,
}

BU_applyDistribution("SpawnSeeds", FARMING_ITEMS, FARMING_WEIGHTS)

local SCRAP_ITEMS = {
    "BundleUp.AluminumScrapSack",
    "BundleUp.BrassScrapSack",
    "BundleUp.BrokenGlassSack",
    "BundleUp.CharcoalCraftedSack",
    "BundleUp.CopperScrapSack",
    "BundleUp.ElectronicsScrapSack",
    "BundleUp.IronScrapSack",
    "BundleUp.ScrapMetalSack",
    "BundleUp.SplintersSack",
    "BundleUp.SteelScrapSack",
    "BundleUp.UnusableWoodSack",
    "BundleUp.Sack_Sack",
    "BundleUp.CircularSawbladeBox",
    "BundleUp.IronBandBox",
    "BundleUp.IronBandSmallBox",
    "BundleUp.IronBarHalfBox",
    "BundleUp.IronBarQuarterBox",
    "BundleUp.IronBlockBox",
    "BundleUp.IronChunkBox",
    "BundleUp.IronPieceBox",
    "BundleUp.RakeHeadBox",
    "BundleUp.SteelBarHalfBox",
    "BundleUp.SteelBarQuarterBox",
    "BundleUp.SteelBlockBox",
    "BundleUp.SteelChunkBox",
    "BundleUp.SteelPieceBox",
}

local SCRAP_WEIGHTS = {
    WeldingWorkshopMetal = 0.3,
    WeldingWorkshopFuel  = 0.1,
    WeldingWorkshopTools = 0.15,
    MechanicShelfTools   = 0.2,
    MechanicOutfit       = 0.1,
}

BU_applyDistribution("SpawnScrap", SCRAP_ITEMS, SCRAP_WEIGHTS)

local JEWELRY_ITEMS = {
    "BundleUp.GoldScrap_Small",
    "BundleUp.GoldScrap_Large",
    "BundleUp.SilverScrap_Small",
    "BundleUp.SilverScrap_Large",
    "BundleUp.JewelryPouch_Small",
    "BundleUp.JewelryPouch_Medium",
}

local JEWELRY_WEIGHTS = {
    JewelryGold        = 0.3,
    JewelrySilver      = 0.3,
    JewelryOthers      = 0.2,
    JewelryStorageAll  = 0.2,
}

BU_applyDistribution("SpawnJewelry", JEWELRY_ITEMS, JEWELRY_WEIGHTS)

local LITERATURE_GROUPS = {
    {
        items = {
            "BundleUp.Book_AdventureNonFictionBundle",
            "BundleUp.Paperback_AdventureNonFictionBundle",
            "BundleUp.Book_GeneralNonFictionBundle",
            "BundleUp.Book_ClassicNonfictionBundle",
            "BundleUp.BookFancy_ClassicNonfictionBundle",
            "BundleUp.Paperback_ClassicNonfictionBundle",
            "BundleUp.Book_SadNonFictionBundle",
            "BundleUp.Paperback_SadNonFictionBundle",
            "BundleUp.Paperback_DietBundle",
        },
        weights = { BookstoreNonFiction = 0.3, LibraryNonFiction = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ArtBundle",
            "BundleUp.Paperback_ArtBundle",
            "BundleUp.Magazine_ArtBundle",
            "BundleUp.Magazine_Art_NewBundle",
        },
        weights = { BookstoreArt = 0.3, LibraryArt = 0.2, ArtStoreLiterature = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_BaseballBundle",
            "BundleUp.Paperback_BaseballBundle",
            "BundleUp.Book_GolfBundle",
            "BundleUp.Paperback_GolfBundle",
            "BundleUp.Book_SportsBundle",
            "BundleUp.Paperback_SportsBundle",
            "BundleUp.Magazine_GolfBundle",
            "BundleUp.Magazine_Golf_NewBundle",
            "BundleUp.Magazine_SportsBundle",
            "BundleUp.Magazine_Sports_NewBundle",
        },
        weights = { BookstoreSports = 0.3, LibrarySports = 0.2, GolfStoreLiterature = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_BiographyBundle",
            "BundleUp.Paperback_BiographyBundle",
        },
        weights = { BookstoreBiography = 0.3, LibraryBiography = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_BusinessBundle",
            "BundleUp.Paperback_BusinessBundle",
            "BundleUp.Book_RichBundle",
            "BundleUp.Paperback_RichBundle",
            "BundleUp.Magazine_BusinessBundle",
            "BundleUp.Magazine_Business_NewBundle",
            "BundleUp.Magazine_RichBundle",
            "BundleUp.Magazine_Rich_NewBundle",
        },
        weights = { BookstoreBusiness = 0.3, LibraryBusiness = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ChildsBundle",
            "BundleUp.Paperback_ChildsBundle",
            "BundleUp.Magazine_ChildsBundle",
            "BundleUp.Magazine_Childs_NewBundle",
            "BundleUp.Paperback_TeensBundle",
            "BundleUp.Magazine_TeensBundle",
            "BundleUp.Magazine_Teens_NewBundle",
            "BundleUp.ChildsPictureBookBundle",
        },
        weights = { BookstoreChilds = 0.3, LibraryChilds = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_CinemaBundle",
            "BundleUp.Paperback_CinemaBundle",
            "BundleUp.Magazine_CinemaBundle",
            "BundleUp.Magazine_Cinema_NewBundle",
        },
        weights = { BookstoreCinema = 0.3, LibraryCinema = 0.2, HomeCinemaLiterature = 0.15 },
    },
    {
        items = {
            "BundleUp.BookBundle",
            "BundleUp.PaperbackBundle",
            "BundleUp.Book_ClassicBundle",
            "BundleUp.BookFancy_ClassicBundle",
            "BundleUp.Paperback_ClassicBundle",
            "BundleUp.Book_ClassicFictionBundle",
            "BundleUp.BookFancy_ClassicFictionBundle",
            "BundleUp.Paperback_ClassicFictionBundle",
            "BundleUp.Book_FictionBundle",
            "BundleUp.Paperback_FictionBundle",
            "BundleUp.Book_LiteraryFictionBundle",
            "BundleUp.Paperback_LiteraryFictionBundle",
        },
        weights = { BookstoreLiteraryFiction = 0.3, LibraryLiteraryFiction = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ComputerBundle",
            "BundleUp.Paperback_ComputerBundle",
        },
        weights = { BookstoreComputer = 0.3, LibraryComputer = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_CrimeFictionBundle",
            "BundleUp.Paperback_CrimeFictionBundle",
            "BundleUp.Book_PolicingBundle",
            "BundleUp.Paperback_PolicingBundle",
            "BundleUp.Paperback_TrueCrimeBundle",
            "BundleUp.Magazine_CrimeBundle",
            "BundleUp.Magazine_Crime_NewBundle",
            "BundleUp.Magazine_PoliceBundle",
            "BundleUp.Magazine_Police_NewBundle",
        },
        weights = { BookstoreCrimeFiction = 0.3, LibraryCrimeFiction = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_FantasyBundle",
            "BundleUp.Paperback_FantasyBundle",
            "BundleUp.Book_SciFiBundle",
            "BundleUp.Paperback_SciFiBundle",
        },
        weights = { BookstoreFantasySciFi = 0.3, LibraryFantasySciFi = 0.2 },
    },
    {
        items = { "BundleUp.Book_FarmingBundle" },
        weights = { BookstoreFarming = 0.3, GigamartFarming = 0.15 },
    },
    {
        items = {
            "BundleUp.Book_FashionBundle",
            "BundleUp.Paperback_FashionBundle",
            "BundleUp.Magazine_FashionBundle",
            "BundleUp.Magazine_Fashion_NewBundle",
        },
        weights = { BookstoreFashion = 0.3, LibraryFashion = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_GeneralReferenceBundle",
            "BundleUp.Book_SchoolTextbookBundle",
        },
        weights = { BookstoreGeneralReference = 0.3, LibraryGeneralReference = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_HistoryBundle",
            "BundleUp.BookFancy_HistoryBundle",
            "BundleUp.Paperback_HistoryBundle",
        },
        weights = { BookstoreHistory = 0.3, LibraryHistory = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_MilitaryHistoryBundle",
            "BundleUp.BookFancy_MilitaryHistoryBundle",
            "BundleUp.Paperback_MilitaryHistoryBundle",
        },
        weights = { BookstoreMilitaryHistory = 0.3, LibraryMilitaryHistory = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_HorrorBundle",
            "BundleUp.Paperback_HorrorBundle",
            "BundleUp.Paperback_ScaryBundle",
            "BundleUp.Magazine_HorrorBundle",
            "BundleUp.Magazine_Horror_NewBundle",
        },
        weights = { BookstoreHorror = 0.3, LibraryHorror = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_LegalBundle",
            "BundleUp.BookFancy_LegalBundle",
            "BundleUp.Paperback_LegalBundle",
        },
        weights = { BookstoreLegal = 0.3, LibraryLegal = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_MedicalBundle",
            "BundleUp.BookFancy_MedicalBundle",
            "BundleUp.Paperback_MedicalBundle",
        },
        weights = { BookstoreMedical = 0.3, LibraryMedical = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_MilitaryBundle",
            "BundleUp.Paperback_MilitaryBundle",
            "BundleUp.Magazine_MilitaryBundle",
            "BundleUp.Magazine_Military_NewBundle",
        },
        weights = { BookstoreMilitaryHistory = 0.2, LibraryMilitaryHistory = 0.15, ArmySurplusLiterature = 0.2 },
    },
    {
        items = {
            "BundleUp.Magazine_FirearmBundle",
            "BundleUp.Magazine_Firearm_NewBundle",
        },
        weights = { GunStoreLiterature = 0.3, ArmySurplusLiterature = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_MusicBundle",
            "BundleUp.Paperback_MusicBundle",
            "BundleUp.Magazine_MusicBundle",
            "BundleUp.Magazine_Music_NewBundle",
        },
        weights = { BookstoreMusic = 0.3, LibraryMusic = 0.2, MusicStoreLiterature = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_NatureBundle",
            "BundleUp.Paperback_NatureBundle",
            "BundleUp.Magazine_OutdoorsBundle",
            "BundleUp.Magazine_Outdoors_NewBundle",
        },
        weights = { BookstoreOutdoors = 0.3, LibraryOutdoors = 0.2, CampingStoreBooks = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_OccultBundle",
            "BundleUp.BookFancy_OccultBundle",
            "BundleUp.Paperback_OccultBundle",
            "BundleUp.Book_QuackeryBundle",
            "BundleUp.Paperback_QuackeryBundle",
            "BundleUp.Paperback_ConspiracyBundle",
        },
        weights = { BookstoreOccult = 0.3, LibraryOccult = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_PhilosophyBundle",
            "BundleUp.BookFancy_PhilosophyBundle",
            "BundleUp.Paperback_PhilosophyBundle",
        },
        weights = { BookstorePhilosophy = 0.3, LibraryPhilosophy = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_PoliticsBundle",
            "BundleUp.BookFancy_PoliticsBundle",
            "BundleUp.Paperback_PoliticsBundle",
        },
        weights = { BookstorePolitics = 0.3, LibraryPolitics = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ReligionBundle",
            "BundleUp.BookFancy_ReligionBundle",
            "BundleUp.Paperback_ReligionBundle",
            "BundleUp.Book_BibleBundle",
            "BundleUp.BookFancy_BibleBundle",
            "BundleUp.Paperback_BibleBundle",
        },
        weights = { BookstoreReligion = 0.3, LibraryReligion = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_RomanceBundle",
            "BundleUp.Paperback_RomanceBundle",
            "BundleUp.Paperback_RelationshipBundle",
            "BundleUp.Paperback_SexyBundle",
        },
        weights = { BookstoreRomance = 0.3, LibraryRomance = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ScienceBundle",
            "BundleUp.Paperback_ScienceBundle",
            "BundleUp.Magazine_ScienceBundle",
            "BundleUp.Magazine_Science_NewBundle",
        },
        weights = { BookstoreScience = 0.3, LibraryScience = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_ThrillerBundle",
            "BundleUp.Paperback_ThrillerBundle",
        },
        weights = { BookstoreThriller = 0.3, LibraryThriller = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_TravelBundle",
            "BundleUp.Paperback_TravelBundle",
        },
        weights = { BookstoreTravel = 0.3, LibraryTravel = 0.2 },
    },
    {
        items = {
            "BundleUp.Book_WesternBundle",
            "BundleUp.Paperback_WesternBundle",
        },
        weights = { BookstoreWestern = 0.3, LibraryWestern = 0.2 },
    },
    {
        items = {
            "BundleUp.Paperback_NewAgeBundle",
            "BundleUp.Paperback_SelfHelpBundle",
        },
        weights = { BookstoreNewAge = 0.3, LibraryNewAge = 0.2 },
    },
    {
        items = {
            "BundleUp.Paperback_HassBundle",
            "BundleUp.Paperback_QuigleyBundle",
            "BundleUp.Paperback_PoorBundle",
            "BundleUp.Paperback_PlayBundle",
        },
        weights = { BookstoreMisc = 0.3, LibraryBooks = 0.2 },
    },
    {
        items = {
            "BundleUp.Magazine_CarBundle",
            "BundleUp.Magazine_Car_NewBundle",
        },
        weights = { CarSupplyLiterature = 0.3, MagazineRackMixed = 0.2 },
    },
    {
        items = {
            "BundleUp.Magazine_GamingBundle",
            "BundleUp.Magazine_Gaming_NewBundle",
            "BundleUp.Magazine_HealthBundle",
            "BundleUp.Magazine_Health_NewBundle",
            "BundleUp.Magazine_HobbyBundle",
            "BundleUp.Magazine_Hobby_NewBundle",
            "BundleUp.Magazine_HumorBundle",
            "BundleUp.Magazine_Humor_NewBundle",
            "BundleUp.Magazine_PopularBundle",
            "BundleUp.Magazine_Popular_NewBundle",
            "BundleUp.Magazine_TechBundle",
            "BundleUp.Magazine_Tech_NewBundle",
        },
        weights = { MagazineRackMixed = 0.3 },
    },
    {
        items = {
            "BundleUp.HottieZ_NewBundle",
            "BundleUp.MagazineBundle",
            "BundleUp.Magazine_NewBundle",
            "BundleUp.MagazineCrosswordBundle",
            "BundleUp.HottieZBundle",
            "BundleUp.TVMagazineBundle",
            "BundleUp.TVMagazine_NewBundle",
            "BundleUp.MagazineWordsearchBundle",
        },
        weights = { MagazineRackMixed = 0.3, MagazineRackPaperback = 0.15 },
    },
    {
        items = {
            "BundleUp.Newspaper_RecentBundle",
            "BundleUp.Newspaper_NewBundle",
            "BundleUp.Newspaper_Knews_NewBundle",
            "BundleUp.Newspaper_Times_NewBundle",
            "BundleUp.Newspaper_Herald_NewBundle",
            "BundleUp.Newspaper_Dispatch_NewBundle",
            "BundleUp.NewspaperBundle",
        },
        weights = { MagazineRackNewspaper = 0.3 },
    },
    {
        items = {
            "BundleUp.ComicBookBundle",
            "BundleUp.ComicBook_RetailBundle",
        },
        weights = { ComicStoreDisplayComics = 0.3, ComicStoreShelfComics = 0.2 },
    },
    {
        items = {
            "BundleUp.CatalogBundle",
            "BundleUp.Diary1Bundle",
            "BundleUp.Diary2Bundle",
            "BundleUp.GraphPaperBundle",
            "BundleUp.JournalBundle",
            "BundleUp.MenuCardBundle",
            "BundleUp.NotebookBundle",
            "BundleUp.NotepadBundle",
            "BundleUp.PhonebookBundle",
            "BundleUp.PhotoBookBundle",
            "BundleUp.RPGmanualBundle",
            "BundleUp.SheetPaper2Bundle",
        },
        weights = { BookstoreMisc = 0.2, LibraryBooks = 0.15, GigamartSchool = 0.2 },
    },
}

for i = 1, #LITERATURE_GROUPS do
    BU_applyDistribution("SpawnLiterature", LITERATURE_GROUPS[i].items, LITERATURE_GROUPS[i].weights)
end

-- Sandbox enum values are 1-based. The master option (SpawnDefault) maps
-- straight onto SCALE; the per-category options carry an extra leading
-- "Inherit default" entry, so their value is offset by one.
local SCALE = { 0, 0.25, 0.5, 1.0, 1.5, 2.0 }
local DEFAULT_VALUE = 4

local function BU_multiplierFor(sv, option)
    local value = sv[option]
    if value and value > 1 then
        return SCALE[value - 1] or 1.0
    end
    return SCALE[sv.SpawnDefault or DEFAULT_VALUE] or 1.0
end

-- Recomputed from the recorded base weight each time, so re-running never compounds.
local function BU_applySpawnRates()
    local sv = SandboxVars and SandboxVars.BundleUp
    if not sv then return end
    for option, slots in pairs(registry) do
        local multiplier = BU_multiplierFor(sv, option)
        for i = 1, #slots do
            local slot = slots[i]
            -- Skip if another mod shifted our entry out from under the index.
            if slot.items[slot.index - 1] == slot.name then
                slot.items[slot.index] = slot.base * multiplier
            end
        end
    end
end

-- Whichever of these fires first with the sandbox options loaded wins; the
-- other is a harmless no-op re-run. Guarded so an event missing on some build
-- degrades to base weights instead of erroring.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU_applySpawnRates)
end
if Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(BU_applySpawnRates)
end
