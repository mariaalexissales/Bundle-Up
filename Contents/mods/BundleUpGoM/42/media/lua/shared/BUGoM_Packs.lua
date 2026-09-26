----------
--ESTRAL--
----------

-- BU_WeightData assigns BU.Bundles and BU.BaseCategory wholesale, so it has to load
-- before these rows.
require "BU_WeightData"

BU = BU or {}
BUGoM = BUGoM or {}

BUGoM.Magazines = {
    "556x45Magazine20_STANAG",
    "556x45Magazine25_STANAG",
    "556x45Magazine30_STANAG",
    "556x45Magazine30_G36",
    "545x39Magazine30_Bakelite",
    "545x39Magazine45_Bakelite",
    "9x39Magazine30",
    "762x39Magazine30",
    "3006Clip8",
    "762x51Magazine20_M14",
    "762x51Magazine20_FAL",
    "762x51Magazine20_G3",
    "762x54StripperClip5_MOSIN",
    "3006Magazine20_BAR",
    "9x19Magazine15_M92FS",
    "9x19Magazine30_M92FS",
    "9x19Magazine50_M92FS",
    "9x19Magazine18_M93R",
    "9x19Magazine60_M93R",
    "9x19Magazine13_HIPOWER",
    "9x19Magazine10_P226",
    "45Magazine7_M1911",
    "45Magazine12_USP",
    "45Magazine20_USP",
    "50Magazine8_DEAGLE",
    "50Magazine12_DEAGLE",
    "9x19Magazine18_VP70M",
    "9x19Magazine30_VP70M",
    "38357SpeedLoader6",
    "762x54Magazine10_SVD",
    "762x51Magazine5_PSG1",
    "223Magazine10_Mini14",
    "223Magazine20_Mini14",
    "223Magazine30_Mini14",
    "12GMagazine8_AA12",
    "45Magazine30_THOMPSON",
    "45Magazine20_THOMPSON",
    "9x19Magazine20_MP5",
    "9x19Magazine25_MP5",
    "9x19Magazine30_MP5",
    "9x19Magazine60_MP5",
    "9x19Magazine20_TEC9",
    "45Magazine30_MAC10",
    "45Magazine40_MAC10",
}

BUGoM.Drums = {
    "556x45Magazine60_STANAG",
    "556x45Magazine50_STANAG",
    "556x45Magazine75_STANAG",
    "556x45Magazine100_STANAG",
    "556x45Magazine150_STANAG",
    "545x39Magazine100_Drum",
    "762x39Magazine75",
    "762x51Box100_M60",
    "12GMagazine20_AA12",
    "45Magazine100_THOMPSON",
    "9x19Magazine100_MP5",
}

BUGoM.Grenades = {
    { base = "40mm_Box_Buckshot", short = "40mm_Buckshot" },
    { base = "40mm_Box_HE", short = "40mm_HE" },
    { base = "40mm_Box_Incendiary", short = "40mm_Incendiary" },
}

BUGoM.Tiers = {
    Magazine   = { { "Box", 5 }, { "Carton", 12 }, { "Crate", 4 } },
    Drum       = { { "Box", 2 }, { "Carton", 6 }, { "Crate", 4 } },
    Grenade    = { { "Carton", 6 }, { "Crate", 4 } },
}

-- pack names are built by string, short .. tier, so grepping for 9x19Magazine15_M92FSBox
-- only finds gunsofmarz.txt.
function BUGoM.packName(short, tier)
    return "BundleUp." .. short .. tier
end

local function BUGoM_addLadder(base, short, tiers)
    local below = "MarzGuns." .. base
    BU.BaseCategory[below] = "ReductionGoM"
    for i = 1, #tiers do
        local fullType = BUGoM.packName(short, tiers[i][1])
        BU.Bundles[fullType] = { base = below, count = tiers[i][2] }
        below = fullType
    end
end

for i = 1, #BUGoM.Magazines do
    BUGoM_addLadder(BUGoM.Magazines[i], BUGoM.Magazines[i], BUGoM.Tiers.Magazine)
end

for i = 1, #BUGoM.Drums do
    BUGoM_addLadder(BUGoM.Drums[i], BUGoM.Drums[i], BUGoM.Tiers.Drum)
end

for i = 1, #BUGoM.Grenades do
    BUGoM_addLadder(BUGoM.Grenades[i].base, BUGoM.Grenades[i].short, BUGoM.Tiers.Grenade)
end
